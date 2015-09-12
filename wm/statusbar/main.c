#include <assert.h>
#include <errno.h>
#include <inttypes.h>
#include <poll.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <sys/signalfd.h>
#include <sys/socket.h>
#include <sys/timerfd.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/wait.h>

#include "sections.h"
#include "util.h"

extern char **environ;

bool wordy;

static struct str status_str = STR_INIT;

static struct cpu_section cpu_section;
static struct dropbox_section dropbox_section;
static struct mem_section mem_section;
static struct net_section net_section;
static struct power_section power_section;
static struct volume_section volume_section;

static int update_on_timer(void)
{
	enum status status;

#define UPDATE_SECTION(section)	do {				\
	if (section##_section.init) {				\
		status = section##_update(&section##_section);	\
		if (status == SECTION_FATAL)			\
			return -1;				\
	}							\
} while (0)

	UPDATE_SECTION(cpu);
	UPDATE_SECTION(dropbox);
	UPDATE_SECTION(mem);
	UPDATE_SECTION(net);
	UPDATE_SECTION(power);

#undef UPDATE_SECTION

	return 0;
}

static int append_time(struct str *str)
{
	time_t t;
	struct tm tm;
	char buf[100];
	size_t sret;

	if (str_append_icon(str, "clock"))
		return -1;

	t = time(NULL);
	if (t == (time_t)-1) {
		perror("time");
		return -1;
	}
	if (!localtime_r(&t, &tm)) {
		perror("localtime_r");
		return -1;
	}
	sret = strftime(buf, sizeof(buf), " %a, %b %d %I:%M:%S %p", &tm);
	if (sret == 0) {
		perror("strftime");
		return -1;
	}

	return str_append(str, buf);
}

static int do_update(void)
{
	char *argv[] = {"xsetroot", "-name", status_str.buf, NULL};
	int status;
	pid_t pid;
	int ret;

	errno = posix_spawnp(&pid, "xsetroot", NULL, NULL, argv, environ);
	if (errno) {
		perror("posix_spawnp");
		return -1;
	}

	ret = waitpid(pid, &status, 0);
	if (ret == -1) {
		perror("waitpid");
		return -1;
	}
	if (!WIFEXITED(status) || WEXITSTATUS(status)) {
		fprintf(stderr, "xsetroot exited abnormally\n");
		return -1;
	}

	return 0;
}

static int update_statusbar(void)
{
	status_str.len = 0;

	if (str_append(&status_str, " "))
		return -1;

#define APPEND_SECTION(section) do {					\
	if (section##_section.init) {					\
		if (append_##section(&section##_section, &status_str))	\
			return -1;					\
	}								\
} while (0)

	if (dropbox_section.running)
		APPEND_SECTION(dropbox);
	APPEND_SECTION(net);
	APPEND_SECTION(cpu);
	APPEND_SECTION(mem);
	APPEND_SECTION(power);
	APPEND_SECTION(volume);

#undef APPEND_SECTION

	if (append_time(&status_str))
		return -1;
	
	if (str_null_terminate(&status_str))
		return -1;
	
	if (do_update())
		return -1;

	return 0;
}

static int get_ctl_addr(struct sockaddr_un *addr)
{
	char *env, *home, *display;
	int ret;

	memset(addr, 0, sizeof(*addr));
	addr->sun_family = AF_UNIX;

	env = getenv("HOME");
	if (!env) {
		fprintf(stderr, "HOME is not set\n");
		return -1;
	}
	home = strdup(env);
	if (!home) {
		perror("strdup");
		return -1;
	}

	env = getenv("DISPLAY");
	if (!env) {
		fprintf(stderr, "DISPLAY is not set\n");
		free(home);
		return -1;
	}
	display = strdup(env);
	if (!display) {
		perror("strdup");
		free(home);
		return -1;
	}

	ret = snprintf(addr->sun_path, sizeof(addr->sun_path),
		       "%s/.statusbar-%s.ctl", home, display);
	if (ret >= sizeof(addr->sun_path)) {
		fprintf(stderr, "Control socket path too long\n");
		ret = -1;
	} else {
		ret = 0;
	}

	free(home);
	free(display);
	return ret;
}

int main(void)
{
	int signal_fd = -1;
	struct sockaddr_un ctl_addr;
	int ctl_fd = -1;
	int timer_fd = -1;
	struct itimerspec it;
	sigset_t mask;
	struct pollfd pollfds[4];
	int ret;
	ssize_t ssret;
	enum status section_status;
	int status = EXIT_SUCCESS;

	sigemptyset(&mask);
	sigaddset(&mask, SIGINT);
	sigaddset(&mask, SIGTERM);
	sigaddset(&mask, SIGCHLD);
	ret = sigprocmask(SIG_BLOCK, &mask, NULL);
	if (ret == -1) {
		perror("sigprocmask");
		status = EXIT_FAILURE;
		goto out;
	}
	signal_fd = signalfd(-1, &mask, SFD_CLOEXEC);
	if (signal_fd == -1) {
		perror("signalfd");
		status = EXIT_FAILURE;
		goto out;
	}

	pollfds[0].fd = signal_fd;
	pollfds[0].events = POLLIN;
	pollfds[0].revents = 0;

	timer_fd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC);
	if (timer_fd == -1) {
		perror("timerfd_create");
		status = EXIT_FAILURE;
		goto out;
	}

	pollfds[1].fd = timer_fd;
	pollfds[1].events = POLLIN;
	pollfds[1].revents = 0;

	ret = get_ctl_addr(&ctl_addr);
	if (ret == -1) {
		status = EXIT_FAILURE;
		goto out;
	}

	ctl_fd = socket(AF_UNIX, SOCK_DGRAM, 0);
	if (ctl_fd == -1) {
		perror("socket");
		status = EXIT_FAILURE;
		goto out;
	}

	ret = unlink(ctl_addr.sun_path);
	if (ret == -1 && errno != ENOENT) {
		perror("unlink");
		status = EXIT_FAILURE;
		goto out;
	}

	ret = bind(ctl_fd, &ctl_addr, sizeof(ctl_addr));
	if (ret == -1) {
		perror("bind");
		status = EXIT_FAILURE;
		goto out;
	}

	pollfds[2].fd = ctl_fd;
	pollfds[2].events = POLLIN;
	pollfds[2].revents = 0;

#define INIT_SECTION(section) do {						\
	section_status = section##_init(&section##_section);			\
	if (section_status == SECTION_FATAL) {					\
		status = EXIT_FAILURE;						\
		goto out;							\
	} else if (section_status == SECTION_ERROR) {				\
		fprintf(stderr, "Ignoring " #section " section\n");		\
	} else if (section_status == SECTION_SUCCESS) {				\
		section##_section.init = 1;					\
	}									\
} while (0)

	INIT_SECTION(cpu);
	INIT_SECTION(dropbox);
	INIT_SECTION(mem);
	INIT_SECTION(net);
	INIT_SECTION(power);
	INIT_SECTION(volume);
	if (ret == SECTION_SUCCESS) {
		pollfds[3].fd = volume_section.fd;
		pollfds[3].events = POLLIN;
		pollfds[3].revents = 0;
	} else {
		pollfds[3].fd = -1;
		pollfds[3].events = 0;
		pollfds[3].revents = 0;
	}

#undef INIT_SECTION

	it.it_interval.tv_sec = 1;
	it.it_interval.tv_nsec = 0;
	it.it_value.tv_sec = 1;
	it.it_value.tv_nsec = 0;
	ret = timerfd_settime(timer_fd, 0, &it, NULL);
	if (ret == -1) {
		perror("timerfd_settime");
		status = EXIT_FAILURE;
		goto out;
	}

	for (;;) {
		bool update = false;

		ret = poll(pollfds, sizeof(pollfds) / sizeof(pollfds[0]), -1);
		if (ret == -1) {
			perror("poll");
			status = EXIT_FAILURE;
			goto out;
		}
		
		if (pollfds[0].revents & POLLIN) {
			struct signalfd_siginfo ssi;

			ssret = read(signal_fd, &ssi, sizeof(ssi));
			if (ssret == -1) {
				perror("read(signal_fd)");
				status = EXIT_FAILURE;
				goto out;
			}
			assert(ssret == sizeof(ssi));
			if (ssi.ssi_signo == SIGCHLD) {
				if (ssi.ssi_pid == volume_section.child) {
					volume_section.child = 0;
					volume_section.init = false;
					fprintf(stderr, "Ignoring volume section\n");
				}
				continue;
			}
			fprintf(stderr, "got signal %s; exiting\n",
				strsignal(ssi.ssi_signo));
			status = EXIT_SUCCESS;
			goto out;
		}

		if (pollfds[1].revents & POLLIN) {
			uint64_t times;

			ssret = read(timer_fd, &times, sizeof(times));
			if (ssret == -1) {
				perror("read(timer_fd)");
				status = EXIT_FAILURE;
				goto out;
			}
			assert(ssret == sizeof(times));
			if (times > 1) {
				fprintf(stderr, "Warning: missed %" PRIu64 " ticks",
					times - 1);
			}
			ret = update_on_timer();
			if (ret) {
				status = EXIT_FAILURE;
				goto out;
			}
			update = true;
		}

		if (pollfds[2].revents & POLLIN) {
			char buf[20];

			ssret = read(ctl_fd, buf, sizeof(buf));
			if (ssret == -1) {
				perror("read(ctl_fd)");
				status = EXIT_FAILURE;
				goto out;
			}

			if (ssret == strlen("togglewordy") &&
			    memcmp(buf, "togglewordy", ssret) == 0) {
				wordy ^= true;
				update = true;
			}
		}

		if (pollfds[3].revents & POLLIN) {
			section_status = volume_update(&volume_section);
			if (section_status == SECTION_FATAL) {
				status = EXIT_FAILURE;
				goto out;
			}
			update = true;
		}

		if (update) {
			ret = update_statusbar();
			if (ret) {
				status = EXIT_FAILURE;
				goto out;
			}
		}
	}

out:
	volume_free(&volume_section);
	power_free(&power_section);
	net_free(&net_section);
	mem_free(&mem_section);
	dropbox_free(&dropbox_section);
	cpu_free(&cpu_section);
	if (ctl_fd != -1) {
		close(ctl_fd);
		unlink(ctl_addr.sun_path);
	}
	if (timer_fd != -1)
		close(timer_fd);
	if (signal_fd != -1)
		close(signal_fd);
	str_free(&status_str);
	return status;
}
