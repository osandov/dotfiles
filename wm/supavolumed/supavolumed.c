#include <stdio.h>
#include <stdlib.h>

#include <libnotify/notify.h>
#include <pulse/pulseaudio.h>
#include <X11/Xlib.h>
#include <xkbcommon/xkbcommon.h>

#define APP_NAME "supavolumed"

static Display *display;
static gboolean notify_inited;
static NotifyNotification *notification;
static pa_mainloop *mainloop;
static pa_context *context;
static int actions;

/* Volume increment step in percent. */
#define VOLUME_INCREMENT 5.0

static void init_x11(void)
{
	static KeySym keysyms[] = {
		XKB_KEY_XF86AudioRaiseVolume,
		XKB_KEY_XF86AudioLowerVolume,
		XKB_KEY_XF86AudioMute,
		XKB_KEY_XF86AudioMicMute,
	};
	KeyCode code;
	Window root;
	int screen;
	size_t i;

	display = XOpenDisplay(NULL);
	if (!display) {
		fprintf(stderr, "Could not open display\n");
		exit(EXIT_FAILURE);
	}

	XAllowEvents(display, AsyncKeyboard, CurrentTime);

	for (screen = 0; screen < ScreenCount(display); screen++) {
		root = RootWindow(display, screen);
		XSelectInput(display, root, KeyPressMask);
		for (i = 0; i < sizeof(keysyms) / sizeof(keysyms[0]); i++) {
			code = XKeysymToKeycode(display, keysyms[i]);
			if (!code) {
				fprintf(stderr, "%s is not mapped on this keyboard\n",
					XKeysymToString(keysyms[i]));
				continue;
			}
			XGrabKey(display, code, AnyModifier, root, False,
				 GrabModeAsync, GrabModeAsync);
		}
	}
}

static void cleanup_x11(void)
{
	Window root;
	int screen;

	if (display) {
		for (screen = 0; screen < ScreenCount(display); screen++) {
			root = RootWindow(display, screen);
			XUngrabKey(display, AnyKey, AnyModifier, root);
		}

		XCloseDisplay(display);
	}
}

static void init_notify(void)
{
	notify_inited = notify_init(APP_NAME);
	if (!notify_inited) {
		fprintf(stderr, "Could not initialize libnotify\n");
		return;
	}

	notification = notify_notification_new(APP_NAME, NULL, NULL);
	if (!notification) {
		fprintf(stderr, "notify_notification_new() failed\n");
		return;
	}

	notify_notification_set_timeout(notification, NOTIFY_EXPIRES_DEFAULT);
	notify_notification_set_hint_string(notification, "synchronous", "volume");
}

static void cleanup_notify(void)
{
	if (notification)
		g_object_unref(G_OBJECT(notification));
	if (notify_inited)
		notify_uninit();
}

static void init_pulse(void)
{
	pa_mainloop_api *mainloop_api;
	pa_context_state_t state;
	int ret;

	mainloop = pa_mainloop_new();
	if (!mainloop) {
		fprintf(stderr, "pa_mainloop_new() failed\n");
		exit(EXIT_FAILURE);
	}

	mainloop_api = pa_mainloop_get_api(mainloop);
	context = pa_context_new(mainloop_api, NULL);
	if (!context) {
		fprintf(stderr, "pa_context_new() failed\n");
		exit(EXIT_FAILURE);
	}

	ret = pa_context_connect(context, NULL, 0, NULL);
	if (ret < 0) {
		fprintf(stderr, "pa_context_connect() failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		exit(EXIT_FAILURE);
	}

	while (1) {
		switch ((state = pa_context_get_state(context))) {
		case PA_CONTEXT_UNCONNECTED:
		case PA_CONTEXT_CONNECTING:
		case PA_CONTEXT_AUTHORIZING:
		case PA_CONTEXT_SETTING_NAME:
			break;
		case PA_CONTEXT_READY:
			return;
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

		ret = pa_mainloop_iterate(mainloop, 1, NULL);
		if (ret < 0) {
			fprintf(stderr, "pa_mainloop_iterate() failed\n");
			exit(EXIT_FAILURE);
		}
	}
}

static void cleanup_pulse(void)
{
	if (context)
		pa_context_unref(context);
	if (mainloop)
		pa_mainloop_free(mainloop);
}

static void cleanup(int status, void *arg)
{
	cleanup_pulse();
	cleanup_notify();
	cleanup_x11();
}

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

	actions--;
}

static void run_all_actions(void)
{
	int ret;

	while (actions > 0) {
		ret = pa_mainloop_iterate(mainloop, 1, NULL);
		if (ret < 0) {
			fprintf(stderr, "pa_mainloop_iterate() failed\n");
			exit(EXIT_FAILURE);
		}
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
		actions--;
		return;
	}

	if (is_last)
		return;

	cv = i->volume;
	v = *(double *)userdata * PA_VOLUME_NORM / 100.0;
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
			pa_strerror(pa_context_errno(context)));
		actions--;
		return;
	}
	pa_operation_unref(o);

	show_volume_notification(volume_pct_from_cv(&cv), i->mute);
}

static void change_volume(double increment)
{
	pa_operation *o;

	o = pa_context_get_sink_info_by_name(context, "@DEFAULT_SINK@",
					     change_sink_volume_callback,
					     (void *)&increment);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		return;
	}
	actions++;
	pa_operation_unref(o);
	run_all_actions();
}

static void sink_toggle_mute_callback(pa_context *c, const pa_sink_info *i,
				      int is_last, void *userdata)
{
	pa_operation *o;

	if (is_last < 0) {
		fprintf(stderr, "Failed to get sink information: %s\n",
			pa_strerror(pa_context_errno(c)));
		actions--;
		return;
	}

	if (is_last)
		return;

	o = pa_context_set_sink_mute_by_name(c, i->name, !i->mute,
					     simple_callback, NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		actions--;
		return;
	}
	pa_operation_unref(o);

	show_volume_notification(volume_pct_from_cv(&i->volume), !i->mute);
}

static void toggle_mute(void)
{
	pa_operation *o;

	o = pa_context_get_sink_info_by_name(context, "@DEFAULT_SINK@",
					     sink_toggle_mute_callback, NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		return;
	}
	actions++;
	pa_operation_unref(o);
	run_all_actions();
}

static void source_toggle_mute_callback(pa_context *c, const pa_source_info *i,
					int is_last, void *userdata)
{
	pa_operation *o;

	if (is_last < 0) {
		fprintf(stderr, "Failed to get source information: %s\n",
			pa_strerror(pa_context_errno(c)));
		actions--;
		return;
	}

	if (is_last)
		return;

	o = pa_context_set_source_mute_by_name(c, i->name, !i->mute,
					     simple_callback, NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		actions--;
		return;
	}
	pa_operation_unref(o);
}

static void toggle_mic_mute(void)
{
	pa_operation *o;

	o = pa_context_get_source_info_by_name(context, "@DEFAULT_SOURCE@",
					       source_toggle_mute_callback,
					       NULL);
	if (!o) {
		fprintf(stderr, "Operation failed: %s\n",
			pa_strerror(pa_context_errno(context)));
		return;
	}
	actions++;
	pa_operation_unref(o);
	run_all_actions();
}

int main(int argc, char **argv)
{
	XEvent e;
	KeyCode raise_code, lower_code, mute_code, mic_mute_code;

	on_exit(cleanup, NULL);
	init_x11();
	init_notify();
	init_pulse();

	raise_code = XKeysymToKeycode(display, XKB_KEY_XF86AudioRaiseVolume);
	lower_code = XKeysymToKeycode(display, XKB_KEY_XF86AudioLowerVolume);
	mute_code = XKeysymToKeycode(display, XKB_KEY_XF86AudioMute);
	mic_mute_code = XKeysymToKeycode(display, XKB_KEY_XF86AudioMicMute);

	while (1) {
		XNextEvent(display, &e);
		switch (e.type) {
		case KeyPress:
			if (e.xkey.keycode == raise_code)
				change_volume(+VOLUME_INCREMENT);
			else if (e.xkey.keycode == lower_code)
				change_volume(-VOLUME_INCREMENT);
			else if (e.xkey.keycode == mute_code)
				toggle_mute();
			else if (e.xkey.keycode == mic_mute_code)
				toggle_mic_mute();
			break;
		default:
			break;
		}
	}

	return EXIT_SUCCESS;
}
