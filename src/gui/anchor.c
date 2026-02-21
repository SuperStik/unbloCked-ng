#include "anchor.h"

gvec(float,2) anc_getoffset(enum anchor anc, gvec(float,2) winsize,
		gvec(float,2) pos){
	gvec(float,2) offset;
	
	switch (anc) {
		default:
		case ANC_TOPLEFT:
			offset = (gvec(float,2)){0.0f, 0.0f};
			break;
		case ANC_TOPMIDDLE:
			offset = (gvec(float,2)){winsize[0] / 2.0f, 0.0f};
			break;
		case ANC_TOPRIGHT:
			offset = (gvec(float,2)){winsize[0] / 2.0f, 0.0f};
			break;
		case ANC_MIDDLELEFT:
			offset = (gvec(float,2)){0.0f, winsize[1] / 2.0f};
			break;
		case ANC_MIDDLE:
			offset = winsize / 2.0f;
			break;
		case ANC_MIDDLERIGHT:
			offset = (gvec(float,2)){winsize[0], winsize[1] / 2.0f};
			break;
		case ANC_BOTTOMLEFT:
			offset = (gvec(float,2)){0.0f, winsize[1]};
			break;
		case ANC_BOTTOMMIDDLE:
			offset = (gvec(float,2)){winsize[0] / 2.0f, winsize[1]};
			break;
		case ANC_BOTTOMRIGHT:
			offset = winsize;
	}

	return pos + offset;
}
