#include <err.h>

#include <cursor.h>
#include <sound/sound.h>

#include "screen.h"

void gui_screen_onclick(struct gui_screen *screen) {
	size_t len = screen->ctrllistlen;
	struct gui_button_info *info = screen->ctrlinfo;
	struct gui_button *button = screen->ctrllist;

	for (size_t i = 0; i < len; ++i) {
		if (info[i].state == GUI_BUTTON_STATE_HOVERED) {
			sound_restart(&sound.ui.click);

			gui_button_onclick onclick = button[i].onclick;
			if (onclick != NULL)
				onclick();

			break;
		}
	}
}

/* TODO: make this not run like donkey dookie */
void gui_screen_onhover(struct gui_screen *screen, float x, float y) {
	size_t len = screen->ctrllistlen;
	struct gui_button *start = screen->ctrllist;
	struct gui_button_info *info = screen->ctrlinfo;
	gvec(float,2) pos = {x, y};
	gvec(float,2) area = {screen->width, screen->height};

	int found = 0;
	for (size_t i = 0; i < len; ++i) {
		if (!found && gui_button_inarea(start + i, pos, area)) {
			info[i].state = GUI_BUTTON_STATE_HOVERED;
			found = 1;
		} else if (info[i].state == GUI_BUTTON_STATE_HOVERED)
			info[i].state = GUI_BUTTON_STATE_ENABLED;
	}

	if (found)
		cursor_set(SDL_SYSTEM_CURSOR_POINTER);
	else
		cursor_set(SDL_SYSTEM_CURSOR_DEFAULT);
}
