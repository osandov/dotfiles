#include <errno.h>
#include <spawn.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/wait.h>

#include "sections.h"
#include "util.h"

/*
 * TODO: investigate a way to implement this without shelling out to dropbox.py.
 */

extern char **environ;

enum status dropbox_init(struct dropbox_section *section)
{
	memset(section, 0, sizeof(*section));
	return dropbox_update(section);
}

void dropbox_free(struct dropbox_section *section)
{
	str_free(&section->status);
}

static int read_all_output(struct dropbox_section *section, pid_t pid,
			   int pipefd)
{
	char buf[1024];
	ssize_t ssret;
	int status;
	int ret, ret2 = 0;

	section->status.len = 0;
	for (;;) {
		ssret = read(pipefd, buf, sizeof(buf));
		if (ssret == -1) {
			perror("read(pipefd)");
			ret2 = -1;
			goto wait;
		}
		if (ssret == 0)
			break;
		ret = str_append_buf(&section->status, buf, ssret);
		if (ret) {
			ret2 = -1;
			goto wait;
		}
	}
	ret = str_null_terminate(&section->status);
	if (ret)
		ret2 = -1;

wait:
	ret = waitpid(pid, &status, 0);
	if (ret == -1) {
		perror("waitpid");
		ret2 = -1;
		goto out;
	}
	if (!WIFEXITED(status) || WEXITSTATUS(status)) {
		fprintf(stderr, "dropbox.py exited abnormally\n");
		ret2 = -1;
	}

out:
	close(pipefd);
	return ret2;
}

enum status dropbox_update(struct dropbox_section *section)
{
	char *argv[] = {"dropbox.py", "status", NULL};
	posix_spawn_file_actions_t file_actions;
	posix_spawnattr_t attr;
	enum status status = SECTION_FATAL;
	sigset_t mask;
	int pipefd[2] = {-1, -1};
	pid_t pid;
	int ret;

	errno = posix_spawn_file_actions_init(&file_actions);
	if (errno) {
		perror("posix_spawn_file_actions_init");
		return SECTION_FATAL;
	}

	errno = posix_spawnattr_init(&attr);
	if (errno) {
		perror("posix_spawnattr_init");
		goto out_file_actions;
	}

	ret = pipe(pipefd);
	if (ret) {
		perror("pipe2");
		goto out_spawnattr;
	}

	errno = posix_spawn_file_actions_addclose(&file_actions, pipefd[0]);
	if (errno) {
		perror("posix_spawn_file_actions_addclose");
		goto out;
	}

	errno = posix_spawn_file_actions_adddup2(&file_actions, pipefd[1],
						 STDOUT_FILENO);
	if (errno) {
		perror("posix_spawn_file_actions_adddup2");
		goto out;
	}

	sigemptyset(&mask);
	errno = posix_spawnattr_setsigmask(&attr, &mask);
	if (errno) {
		perror("posix_spawnattr_setsigmask");
		goto out;
	}

	errno = posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETSIGMASK);
	if (errno) {
		perror("posix_spawnattr_setflags");
		goto out;
	}

	errno = posix_spawnp(&pid, "dropbox-cli", &file_actions, &attr, argv,
			     environ);
	if (errno) {
		perror("posix_spawnp");
		goto out;
	}

	close(pipefd[1]);
	ret = read_all_output(section, pid, pipefd[0]);
	if (ret)
		goto out;

	if (strcmp(section->status.buf, "Dropbox isn't running!\n") == 0)
		section->running = false;
	else
		section->running = true;

	if (strcmp(section->status.buf, "Up to date\n") == 0 ||
	    strcmp(section->status.buf, "Idle\n") == 0)
		section->uptodate = true;
	else
		section->uptodate = false;

	status = SECTION_SUCCESS;
out:
	close(pipefd[0]);
	close(pipefd[1]);
out_spawnattr:
	posix_spawnattr_destroy(&attr);
out_file_actions:
	posix_spawn_file_actions_destroy(&file_actions);
	return status;
}

int append_dropbox(const struct dropbox_section *section, struct str *str)
{
	struct timespec tp;
	char *c;
	int ret;

	ret = clock_gettime(CLOCK_MONOTONIC, &tp);
	if (ret) {
		perror("clock_gettime");
		return -1;
	}

	if (section->uptodate || tp.tv_sec % 2)
		ret = str_append_icon(str, "dropbox_idle");
	else
		ret = str_append_icon(str, "dropbox_busy");
	if (ret)
	    return -1;

	if (wordy) {
		if (str_append(str, " "))
			return -1;

		c = strchrnul(section->status.buf, '\n');
		if (str_append_buf(str, section->status.buf, c - section->status.buf))
			return -1;
	}

	return str_separator(str);
}
