#include "xoroshiro.h"

#ifdef __clang__
# define rotl64(x, k) __builtin_rotateleft64(x, k)
#else
static inline uint64_t rotl64(uint64_t x, int k) {
	return (x << k) | (x >> (64 - k));
}
#endif /* __clang__ */

void xoroshiro256_seed(struct xoroshiro256 *state, uint64_t seed) {
	/* seed with Splitmix64 */
	for (int i = 0; i < 4; ++i) {
		seed += 0x9e3779b97f4a7c15;

		uint64_t z = seed;
		z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9;
		z = (z ^ (z >> 27)) * 0x94d049bb133111eb;

		state->s[i] = z ^ (z >> 31);
	}
}

uint64_t xoroshiro256pp_next(struct xoroshiro256 *state) {
	const uint64_t state0 = state->s[0];
	const uint64_t result = rotl64(state0 + state->s[3], 23) + state0;

	const uint64_t state1 = state->s[1];
	const uint64_t t = state1 << 17;

	state->s[2] ^= state0;
	state->s[3] ^= state1;
	state->s[1] ^= state->s[2];
	state->s[0] ^= state->s[3];

	state->s[2] ^= t;

	state->s[3] = rotl64(state->s[3], 45);

	return result;
}

double xoroshiro256pp_nextdouble(struct xoroshiro256 *state) {
	union {
		double d;
		uint64_t i;
	} result;

	result.i = xoroshiro256pp_next(state) >> 12;
	result.i |= 0x3FF0000000000000;

	return result.d - 1.0;
}

gvec(float,2) xoroshiro256pp_nextfloats(struct xoroshiro256 *state) {
	union {
		gvec(float,2) f;
		uint64_t i;
	} result;

	result.i = xoroshiro256pp_next(state) & 0x7FFFFF007FFFFF;
	result.i |= 0x3F8000003F800000;

	return result.f - (gvec(float,2)){1.0f, 1.0f};
}
