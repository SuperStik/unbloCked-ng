#ifndef XOROSHIRO_H
#define XOROSHIRO_H 1

#include <stdint.h>

struct xoroshiro256 {
	uint64_t s[4];
};

void xoroshiro256_seed(struct xoroshiro256 *, uint64_t seed);

uint64_t xoroshiro256pp_next(struct xoroshiro256 *);

#endif /* XOROSHIRO_H */
