#ifndef GUI_DRAWBUTTON
#define GUI_DRAWBUTTON 1

#include <gui/button.h>
#include <math/vector.h>
#include <objc/objc.h>

struct gui_drawbutton {
	struct gui_button *button;
	struct objc_object *vertbuf;
	struct objc_object *indbuf;
};

struct gui_buttonverts {
	gvec(float,2) pos;
	gvec(float,2) uv;
};

void gui_drawbutton_initbufs(struct objc_object *device, struct objc_object **
		vertbuf, struct objc_object **indbuf, float xpos, float ypos,
		float width, float height);

void gui_drawbutton_draw(struct gui_drawbutton *, struct objc_object *encoder);

#endif /* GUI_DRAWBUTTON */
