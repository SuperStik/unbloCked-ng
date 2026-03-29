#ifndef GUI_DRAWHOSTWORLD_H
#define GUI_DRAWHOSTWORLD_H 1

#include <gui/hostworld.h>
#include <math/vector.h>
#include <objc/objc.h>

struct gui_drawhostworld {
	struct gui_button_info *buttoninfo;

	struct {
		id button;
		id text;
	} pipeline;

	struct {
		id font;
		id gui;
	} texture;

	id buttonverts[2];
	id buttoninds;

	id textbuf;
	id textind;
	gvec(float,4) texttransforms[4 * 5];
	unsigned long textvertcounts[5];
};

void gui_drawhostworld_init(struct gui_drawhostworld *, struct gui_hostworld *,
		id device);
void gui_drawhostworld_release(const struct gui_drawhostworld *);

void gui_drawhostworld_draw_opaque(const struct gui_drawhostworld *, id
		render_encoder);
void gui_drawhostworld_draw_blended(const struct gui_drawhostworld *, id
		render_encoder);

#endif /* GUI_DRAWHOSTWORLD_H */
