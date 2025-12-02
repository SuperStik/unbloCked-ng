#include "mainmenu.h"

void gui_mainmenu_rebuild(struct gui_mainmenu *screen, float w, float h) {
	screen->screen.width = w;
	screen->screen.height = h;
	screen->screen.ctrllist = screen->buttons;
	screen->screen.ctrlinfo = screen->buttoninfo;
	screen->screen.ctrllistlen = 5;

	float wd2 = w / 2;
	float hd2 = h / 2;
	for (int i = 0; i < 5; ++i)
		gui_button_init(&(screen->buttons[i]), &(screen->buttoninfo[i]),
				i, 0.0f, i * -24, 50.0f, 16.0f,
				"BIG TEST");
}
