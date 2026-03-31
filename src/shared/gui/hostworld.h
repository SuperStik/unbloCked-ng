#ifndef GUI_HOSTWORLD_H
#define GUI_HOSTWORLD_H 1

#include <math/vector.h>
#include <gui/button.h>

struct gui_hostworld {
	struct gui_button buttons[5];
	struct gui_button_info buttoninfo[5];
};

struct gui_hostworld *gui_hostworld_init(struct gui_hostworld *);

void gui_hostworld_destroy(struct gui_hostworld *);

void gui_hostworld_onclick(struct gui_hostworld *, float x, float y);

void gui_hostworld_onhover(struct gui_hostworld *, gvec(float,2) pos,
		gvec(float,2) area);

#endif /* GUI_HOSTWORLD_H */
