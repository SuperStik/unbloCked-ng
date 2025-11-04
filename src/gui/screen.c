#include <err.h>

#include "screen.h"

ssize_t gui_screen_onclick(struct gui_screen *screen, float x, float y) {
	warnx("screen: %p; click: (%g,%g)", screen, x, y);

	size_t len = screen->ctrllistlen;
	struct gui_button *start = screen->ctrllist;
	for (size_t i = 0; i < len; ++i)
		gui_button_mousepressed(start + i, x, y);

	return -1;
}
