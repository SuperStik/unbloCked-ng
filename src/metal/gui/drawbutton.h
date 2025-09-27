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

id gui_drawbutton_getverts(id device, float xpos, float ypos, float width,
		float height);
id gui_drawbutton_getinds(id device);

void gui_drawbutton_draw(struct gui_drawbutton *, id encoder);

#endif /* GUI_DRAWBUTTON */
