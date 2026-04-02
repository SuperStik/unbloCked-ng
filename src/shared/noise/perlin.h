#ifndef NOISE_PERLIN_H
#define NOISE_PERLIN_H 1

#include <xoroshiro.h>

struct noise_perlin {
	double x_off;
	double y_off;
	double z_off;
	unsigned char permutation[256];
};

void noise_perlin_init(struct noise_perlin *, struct xoroshiro256 *rand);

double noise_perlin_get(const struct noise_perlin *, double x, double y, double
		z);
double noise_perlin_octaves(const struct noise_perlin *, double x, double y,
		double z, unsigned octaves, double persistence);

#endif /* NOISE_PERLIN_H */
