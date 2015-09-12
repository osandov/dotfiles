#include <linux/netlink.h>
#include <linux/nl80211.h>
#include <linux/rtnetlink.h>
#include <net/if.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/ctrl.h>
#include <netlink/socket.h>
#include <sys/socket.h>

#include "sections.h"

static int getlink_filter(const struct sockaddr_nl *who, struct nlmsghdr *n,
			  void *arg)
{
	struct net_section *section = arg;
	struct nic *nic;
	struct ifinfomsg *ifi = NLMSG_DATA(n);
	struct rtattr *tb[IFLA_MAX + 1];
	int len = n->nlmsg_len;

	if (ifi->ifi_flags & IFF_LOOPBACK)
		return 0;

	len -= NLMSG_LENGTH(sizeof(*ifi));
	if (len < 0)
		return -1;

	parse_rtattr(tb, IFLA_MAX, IFLA_RTA(ifi), len);

	if (!tb[IFLA_IFNAME])
		return 0;

	nic = calloc(1, sizeof(*nic));
	if (!nic)
		return -1;

	nic->ifindex = ifi->ifi_index;
	nic->name = strdup(rta_getattr_str(tb[IFLA_IFNAME]));
	if (!nic->name) {
		free(nic);
		return -1;
	}

	if (section->nics_tail)
		section->nics_tail->next = nic;
	else
		section->nics_head = nic;
	section->nics_tail = nic;

	return 0;
}

static int getaddr_filter(const struct sockaddr_nl *who, struct nlmsghdr *n,
			  void *arg)
{
	struct net_section *section = arg;
	struct ifaddrmsg *ifa = NLMSG_DATA(n);
	struct nic *nic;

	nic = section->nics_head;
	while (nic) {
		if (ifa->ifa_index == nic->ifindex)
			nic->have_addr = 1;
		nic = nic->next;
	}

	return 0;
}

int enumerate_nics(struct net_section *section)
{
	if (rtnl_wilddump_request(&section->rth, AF_UNSPEC, RTM_GETLINK) < 0) {
		fprintf(stderr, "rtnl_wilddump_request() failed");
		return -1;
	}

	if (rtnl_dump_filter(&section->rth, getlink_filter, section) < 0) {
		fprintf(stderr, "rtnl_dump_filter() failed");
		return -1;
	}

	if (rtnl_wilddump_request(&section->rth, AF_UNSPEC, RTM_GETADDR) < 0) {
		fprintf(stderr, "rtnl_wilddump_request() failed");
		return -1;
	}

	if (rtnl_dump_filter(&section->rth, getaddr_filter, section) < 0) {
		fprintf(stderr, "rtnl_dump_filter() failed");
		return -1;
	}

	return 0;
}

static int error_handler(struct sockaddr_nl *nla, struct nlmsgerr *err,
			 void *arg)
{
	int *ret = arg;
	*ret = err->error;
	return NL_STOP;
}

static int finish_handler(struct nl_msg *msg, void *arg)
{
	int *ret = arg;
	*ret = 0;
	return NL_SKIP;
}

static int ack_handler(struct nl_msg *msg, void *arg)
{
	int *ret = arg;
	*ret = 0;
	return NL_STOP;
}

static int handle_nl_cmd(struct nl_sock *nl_sock, int nl80211_id,
			 signed long long devidx, uint8_t cmd, int flags,
			 int (*handler)(struct nl_msg *, void *), void *arg)
{
	struct nl_msg *msg = NULL;
	struct nl_cb *cb = NULL, *s_cb = NULL;
	int ret;

	msg = nlmsg_alloc();
	if (!msg) {
		fprintf(stderr, "Failed to allocate netlink message\n");
		ret = -1;
		goto out;
	}
	
	cb = nl_cb_alloc(NL_CB_DEFAULT);
	s_cb = nl_cb_alloc(NL_CB_DEFAULT);
	if (!cb || !s_cb) {
		fprintf(stderr, "Failed to allocate netlink callbacks\n");
		ret = -1;
		goto out;
	}

	genlmsg_put(msg, 0, 0, nl80211_id, 0, flags, cmd, 0);

	if (devidx)
		NLA_PUT_U32(msg, NL80211_ATTR_IFINDEX, devidx);

	nl_socket_set_cb(nl_sock, s_cb);

	ret = nl_send_auto_complete(nl_sock, msg);
	if (ret < 0)
		goto out;

	nl_cb_err(cb, NL_CB_CUSTOM, error_handler, &ret);
	nl_cb_set(cb, NL_CB_FINISH, NL_CB_CUSTOM, finish_handler, &ret);
	nl_cb_set(cb, NL_CB_ACK, NL_CB_CUSTOM, ack_handler, &ret);
	nl_cb_set(cb, NL_CB_VALID, NL_CB_CUSTOM, handler, arg);

	while (ret > 0)
		nl_recvmsgs(nl_sock, cb);

	ret = 0;
out:
	if (s_cb)
		nl_cb_put(s_cb);
	if (cb)
		nl_cb_put(cb);
	if (msg)
		nlmsg_free(msg);
	return ret;

nla_put_failure:
	fprintf(stderr, "NLA_PUT_U32 failed\n");
	ret = -1;
	goto out;
}

static int iface_handler(struct nl_msg *msg, void *arg)
{
	struct net_section *section = arg;
	struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));
	struct nlattr *tb_msg[NL80211_ATTR_MAX + 1];
	struct nic *nic;
	char *name;

	nla_parse(tb_msg, NL80211_ATTR_MAX, genlmsg_attrdata(gnlh, 0),
		  genlmsg_attrlen(gnlh, 0), NULL);

	if (tb_msg[NL80211_ATTR_IFNAME]) {
		name = nla_get_string(tb_msg[NL80211_ATTR_IFNAME]);
		nic = section->nics_head;
		while (nic) {
			if (strcmp(nic->name, name) == 0)
				nic->is_wifi = 1;
			nic = nic->next;
		}
	}

	return NL_SKIP;
}

int find_wifi_nics(struct net_section *section)
{
	return handle_nl_cmd(section->nl_sock, section->nl80211_id,
			     0, NL80211_CMD_GET_INTERFACE, NLM_F_DUMP,
			     iface_handler, section);
}

static int link_bss_handler(struct nl_msg *msg, void *arg)
{
	struct nic *nic = arg;
	struct nlattr *tb[NL80211_ATTR_MAX + 1];
	struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));
	struct nlattr *bss[NL80211_BSS_MAX + 1];
	static struct nla_policy bss_policy[NL80211_BSS_MAX + 1] = {
		[NL80211_BSS_TSF] = { .type = NLA_U64 },
		[NL80211_BSS_FREQUENCY] = { .type = NLA_U32 },
		[NL80211_BSS_BSSID] = { 0 },
		[NL80211_BSS_BEACON_INTERVAL] = { .type = NLA_U16 },
		[NL80211_BSS_CAPABILITY] = { .type = NLA_U16 },
		[NL80211_BSS_INFORMATION_ELEMENTS] = { 0 },
		[NL80211_BSS_SIGNAL_MBM] = { .type = NLA_U32 },
		[NL80211_BSS_SIGNAL_UNSPEC] = { .type = NLA_U8 },
		[NL80211_BSS_STATUS] = { .type = NLA_U32 },
	};
	unsigned char *ie;
	int ielen;

	nla_parse(tb, NL80211_ATTR_MAX, genlmsg_attrdata(gnlh, 0),
		  genlmsg_attrlen(gnlh, 0), NULL);

	if (!tb[NL80211_ATTR_BSS]) {
		fprintf(stderr, "bss info missing!\n");
		return NL_SKIP;
	}
	if (nla_parse_nested(bss, NL80211_BSS_MAX,
			     tb[NL80211_ATTR_BSS],
			     bss_policy)) {
		fprintf(stderr, "failed to parse nested attributes!\n");
		return NL_SKIP;
	}

	if (!bss[NL80211_BSS_BSSID])
		return NL_SKIP;

	if (!bss[NL80211_BSS_STATUS])
		return NL_SKIP;

	if (bss[NL80211_BSS_INFORMATION_ELEMENTS]) {
		ie = nla_data(bss[NL80211_BSS_INFORMATION_ELEMENTS]);
		ielen = nla_len(bss[NL80211_BSS_INFORMATION_ELEMENTS]);

		while (ielen >= 2 && ielen >= ie[1]) {
			if (ie[0] == 0) {
				nic->ssid_len = ie[1];
				nic->ssid = malloc(nic->ssid_len);
				if (!nic->ssid)
					return NL_STOP;
				memcpy(nic->ssid, ie + 2, nic->ssid_len);
			}
			ielen -= ie[1] + 2;
			ie += ie[1] + 2;
		}
	}

	return NL_SKIP;
}

static int link_sta_handler(struct nl_msg *msg, void *arg)
{
	struct nic *nic = arg;
	struct nlattr *tb[NL80211_ATTR_MAX + 1];
	struct genlmsghdr *gnlh = nlmsg_data(nlmsg_hdr(msg));
	struct nlattr *sinfo[NL80211_STA_INFO_MAX + 1];
	static struct nla_policy stats_policy[NL80211_STA_INFO_MAX + 1] = {
		[NL80211_STA_INFO_INACTIVE_TIME] = { .type = NLA_U32 },
		[NL80211_STA_INFO_RX_BYTES] = { .type = NLA_U32 },
		[NL80211_STA_INFO_TX_BYTES] = { .type = NLA_U32 },
		[NL80211_STA_INFO_RX_PACKETS] = { .type = NLA_U32 },
		[NL80211_STA_INFO_TX_PACKETS] = { .type = NLA_U32 },
		[NL80211_STA_INFO_SIGNAL] = { .type = NLA_U8 },
		[NL80211_STA_INFO_TX_BITRATE] = { .type = NLA_NESTED },
		[NL80211_STA_INFO_LLID] = { .type = NLA_U16 },
		[NL80211_STA_INFO_PLID] = { .type = NLA_U16 },
		[NL80211_STA_INFO_PLINK_STATE] = { .type = NLA_U8 },
	};

	nla_parse(tb, NL80211_ATTR_MAX, genlmsg_attrdata(gnlh, 0),
		  genlmsg_attrlen(gnlh, 0), NULL);

	if (!tb[NL80211_ATTR_STA_INFO]) {
		fprintf(stderr, "sta stats missing!\n");
		return NL_SKIP;
	}
	if (nla_parse_nested(sinfo, NL80211_STA_INFO_MAX,
			     tb[NL80211_ATTR_STA_INFO],
			     stats_policy)) {
		fprintf(stderr, "failed to parse nested attributes!\n");
		return NL_SKIP;
	}

	if (sinfo[NL80211_STA_INFO_SIGNAL]) {
		nic->signal = (int8_t)nla_get_u8(sinfo[NL80211_STA_INFO_SIGNAL]);
		nic->have_wifi_signal = 1;
	}

	return NL_SKIP;
}

int get_wifi_info(struct net_section *section, struct nic *nic)
{
	int ret;

	ret = handle_nl_cmd(section->nl_sock, section->nl80211_id, nic->ifindex,
			    NL80211_CMD_GET_SCAN, NLM_F_DUMP, link_bss_handler,
			    nic);
	if (ret)
		return ret;

	return handle_nl_cmd(section->nl_sock, section->nl80211_id,
			     nic->ifindex, NL80211_CMD_GET_STATION, NLM_F_DUMP,
			     link_sta_handler, nic);
}
