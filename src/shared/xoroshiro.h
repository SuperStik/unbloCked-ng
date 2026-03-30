#ifndef XOROSHIRO_H
#define XOROSHIRO_H 1

#include <math/vector.h>
#include <stdint.h>

struct xoroshiro256 {
	uint64_t s[4];
};

void xoroshiro256_seed(struct xoroshiro256 *, uint64_t seed);

uint64_t xoroshiro256pp_next(struct xoroshiro256 *);

double xoroshiro256pp_nextdouble(struct xoroshiro256 *state);

gvec(float,2) xoroshiro256pp_nextfloats(struct xoroshiro256 *state);

#endif /* XOROSHIRO_H */
