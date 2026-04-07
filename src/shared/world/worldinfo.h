#ifndef WORLD_WORLDINFO_H
#define WORLD_WORLDINFO_H 1

#include <stdint.h>

struct ublc_worldinfo {
	char *name;
	uint64_t seed;
	uint64_t id[2];
};

struct ublc_worldinfo *ublc_worldinfo_new(struct ublc_worldinfo *, const char *
		name);
struct ublc_worldinfo *ublc_worldinfo_newseeded(struct ublc_worldinfo *, const
		char *name, uint64_t seed);

void ublc_worldinfo_delete(const struct ublc_worldinfo *);

#endif /* WORLD_WORLDINFO_H */
