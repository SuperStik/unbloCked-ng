#include <err.h>

#include <sound/sound.h>

#include "screen.h"

ssize_t gui_screen_onclick(struct gui_screen *screen, float x, float y) {
	warnx("screen: %p; click: (%g,%g)", screen, x, y);

	size_t len = screen->ctrllistlen;
	struct gui_button *start = screen->ctrllist;
	gvec(float,2) pos = {x, y};
	gvec(float,2) area = {screen->width, screen->height};

	for (size_t i = 0; i < len; ++i) {
		if (gui_button_mousepressed(start + i, pos, area)) {
			sound_restart(&sound.ui.click);
			break;
		}
	}

	return -1;
}
