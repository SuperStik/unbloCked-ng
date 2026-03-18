#include <err.h>

#include <sound/sound.h>

#include "screen.h"

void gui_screen_onclick(struct gui_screen *screen, float x, float y) {
	size_t len = screen->ctrllistlen;
	struct gui_button *start = screen->ctrllist;
	gvec(float,2) pos = {x, y};
	gvec(float,2) area = {screen->width, screen->height};

	for (size_t i = 0; i < len; ++i) {
		if (gui_button_inarea(start + i, pos, area)) {
			sound_restart(&sound.ui.click);
			break;
		}
	}
}

/* TODO: make this not run like donkey dookie */
void gui_screen_onhover(struct gui_screen *screen, float x, float y) {
	size_t len = screen->ctrllistlen;
	struct gui_button *start = screen->ctrllist;
	gvec(float,2) pos = {x, y};
	gvec(float,2) area = {screen->width, screen->height};

	for (size_t i = 0; i < len; ++i) {
		if (gui_button_inarea(start + i, pos, area))
			start[i].info->state = GUI_BUTTON_STATE_HOVERED;
		else if (start[i].info->state == GUI_BUTTON_STATE_HOVERED)
			start[i].info->state = GUI_BUTTON_STATE_ENABLED;
	}
}
