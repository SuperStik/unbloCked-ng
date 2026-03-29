#include <cursor.h>
#include "hostworld.h"

struct gui_hostworld *gui_hostworld_init(struct gui_hostworld *screen) {
	gui_button_init(&screen->buttons[0], &screen->buttoninfo[0], NULL,
			-154.0f, -28.0f, 70.0f, 20.0f, "Rename");
	gui_button_init(&screen->buttons[1], &screen->buttoninfo[1], NULL,
			-74.0f, -52.0f, 70.0f, 20.0f, "Delete");
	gui_button_init(&screen->buttons[2], &screen->buttoninfo[2], NULL,
			-154.0f, -52.0f, 150.0f, 20.0f, "Play");
	gui_button_init(&screen->buttons[3], &screen->buttoninfo[3], NULL,
			4.0f, -52.0f, 150.0f, 20.0f, "Create New World");
	gui_button_init(&screen->buttons[4], &screen->buttoninfo[4], NULL,
			4.0f, 28.0f, 150.0f, 20.0f, "Cancel");
	return screen;
}

void gui_hostworld_destroy(struct gui_hostworld *screen) {
	for (int i = 0; i < 5; ++i)
		gui_button_destroy(&screen->buttons[i]);
}

void gui_hostworld_onclick(struct gui_hostworld *screen) {
	for (size_t i = 0; i < 5; ++i) {
		if (screen->buttoninfo[i].state == GUI_BUTTON_STATE_HOVERED) {
			gui_button_onclick onclick = screen->buttons[i].onclick;
			if (onclick != NULL)
				onclick();

			break;
		}
	}
}

void gui_hostworld_onhover(struct gui_hostworld *screen, gvec(float,2) pos,
		gvec(float,2) area) {
	char found = 0;
	for (size_t i = 0; i < 5; ++i) {
		if (!found && gui_button_inarea(&screen->buttons[i], pos,
					area)) {
			__atomic_store_n(&screen->buttoninfo[i].state,
					GUI_BUTTON_STATE_HOVERED,
					__ATOMIC_RELAXED);
			found = 1;
		} else if (screen->buttoninfo[i].state ==
				GUI_BUTTON_STATE_HOVERED)
			__atomic_store_n(&screen->buttoninfo[i].state,
					GUI_BUTTON_STATE_ENABLED,
					__ATOMIC_RELAXED);
	}

	SDL_SystemCursor id = SDL_SYSTEM_CURSOR_DEFAULT;
	if (found)
		id = SDL_SYSTEM_CURSOR_POINTER;

	cursor_set(id);
}
