#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/rtnetlink.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/ctrl.h>
#include <netlink/socket.h>
#include <sys/socket.h>

#include "nics.h"
#include "sections.h"

enum status net_init(struct net_section *section)
{
	if (rtnl_open(&section->rth, 0) < 0) {
		fprintf(stderr, "Failed to open rtnetlink socket\n");
		goto out;
	}
	section->rth_init = true;

	section->nl_sock = nl_socket_alloc();
	if (!section->nl_sock) {
		fprintf(stderr, "Failed to allocate netlink socket\n");
		goto out_rth;
	}
	nl_socket_set_buffer_size(section->nl_sock, 8192, 8192);

	if (genl_connect(section->nl_sock)) {
		fprintf(stderr, "Failed to connect to generic netlink\n");
		goto out_nl_sock;
	}

	section->nl80211_id = genl_ctrl_resolve(section->nl_sock, "nl80211");
	if (section->nl80211_id < 0) {
		fprintf(stderr, "nl80211 not found\n");
		goto out_nl_sock;
	}

	return net_update(section);

out_nl_sock:
	nl_socket_free(section->nl_sock);
out_rth:
	rtnl_close(&section->rth);
out:
	return SECTION_FATAL;
}

static void free_nics(struct net_section *section)
{
	struct nic *nic = section->nics_head;

	while (nic) {
		struct nic *next = nic->next;
		free(nic->name);
		free(nic->ssid);
		free(nic);
		nic = next;
	}

	section->nics_head = NULL;
	section->nics_tail = NULL;
}

void net_free(struct net_section *section)
{
	free_nics(section);
	nl_socket_free(section->nl_sock);
	if (section->rth_init)
		rtnl_close(&section->rth);
}

enum status net_update(struct net_section *section)
{
	struct nic *nic;

	free_nics(section);

	if (enumerate_nics(section))
		return SECTION_FATAL;

	if (find_wifi_nics(section))
		return SECTION_FATAL;

	nic = section->nics_head;
	while (nic) {
		if (nic->is_wifi) {
			if (get_wifi_info(section, nic))
				return SECTION_FATAL;
		}
		nic = nic->next;
	}

	return SECTION_SUCCESS;
}

static int append_nic(const struct nic *nic, struct str *str)
{
	const int high_thresh = 66;
	const int low_thresh = 33;
	int signal, quality;
	int ret;

	if (nic->is_wifi) {
		if (!nic->ssid || !nic->have_wifi_signal) {
			if (str_append_icon(str, "wifi0"))
				return -1;
		} else {
			/* Convert dBm to percentage. */
			signal = nic->signal;
			if (signal > -50)
				signal = -50;
			else if (signal < -100)
				signal = -100;
			quality = 2 * (signal + 100);

			if (quality >= high_thresh) {
				if (nic->have_addr)
					ret = str_append_icon(str, "wifi3");
				else
					ret = str_append_icon(str, "wifi3_noaddr");
			} else if (quality >= low_thresh) {
				if (nic->have_addr)
					ret = str_append_icon(str, "wifi2");
				else
					ret = str_append_icon(str, "wifi2_noaddr");
			} else {
				if (nic->have_addr)
					ret = str_append_icon(str, "wifi1");
				else
					ret = str_append_icon(str, "wifi1_noaddr");
			}
			if (ret)
				return -1;

			if (wordy) {
				if (str_append(str, " "))
					return -1;

				if (str_append_escaped(str, nic->ssid, nic->ssid_len))
					return -1;

				if (str_appendf(str, " %3d%%", quality))
					return -1;
			}
		}
	} else {
		if (nic->have_addr)
			ret = str_append_icon(str, "wired");
		else
			ret = str_append_icon(str, "wired_noaddr");
		if (ret)
			return -1;
	}
	if (str_separator(str))
		return -1;
	return 0;
}

int append_net(const struct net_section *section, struct str *str)
{
	struct nic *nic;

	nic = section->nics_head;
	while (nic) {
		if (append_nic(nic, str))
			return -1;
		nic = nic->next;
	}

	return 0;
}
