#include "mainmenu.h"

void gui_mainmenu_rebuild(struct gui_mainmenu *screen, float w, float h) {
	screen->screen.width = w;
	screen->screen.height = h;
	screen->screen.ctrllist = screen->buttons;
	screen->screen.ctrllistlen = 5;

	float wd2 = w / 2;
	float hd2 = h / 2;
	for (unsigned i = 0; i < 5; ++i)
		gui_button_init(&(screen->buttons[i]), i, wd2 - 25.0f, hd2 -
				8.0f, 50.0f, 16.0f, "BIG TEST");
}
