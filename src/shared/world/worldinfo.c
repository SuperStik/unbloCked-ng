#include <stdlib.h>
#include <string.h>

#include "worldinfo.h"

struct ublc_worldinfo *ublc_worldinfo_new(struct ublc_worldinfo *info, const
		char *name) {
	uint64_t seed = arc4random();
	seed <<= 32;
	seed |= arc4random();

	return ublc_worldinfo_newseeded(info, name, seed);
}

struct ublc_worldinfo *ublc_worldinfo_newseeded(struct ublc_worldinfo *info,
		const char *name, uint64_t seed) {
	info->seed = seed;
	info->name = strdup(name);
	arc4random_buf(&info->id, sizeof(info->id));

	return info;
}

void ublc_worldinfo_delete(const struct ublc_worldinfo *info) {
	free(info->name);
}
