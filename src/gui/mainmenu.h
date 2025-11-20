#ifndef GUI_MAINMENU_H
#define GUI_MAINMENU_H 1

#include <gui/screen.h>

struct gui_mainmenu {
	struct gui_screen screen;
	struct gui_button buttons[5];
	struct gui_button_info buttoninfo[5];
};

void gui_mainmenu_rebuild(struct gui_mainmenu *, float w, float h);

#endif /* GUI_MAINMENU_H */
