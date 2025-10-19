#ifndef GUI_DRAWBUTTON
#define GUI_DRAWBUTTON 1

#include <gui/button.h>
#include <math/vector.h>
#include <objc/objc.h>

struct gui_drawbutton_info {
	gvec(float,2) pos;
	uint8_t anchor;
};

id gui_drawbutton_getverts(id device, float xpos, float ypos, float width,
		float height);
id gui_drawbutton_getinds(id device);

void gui_drawbutton_draw(id vertbuf, id indbuf, id encoder, struct
		gui_drawbutton_info *buttons, unsigned long count);

#endif /* GUI_DRAWBUTTON */
