#ifndef GUI_MAINMENU_H
#define GUI_MAINMENU_H 1

#include <gui/screen.h>

struct gui_mainmenu {
	struct gui_screen screen;
	struct gui_button buttons[5];
	struct gui_button_info buttoninfo[5];
};

struct gui_mainmenu *gui_mainmenu_init(struct gui_mainmenu *, float w, float h);

struct gui_mainmenu *gui_mainmenu_rebuild(struct gui_mainmenu *, float w, float
		h);

void gui_mainmenu_destroy(struct gui_mainmenu *);

#endif /* GUI_MAINMENU_H */
