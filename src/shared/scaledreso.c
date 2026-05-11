#include <math.h>

#include "scaledreso.h"

static float resolutionscale = 1.0f;

void setscaledreso(int32_t w, int32_t h) {
	float ratiowid = w / (WIDTH / 2);
	float ratiohgt = h / (HEIGHT / 2);

	float ratio = fminf(ratiowid, ratiohgt);
	resolutionscale = fmaxf(ratio, 1.0f);
}

void scaledreso(float *w, float *h) {
	float ratio = resolutionscale;
	*w /= ratio;
	*h /= ratio;
}
