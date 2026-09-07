#ifndef GUI_DRAWLOADING_H
#define GUI_DRAWLOADING_H 1

#include <math/vector.h>
#include <objc/objc.h>

struct gui_drawloading {
	id pipeline_text;
	id texture_font;

	id textbuf;
	id textind;
	gvec(float,4) texttransform[4];
	unsigned long textvertcount;
};

void gui_drawloading_init(struct gui_drawloading *, id device);
void gui_drawloading_release(const struct gui_drawloading *);

void gui_drawloading_draw_blended(const struct gui_drawloading *, id
		render_encoder);

#endif /* GUI_DRAWLOADING_H */
