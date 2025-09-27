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

struct objc_object *gui_drawbutton_getverts(struct objc_object *device,
		float xpos, float ypos, float width, float height);
struct objc_object *gui_drawbutton_getinds(struct objc_object *device);

void gui_drawbutton_draw(struct gui_drawbutton *, struct objc_object *encoder);

#endif /* GUI_DRAWBUTTON */
