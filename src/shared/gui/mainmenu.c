#include "mainmenu.h"

static void mainmenu_resize(struct gui_mainmenu *, float w, float h);

struct gui_mainmenu *gui_mainmenu_init(struct gui_mainmenu *screen, float w,
		float h) {
	mainmenu_resize(screen, w, h);
	screen->screen.ctrllist = screen->buttons;
	screen->screen.ctrlinfo = screen->buttoninfo;
	screen->screen.ctrllistlen = 5;

	float wd2 = w / 2;
	float hd2 = h / 2;
	gui_button_init(&screen->buttons[0], &screen->buttoninfo[0], 0.0f,
			-12.0f, 200.0f, 20.0f, "Local Play");
	gui_button_init(&screen->buttons[1], &screen->buttoninfo[1], 0.0f,
			-36.0f, 200.0f, 20.0f, "Net Play");
	gui_button_init(&screen->buttons[2], &screen->buttoninfo[2], 0.0f,
			-60.0f, 200.0f, 20.0f, "Texture Packs");
	gui_button_init(&screen->buttons[3], &screen->buttoninfo[3], -51.0f,
			-96.0f, 98.0f, 20.0f, "Options");
	gui_button_init(&screen->buttons[4], &screen->buttoninfo[4], 51.0f,
			-96.0f, 98.0f, 20.0f, "Quit");

	for (int i = 1; i < 4; ++i)
		screen->buttoninfo[i].state = GUI_BUTTON_STATE_DISABLED;

	return screen;
}

struct gui_mainmenu *gui_mainmenu_resize(struct gui_mainmenu *screen, float w,
		float h) {
	mainmenu_resize(screen, w, h);

	float wd2 = w / 2;
	float hd2 = h / 2;

	return screen;
}

void gui_mainmenu_destroy(struct gui_mainmenu *screen) {
	for (int i = 0; i < 5; ++i)
		gui_button_destroy(&(screen->buttons[i]));
}

static void mainmenu_resize(struct gui_mainmenu *screen, float w, float h) {
	screen->screen.width = w;
	screen->screen.height = h;
}
