#include <SDL3/SDL_events.h>
#include <SDL3/SDL_timer.h>

#include <cursor.h>
#include "mainmenu.h"
#include <sound/sound.h>

static void quitgame(void);

struct gui_mainmenu *gui_mainmenu_init(struct gui_mainmenu *screen) {
	gui_button_init(&screen->buttons[0], &screen->buttoninfo[0], NULL, 0.0f,
			-12.0f, 200.0f, 20.0f, "Local Play");
	gui_button_init(&screen->buttons[1], &screen->buttoninfo[1], NULL, 0.0f,
			-36.0f, 200.0f, 20.0f, "Net Play");
	gui_button_init(&screen->buttons[2], &screen->buttoninfo[2], NULL, 0.0f,
			-60.0f, 200.0f, 20.0f, "Texture Packs");
	gui_button_init(&screen->buttons[3], &screen->buttoninfo[3], NULL,
			-51.0f, -96.0f, 98.0f, 20.0f, "Options");
	gui_button_init(&screen->buttons[4], &screen->buttoninfo[4], quitgame,
			51.0f, -96.0f, 98.0f, 20.0f, "Quit");

	for (int i = 1; i < 4; ++i)
		screen->buttoninfo[i].state = GUI_BUTTON_STATE_DISABLED;

	return screen;
}

void gui_mainmenu_destroy(struct gui_mainmenu *screen) {
	for (int i = 0; i < 5; ++i)
		gui_button_destroy(&(screen->buttons[i]));
}

void gui_mainmenu_onclick(struct gui_mainmenu *screen) {
	for (size_t i = 0; i < 5; ++i) {
		if (screen->buttoninfo[i].state == GUI_BUTTON_STATE_HOVERED) {
			sound_restart(&sound.ui.click);

			gui_button_onclick onclick = screen->buttons[i].onclick;
			if (onclick != NULL)
				onclick();

			break;
		}
	}
}

/* TODO: make this not run like donkey dookie */
void gui_mainmenu_onhover(struct gui_mainmenu *screen, gvec(float,2) pos,
		gvec(float,2) area) {
	char found = 0;
	for (size_t i = 0; i < 5; ++i) {
		if (!found && gui_button_inarea(&screen->buttons[i], pos,
					area)) {
			screen->buttoninfo[i].state = GUI_BUTTON_STATE_HOVERED;
			found = 1;
		} else if (screen->buttoninfo[i].state ==
				GUI_BUTTON_STATE_HOVERED)
			screen->buttoninfo[i].state = GUI_BUTTON_STATE_ENABLED;
	}

	if (found)
		cursor_set(SDL_SYSTEM_CURSOR_POINTER);
	else
		cursor_set(SDL_SYSTEM_CURSOR_DEFAULT);
}

static void quitgame(void) {
	SDL_Event event;
	event.type = SDL_EVENT_QUIT;
	event.quit.reserved = 0;
	event.quit.timestamp = SDL_GetTicksNS();

	SDL_PushEvent(&event);
}
