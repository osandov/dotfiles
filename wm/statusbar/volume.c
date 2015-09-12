#include <assert.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

#include "sections.h"
#include "pa_watcher.h"
#include "util.h"

enum status volume_init(struct volume_section *section)
{
	int pipefd[2];
	pid_t pid;
	int ret;

	memset(section, 0, sizeof(*section));
	section->fd = -1;

	ret = pipe2(pipefd, O_CLOEXEC);
	if (ret) {
		perror("pipe2");
		return SECTION_FATAL;
	}

	pid = fork();
	if (pid == -1) {
		perror("fork");
		close(pipefd[0]);
		close(pipefd[1]);
		return SECTION_FATAL;
	}

	if (pid) {
		section->child = pid;
		section->fd = pipefd[0];
		close(pipefd[1]);
		return SECTION_SUCCESS;
	} else {
		close(pipefd[0]);
		/* TODO: close all other file descriptors? */
		pa_watcher(pipefd[1]);
		/* This shouldn't return unless there's an error. */
		exit(EXIT_FAILURE);
	}
}

void volume_free(struct volume_section *section)
{
	if (section->child)
		kill(section->child, SIGKILL);
	if (section->fd != -1)
		close(section->fd);
}

enum status volume_update(struct volume_section *section)
{
	struct pa_volume volume;
	ssize_t ssret;

	/*
	 * TODO: keep reading while there's stuff in the pipe and just use the
	 * last one?
	 */
	ssret = read(section->fd, &volume, sizeof(volume));
	if (ssret == -1) {
		perror("read");
		return SECTION_FATAL;
	}
	assert(ssret == sizeof(volume));

	section->muted = volume.muted;
	section->volume = volume.volume;

	return SECTION_SUCCESS;
}

int append_volume(const struct volume_section *section, struct str *str)
{
	if (section->muted) {
		if (str_append_icon(str, "spkr_mute"))
			return -1;
		if (str_append(str, " MUTE"))
			return -1;
	} else  {
		if (str_append_icon(str, "spkr_play"))
			return -1;
		if (str_appendf(str, " %.0f%%", section->volume))
			return -1;
	}
	return str_separator(str);
}
