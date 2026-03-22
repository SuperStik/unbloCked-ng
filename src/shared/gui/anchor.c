#include "anchor.h"

gvec(float,2) anc_getoffset(enum anchor anc, gvec(float,2) pos, gvec(float,2)
		area) {
	pos[1] = -pos[1];
	area[1] = -area[1];
	gvec(float,2) offset;
	
	switch (anc) {
		default:
		case ANC_TOPLEFT:
			offset = (gvec(float,2)){0.0f, 0.0f};
			break;
		case ANC_TOPMIDDLE:
			offset = (gvec(float,2)){area[0] / 2.0f, 0.0f};
			break;
		case ANC_TOPRIGHT:
			offset = (gvec(float,2)){area[0] / 2.0f, 0.0f};
			break;
		case ANC_MIDDLELEFT:
			offset = (gvec(float,2)){0.0f, area[1] / 2.0f};
			break;
		case ANC_MIDDLE:
			offset = area / 2.0f;
			break;
		case ANC_MIDDLERIGHT:
			offset = (gvec(float,2)){area[0], area[1] / 2.0f};
			break;
		case ANC_BOTTOMLEFT:
			offset = (gvec(float,2)){0.0f, area[1]};
			break;
		case ANC_BOTTOMMIDDLE:
			offset = (gvec(float,2)){area[0] / 2.0f, area[1]};
			break;
		case ANC_BOTTOMRIGHT:
			offset = area;
	}

	return pos - offset;
}
