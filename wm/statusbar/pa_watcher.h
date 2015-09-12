#ifndef PA_WATCHER_H
#define PA_WATCHER_H

#include <stdbool.h>

struct pa_volume {
	bool muted;
	double volume;
};

void pa_watcher(int fd);

#endif /* PA_WATCHER_H */
