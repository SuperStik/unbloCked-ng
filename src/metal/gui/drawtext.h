#ifndef GUI_DRAWTEXT
#define GUI_DRAWTEXT 1

#include <math/vector.h>

struct gui_textvert {
	gvec(float,2) pos;
	gvec(_Float16,2) uv;
	unsigned char character;
};

#endif /* GUI_DRAWTEXT */
