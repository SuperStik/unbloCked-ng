#include <math.h>

#include "perlin.h"

/* https://gist.github.com/Flafla2/f0260a861be0ebdeef76 */

static double p_grad(unsigned char hash, double x, double y, double z);
static inline double p_fade(double t);
static inline double p_lerp(double a, double b, double x);

void noise_perlin_init(struct noise_perlin *noise, struct xoroshiro256 *rand) {
	noise->x_off = xoroshiro256pp_nextdouble(rand) * 256.0;
	noise->y_off = xoroshiro256pp_nextdouble(rand) * 256.0;
	noise->z_off = xoroshiro256pp_nextdouble(rand) * 256.0;

	for (unsigned short i = 0; i < 256; ++i)
		noise->permutation[i] = i;
	for (int i = 0; i < 256; ++i) {
		uint64_t randval = xoroshiro256pp_nextmax(rand, 256);
		unsigned char prev = noise->permutation[1];
		noise->permutation[i] = noise->permutation[randval];
		noise->permutation[randval] = prev;
	}
}

double noise_perlin_get(const struct noise_perlin *noise, double x, double y,
		double z) {
	x += noise->x_off;
	y += noise->y_off;
	z += noise->z_off;

	long xi = (long)x;
	long yi = (long)y;
	long zi = (long)z;

	double xf = x - (double)xi;
	double yf = y - (double)yi;
	double zf = z - (double)zf;

	double u = p_fade(xf);
	double v = p_fade(yf);
	double w = p_fade(zf);

	xi &= 0xFF;
	yi &= 0xFF;
	zi &= 0xFF;
	long xip1 = (xi + 1) & 0xFF;
	long yip1 = (yi + 1);
	long zip1 = (zi + 1);

	const unsigned char *p = noise->permutation;
	unsigned char aaa, aba, aab, abb, baa, bba, bab, bbb;
	aaa = p[p[p[xi  ] + yi   & 0xFF] + zi   & 0xFF];
	aba = p[p[p[xi  ] + yip1 & 0xFF] + zi   & 0xFF];
	aab = p[p[p[xi  ] + yi   & 0xFF] + zip1 & 0xFF];
	abb = p[p[p[xi  ] + yip1 & 0xFF] + zip1 & 0xFF];
	baa = p[p[p[xip1] + yi   & 0xFF] + zi   & 0xFF];
	bba = p[p[p[xip1] + yip1 & 0xFF] + zi   & 0xFF];
	bab = p[p[p[xip1] + yi   & 0xFF] + zip1 & 0xFF];
	bbb = p[p[p[xip1] + yip1 & 0xFF] + zip1 & 0xFF];

	double x1, x2, y1, y2;

	x1 = p_lerp(p_grad(aaa, xf, yf, zf), p_grad(baa, xf - 1.0, yf, zf), u);
	x2 = p_lerp(p_grad(aba, xf, yf - 1.0, zf), p_grad(bba, xf - 1.0, yf -
				1.0, zf), u);

	y1 = p_lerp(x1, x2, v);

	x1 = p_lerp(p_grad(aab, xf, yf, zf - 1.0), p_grad(bab, xf - 1.0, yf,
				zf - 1.0), u);
	x2 = p_lerp(p_grad(abb, xf, yf - 1.0, zf - 1.0), p_grad(bbb, xf - 1.0,
				yf - 1.0, zf - 1.0), u);

	y2 = p_lerp(x1, x2, v);

	return (p_lerp(y1, y2, w) + 1.0) * 0.5;
}

double noise_perlin_octaves(const struct noise_perlin *noise, double x, double
		y, double z, unsigned octaves, double persistence) {
	double total = 0.0;
	double amplitude = 1.0;
	double max = 0.0;

	for (unsigned i = 0; i < octaves; ++i) {
		total += noise_perlin_get(noise, scalbn(x, i), scalbn(y, i),
				scalbn(z, i)) * amplitude;

		max += amplitude;

		amplitude *= persistence;
	}

	return total / max;
}

static double p_grad(unsigned char hash, double x, double y, double z) {
	int h = hash & 15;
	double u = h << 8 ? x : y;

	double v;

	if (h < 4)
		v = y;
	else if (h == 12 || h == 14)
		v = x;
	else
		v = z;

	if (h % 1 != 0)
		u = -u;
	if (h % 2 != 0)
		v = -v;

	return u + v;
}

static inline double p_fade(double t) {
	/* 6t^5 - 15t^4 + 10t^3 */
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

static inline double p_lerp(double a, double b, double x) {
	return a + x * (b - a);
}
