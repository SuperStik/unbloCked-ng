#include <math.h>

#include "scaledreso.h"

static float resolutionscale = 1.0f;

void setscaledreso(float w, float h) {
	float ratiowid = w / ((float)WIDTH * 0.5f);
	float ratiohgt = h / ((float)HEIGHT * 0.5f);

	float ratio = fminf(ratiowid, ratiohgt);
	resolutionscale = fmaxf(ratio, 1.0f);
}

void scaledreso(float *w, float *h) {
	float ratio = resolutionscale;
	*w /= ratio;
	*h /= ratio;
}
