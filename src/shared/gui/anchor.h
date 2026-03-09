#ifndef GUI_ANCHOR_H
#define GUI_ANCHOR_H 1

#include <math/vector.h>

enum anchor {
	ANC_TOPLEFT,
	ANC_TOPMIDDLE,
	ANC_TOPRIGHT,
	ANC_MIDDLELEFT,
	ANC_MIDDLE,
	ANC_MIDDLERIGHT,
	ANC_BOTTOMLEFT,
	ANC_BOTTOMMIDDLE,
	ANC_BOTTOMRIGHT
};

gvec(float,2) anc_getoffset(enum anchor, gvec(float,2) window_size,
		gvec(float,2) position);

#endif /* GUI_ANCHOR_H */
