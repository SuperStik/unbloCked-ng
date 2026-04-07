#ifndef WORLD_WORLD_H
#define WORLD_WORLD_H 1

#include <world/worldinfo.h>

struct ublc_world {
	struct ublc_chunklist *chunklist;
	struct ublc_worldinfo info;
};

#endif /* WORLD_WORLD_H */
