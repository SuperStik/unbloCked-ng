#ifndef GUI_MAINMENU_H
#define GUI_MAINMENU_H 1

#include <math/vector.h>
#include <gui/button.h>

struct gui_mainmenu {
	struct gui_button buttons[5];
	struct gui_button_info buttoninfo[5];
};

struct gui_mainmenu *gui_mainmenu_init(struct gui_mainmenu *);

void gui_mainmenu_destroy(struct gui_mainmenu *);

void gui_mainmenu_onclick(struct gui_mainmenu *, float x, float y);

void gui_mainmenu_onhover(struct gui_mainmenu *, gvec(float,2) pos,
		gvec(float,2) area);

#endif /* GUI_MAINMENU_H */
