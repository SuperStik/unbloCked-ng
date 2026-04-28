#ifndef WORLD_WORLD_H
#define WORLD_WORLD_H 1

#include <world/chunklist.h>
#include <world/worldinfo.h>

struct ublc_world {
	struct ublc_chunklist chunklist;
	struct ublc_worldinfo info;
};

struct ublc_world *ublc_world_new(struct ublc_world *);

void ublc_world_delete(struct ublc_world *);

#endif /* WORLD_WORLD_H */
