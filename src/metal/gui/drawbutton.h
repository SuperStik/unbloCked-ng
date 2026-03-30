#ifndef GUI_DRAWBUTTON
#define GUI_DRAWBUTTON 1

#include <gui/button.h>
#include <math/vector.h>
#include <objc/objc.h>

struct gui_buttonverts {
	gvec(float,2) pos;
	gvec(float,2) uv;
};

id gui_drawbutton_getverts(id device, float width, float height);
id gui_drawbutton_getinds(id device);

void gui_drawbutton_prepare(id encoder, const struct gui_button_info *, unsigned
		long count);

void gui_drawbutton_draw(id encoder, id vertbuf, id indbuf);
void gui_drawbutton_draw_inst(id encoder, id vertbuf, id indbuf, unsigned long
		count);
void gui_drawbutton_draw_instbase(id encoder, id vertbuf, id indbuf, unsigned
		long count, unsigned long base);

#endif /* GUI_DRAWBUTTON */
