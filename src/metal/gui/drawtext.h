#ifndef GUI_DRAWTEXT
#define GUI_DRAWTEXT 1

#include <math/vector.h>
#include <objc/objc.h>
#include <stddef.h>

struct gui_textvert {
	gvec(float,2) pos;
	gvec(_Float16,2) uv;
	unsigned char character;
	unsigned char color;
};

unsigned gui_drawtext_maketextbuf(id device, id *buffer, id *indices,
		float *length, const char *string);

void gui_drawtext_draw(id encoder, id buffer, id indices, const gvec(float,4)
		transform[4], gvec(_Float16,4) color, unsigned count);

#endif /* GUI_DRAWTEXT */
