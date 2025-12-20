#ifndef GUI_DRAWTEXT
#define GUI_DRAWTEXT 1

#include <math/vector.h>
#include <objc/objc.h>
#include <stddef.h>

struct gui_textvert {
	gvec(float,2) pos;
	gvec(_Float16,2) uv;
	unsigned char character;
};

unsigned gui_drawtext_maketextbuf(id device, id *buffer, id *indices, const
		char *string);

#endif /* GUI_DRAWTEXT */
