#include <cursor.h>
#include "hostworld.h"
#include "screen.h"
#include <sound/sound.h>

static void button_cancel(void);

struct gui_hostworld *gui_hostworld_init(struct gui_hostworld *screen) {
	gui_button_init(&screen->buttons[0], &screen->buttoninfo[0], NULL,
			-119.0f, -92.0f, 70.0f, 20.0f, "Rename");
	gui_button_init(&screen->buttons[1], &screen->buttoninfo[1], NULL,
			-39.0f, -92.0f, 70.0f, 20.0f, "Delete");
	gui_button_init(&screen->buttons[2], &screen->buttoninfo[2], NULL,
			-79.0f, -68.0f, 150.0f, 20.0f, "Play");
	gui_button_init(&screen->buttons[3], &screen->buttoninfo[3], NULL,
			79.0f, -68.0f, 150.0f, 20.0f, "Create");
	gui_button_init(&screen->buttons[4], &screen->buttoninfo[4],
			button_cancel, 79.0f, -92.0f, 150.0f, 20.0f, "Cancel");
	for (int i = 0; i < 4; ++i)
		screen->buttoninfo[i].state = GUI_BUTTON_STATE_DISABLED;

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

static void button_cancel(void) {
	sound_restart(&sound.ui.click);
	gui_screen_switch(&screen, GUI_SCREEN_MAINMENU);
	cursor_set(SDL_SYSTEM_CURSOR_DEFAULT);
}
