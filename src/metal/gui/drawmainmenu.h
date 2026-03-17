#ifndef GUI_DRAWMAINMENU
#define GUI_DRAWMAINMENU 1

#include <objc/objc.h>

struct gui_drawmainmenu {
	struct gui_screen *screen;

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
	unsigned textvertcounts[5];
};

void gui_drawmainmenu_init(struct gui_drawmainmenu *, struct gui_screen *, id
		device);

void gui_drawmainmenu_draw_opaque(const struct gui_drawmainmenu *, id
		render_encoder);
void gui_drawmainmenu_draw_blended(const struct gui_drawmainmenu *, id
		render_encoder);

void gui_drawmainmenu_release(const struct gui_drawmainmenu *);

#endif /* GUI_DRAWMAINMENU */
