#ifndef GUI_DRAWMAINMENU
#define GUI_DRAWMAINMENU 1

#include <gui/mainmenu.h>
#include <math/vector.h>
#include <objc/objc.h>

struct gui_drawmainmenu {
	struct gui_button_info *buttoninfo;

	struct {
		id button;
		id text;
	} pipeline;

	struct {
		id font;
		id gui;
	} texture;

	id buttonverts;
	id buttoninds;

	id textbufs[5];
	id textinds[5];
	gvec(float,4) texttransforms[4 * 5];
	unsigned long textvertcounts[5];
};

void gui_drawmainmenu_init(struct gui_drawmainmenu *, struct gui_mainmenu *, id
		device);

void gui_drawmainmenu_draw_opaque(const struct gui_drawmainmenu *, id
		render_encoder);
void gui_drawmainmenu_draw_blended(const struct gui_drawmainmenu *, id
		render_encoder);

void gui_drawmainmenu_release(const struct gui_drawmainmenu *);

#endif /* GUI_DRAWMAINMENU */
