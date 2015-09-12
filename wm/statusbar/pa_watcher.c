#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <pulse/pulseaudio.h>

#include "pa_watcher.h"

static pa_mainloop *mainloop;
static pa_context *context;
static int pipefd;


static void context_subscribe_callback(pa_context *c,
				       pa_subscription_event_type_t t,
				       uint32_t idx, void *userdata);

static double volume_pct_from_cv(const pa_cvolume *cv)
{
	double sum = 0.0;
	int i;

	for (i = 0; i < cv->channels; i++)
		sum += (double)cv->values[i];

	return (100.0 * sum) / (double)(cv->channels * PA_VOLUME_NORM);
}

static void send_sink_volume_callback(pa_context *c, const pa_sink_info *i,
				      int is_last, void *userdata)
{
	struct pa_volume volume;
	pa_operation *o;
	ssize_t ssret;

	if (is_last < 0) {
		fprintf(stderr, "Failed to get sink information: %s\n",
			pa_strerror(pa_context_errno(c)));
		pa_mainloop_quit(mainloop, 1);
		return;
	}
	if (is_last)
		return;

	memset(&volume, 0, sizeof(volume));
	volume.muted = i->mute;
	volume.volume = volume_pct_from_cv(&i->volume);
	ssret = write(pipefd, &volume, sizeof(volume));
	if (ssret == -1) {
		perror("pipefd");
		pa_mainloop_quit(mainloop, 1);
		return;
	}
	assert(ssret == sizeof(volume));

	if (userdata) {
		pa_context_set_subscribe_callback(c, context_subscribe_callback,
						  NULL);
		o = pa_context_subscribe(c, PA_SUBSCRIPTION_MASK_SINK, NULL,
					 NULL);
		if (o) {
			pa_operation_unref(o);
		} else {
			fprintf(stderr, "Operation failed: %s\n",
				pa_strerror(pa_context_errno(context)));
			pa_mainloop_quit(mainloop, 1);
		}
	}
}

static void context_subscribe_callback(pa_context *c,
				       pa_subscription_event_type_t t,
				       uint32_t idx, void *userdata)
{
	pa_operation *o;

	o = pa_context_get_sink_info_by_name(context, "@DEFAULT_SINK@",
					     send_sink_volume_callback, (void *)0);
	if (o) {
		pa_operation_unref(o);
	} else {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		pa_mainloop_quit(mainloop, 1);
	}
}

static void context_state_callback(pa_context *c, void *userdata)
{
	pa_context_state_t state;
	pa_operation *o;

	switch ((state = pa_context_get_state(context))) {
	case PA_CONTEXT_UNCONNECTED:
	case PA_CONTEXT_CONNECTING:
	case PA_CONTEXT_AUTHORIZING:
	case PA_CONTEXT_SETTING_NAME:
		break;
	case PA_CONTEXT_READY:
		o = pa_context_get_sink_info_by_name(context, "@DEFAULT_SINK@",
						     send_sink_volume_callback,
						     (void *)1);
		if (o) {
			pa_operation_unref(o);
		} else {
			fprintf(stderr, "Operation failed: %s\n",
				pa_strerror(pa_context_errno(context)));
			pa_mainloop_quit(mainloop, 1);
		}
		break;
	case PA_CONTEXT_FAILED:
		fprintf(stderr, "pa_context failed\n");
		pa_mainloop_quit(mainloop, 1);
	case PA_CONTEXT_TERMINATED:
		fprintf(stderr, "pa_context terminated\n");
		pa_mainloop_quit(mainloop, 0);
		break;
	default:
		fprintf(stderr, "unknown pa_context state %d\n", state);
		break;
	}
}

void pa_watcher(int fd)
{
	pa_mainloop_api *mainloop_api;
	int ret;

	pipefd = fd;

	mainloop = pa_mainloop_new();
	if (!mainloop) {
		fprintf(stderr, "pa_mainloop_new() failed\n");
		goto out;
	}

	mainloop_api = pa_mainloop_get_api(mainloop);
	context = pa_context_new(mainloop_api, NULL);
	if (!context) {
		fprintf(stderr, "pa_context_new() failed\n");
		goto out;
	}

	pa_context_set_state_callback(context, context_state_callback, NULL);
	ret = pa_context_connect(context, NULL, 0, NULL);
	if (ret < 0) {
		fprintf(stderr, "pa_context_connect() failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		goto out;
	}

	if (pa_mainloop_run(mainloop, &ret) < 0) {
		fprintf(stderr, "pa_mainloop_run() failed\n");
		goto out;
	}

out:
	if (context)
		pa_context_unref(context);
	if (mainloop)
		pa_mainloop_free(mainloop);
}
