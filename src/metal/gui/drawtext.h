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

unsigned long gui_drawtext_maketextbuf(id device, id *buffer, id *indices,
		float *length, const char *string);
void gui_drawtext_maketextbuf_multi(id device, id *buffer, id *indices, float *
		lengths, const char *const *strings, unsigned strcount,
		unsigned long *charcounts);

void gui_drawtext_draw(id encoder, id buffer, id indices, const gvec(float,4)
		transform[4], gvec(_Float16,4) color, unsigned long count);
void gui_drawtext_draw_multi(id encoder, id buffer, id indices, const
		gvec(float,4) *transform, const gvec(_Float16,4) *color, const
		unsigned long *vertcount, unsigned textcount);

#endif /* GUI_DRAWTEXT */
