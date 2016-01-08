#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <gdk/gdkx.h>
#include <gtk/gtk.h>
#include <libnotify/notify.h>
#include <pulse/pulseaudio.h>
#include <pulse/glib-mainloop.h>
#include <X11/Xlib.h>
#include <xkbcommon/xkbcommon.h>

#define APP_NAME "supavolumed"

/* Volume increment step in percent. */
#define VOLUME_INCREMENT 5

static NotifyNotification *notification;

enum {
	RAISE_VOLUME,
	LOWER_VOLUME,
	MUTE,
	MIC_MUTE,
};

static KeySym keysyms[] = {
	[RAISE_VOLUME] = XKB_KEY_XF86AudioRaiseVolume,
	[LOWER_VOLUME] = XKB_KEY_XF86AudioLowerVolume,
	[MUTE] = XKB_KEY_XF86AudioMute,
	[MIC_MUTE] = XKB_KEY_XF86AudioMicMute,
};

static KeyCode keycodes[sizeof(keysyms) / sizeof(keysyms[0])];

static void show_volume_notification(unsigned int volume_pct, int muted)
{
	const char *icon;

	if (muted)
		icon = "audio-volume-muted";
	else if (volume_pct == 0)
		icon = "audio-volume-off";
	else if (volume_pct < 33)
		icon = "audio-volume-low";
	else if (volume_pct < 66)
		icon = "audio-volume-medium";
	else
		icon = "audio-volume-high";

	if (notification) {
		GError *err = NULL;

		if (!notify_notification_update(notification, APP_NAME, NULL, icon)) {
			fprintf(stderr, "Invalid parameter passed to notify_notification_update()");
			return;
		}
		notify_notification_set_hint_int32(notification, "value",
						   (gint)volume_pct);
		notify_notification_show(notification, &err);
		if (err) {
			fprintf(stderr, "notify_notification_show() failed: %s\n", err->message);
			g_error_free(err);
			return;
		}
	}
}

static void simple_callback(pa_context *c, int success, void *userdata)
{
	if (!success) {
		fprintf(stderr, "Failure: %s\n",
			pa_strerror(pa_context_errno(c)));
	}
}

static unsigned int volume_pct_from_cv(const pa_cvolume *cv)
{
	unsigned int sum = 0;
	int i;

	for (i = 0; i < cv->channels; i++)
		sum += cv->values[i];

	return (100 * sum) / (cv->channels * PA_VOLUME_NORM);
}

static void change_sink_volume_callback(pa_context *c, const pa_sink_info *i,
					int is_last, void *userdata)
{
	pa_operation *o;
	pa_cvolume cv;
	int v;
	int j;

	if (is_last < 0) {
		fprintf(stderr, "Failed to get sink information: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}

	if (is_last)
		return;

	cv = i->volume;
	v = (intptr_t)userdata / 100.0 * PA_VOLUME_NORM;
	for (j = 0; j < cv.channels; j++) {
		if (v < 0 && cv.values[j] < -v)
			cv.values[j] = PA_VOLUME_MUTED;
		else if (v > 0 && cv.values[j] + v > PA_VOLUME_NORM)
			cv.values[j] = PA_VOLUME_NORM;
		else
			cv.values[j] += v;
	}

	o = pa_context_set_sink_volume_by_name(c, i->name, &cv, simple_callback,
					       NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}
	pa_operation_unref(o);

	show_volume_notification(volume_pct_from_cv(&cv), i->mute);
}

static void change_volume(pa_context *c, intptr_t increment)
{
	pa_operation *o;

	o = pa_context_get_sink_info_by_name(c, "@DEFAULT_SINK@",
					     change_sink_volume_callback,
					     (void *)increment);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}
	pa_operation_unref(o);
}

static void sink_toggle_mute_callback(pa_context *c, const pa_sink_info *i,
				      int is_last, void *userdata)
{
	pa_operation *o;

	if (is_last < 0) {
		fprintf(stderr, "Failed to get sink information: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}

	if (is_last)
		return;

	o = pa_context_set_sink_mute_by_name(c, i->name, !i->mute,
					     simple_callback, NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}
	pa_operation_unref(o);

	show_volume_notification(volume_pct_from_cv(&i->volume), !i->mute);
}

static void toggle_mute(pa_context *c)
{
	pa_operation *o;

	o = pa_context_get_sink_info_by_name(c, "@DEFAULT_SINK@",
					     sink_toggle_mute_callback, NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}
	pa_operation_unref(o);
}

static void source_toggle_mute_callback(pa_context *c, const pa_source_info *i,
					int is_last, void *userdata)
{
	pa_operation *o;

	if (is_last < 0) {
		fprintf(stderr, "Failed to get source information: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}

	if (is_last)
		return;

	o = pa_context_set_source_mute_by_name(c, i->name, !i->mute,
					     simple_callback, NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}
	pa_operation_unref(o);
}

static void toggle_mic_mute(pa_context *c)
{
	pa_operation *o;

	o = pa_context_get_source_info_by_name(c, "@DEFAULT_SOURCE@",
					       source_toggle_mute_callback,
					       NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(c)));
		return;
	}
	pa_operation_unref(o);
}

GdkFilterReturn filter(GdkXEvent *xevent, GdkEvent *event, gpointer data)
{
	XEvent *e = (XEvent *)xevent;
	pa_context *c = (pa_context *)data;

	if (pa_context_get_state(c) != PA_CONTEXT_READY)
		return GDK_FILTER_CONTINUE;

	switch (e->type) {
	case KeyPress:
		if (e->xkey.keycode == keycodes[RAISE_VOLUME])
			change_volume(c, +VOLUME_INCREMENT);
		else if (e->xkey.keycode == keycodes[LOWER_VOLUME])
			change_volume(c, -VOLUME_INCREMENT);
		else if (e->xkey.keycode == keycodes[MUTE])
			toggle_mute(c);
		else if (e->xkey.keycode == keycodes[MIC_MUTE])
			toggle_mic_mute(c);
		break;
	default:
		break;
	}

	return GDK_FILTER_CONTINUE;
}

static void context_state_callback(pa_context *c, void *userdata)
{
	switch (pa_context_get_state(c)) {
	case PA_CONTEXT_CONNECTING:
	case PA_CONTEXT_AUTHORIZING:
	case PA_CONTEXT_SETTING_NAME:
	case PA_CONTEXT_READY:
		break;
	case PA_CONTEXT_TERMINATED:
		gtk_main_quit();
		break;
	case PA_CONTEXT_FAILED:
	default:
		fprintf(stderr, "Connection failure: %s",
			pa_strerror(pa_context_errno(c)));
		gtk_main_quit();
		break;
	}
}

static void exit_signal_callback(pa_mainloop_api *m, pa_signal_event *e, int sig, void *userdata)
{
	gtk_main_quit();
}

int main(int argc, char **argv)
{
	pa_glib_mainloop *mainloop;
	pa_mainloop_api *mainloop_api;
	pa_context *context;
	GdkWindow *root;
	int status = EXIT_SUCCESS;
	int i;

	gtk_init(&argc, &argv);

	mainloop = pa_glib_mainloop_new(NULL);
	if (!mainloop) {
		fprintf(stderr, "pa_glib_mainloop_new() failed\n");
		status = EXIT_FAILURE;
		goto out;
	}

	mainloop_api = pa_glib_mainloop_get_api(mainloop);

	if (pa_signal_init(mainloop_api) < 0) {
		fprintf(stderr, "pa_signal_init() failed\n");
		status = EXIT_FAILURE;
		goto mainloop_free;
	}
	pa_signal_new(SIGINT, exit_signal_callback, NULL);
	pa_signal_new(SIGTERM, exit_signal_callback, NULL);

	context = pa_context_new(mainloop_api, NULL);
	if (!context) {
		fprintf(stderr, "pa_context_new() failed\n");
		status = EXIT_FAILURE;
		goto mainloop_free;
	}

	pa_context_set_state_callback(context, context_state_callback, NULL);
	if (pa_context_connect(context, NULL, 0, NULL) < 0) {
		fprintf(stderr, "pa_context_connect() failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		status = EXIT_FAILURE;
		goto context_unref;
	}

	if (!notify_init(APP_NAME)) {
		fprintf(stderr, "Could not initialize libnotify\n");
		status = EXIT_FAILURE;
		goto context_unref;
	}

	notification = notify_notification_new(APP_NAME, NULL, NULL);
	if (!notification) {
		fprintf(stderr, "notify_notification_new() failed\n");
		status = EXIT_FAILURE;
		goto notify_uninit;
	}

	notify_notification_set_timeout(notification, NOTIFY_EXPIRES_DEFAULT);
	notify_notification_set_hint_string(notification, "synchronous", "volume");

	root = gdk_get_default_root_window();

	gdk_window_set_events(root, GDK_KEY_PRESS_MASK);
	gdk_window_add_filter(root, filter, context);

	for (i = 0; i < sizeof(keysyms) / sizeof(keysyms[0]); i++) {
		keycodes[i] = XKeysymToKeycode(GDK_WINDOW_XDISPLAY(root), keysyms[i]);
		if (!keycodes[i]) {
			fprintf(stderr, "%s is not mapped on this keyboard\n",
				XKeysymToString(keysyms[i]));
			continue;
		}
		XGrabKey(GDK_WINDOW_XDISPLAY(root), keycodes[i], AnyModifier,
			 GDK_WINDOW_XID(root), False, GrabModeAsync,
			 GrabModeAsync);
	}

	gtk_main();

	g_object_unref(G_OBJECT(notification));
notify_uninit:
	notify_uninit();
context_unref:
	pa_context_unref(context);
mainloop_free:
	pa_glib_mainloop_free(mainloop);
out:
	return status;
}
