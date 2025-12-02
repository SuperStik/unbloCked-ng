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
	for (int i = 0; i < 5; ++i)
		gui_button_init(&(screen->buttons[i]), &(screen->buttoninfo[i]),
				i, 0.0f, i * -24, 50.0f, 16.0f, "TEST");

	return screen;
}

struct gui_mainmenu *gui_mainmenu_resize(struct gui_mainmenu *screen, float w,
		float h) {
	mainmenu_resize(screen, w, h);

	float wd2 = w / 2;
	float hd2 = h / 2;
	for (int i = 0; i < 5; ++i)
		gui_button_resize(&(screen->buttons[i]), 0.0f, i * -24, 50.0f,
				16.0f);

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
