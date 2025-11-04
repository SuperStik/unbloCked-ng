#include <err.h>

#include "screen.h"

ssize_t gui_screen_onclick(struct gui_screen *screen, float x, float y) {
	warnx("screen: %p; click: (%g,%g)", screen, x, y);
	return -1;
}
