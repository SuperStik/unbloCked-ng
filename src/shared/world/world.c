#include "world.h"

struct ublc_world *ublc_world_new(struct ublc_world *world) {
	ublc_chunklist_init(&world->chunklist, 0);
	ublc_worldinfo_new(&world->info, "TEST");

	return world;
}

void ublc_world_delete(struct ublc_world *world) {
	ublc_chunklist_delete(&world->chunklist);
	ublc_worldinfo_delete(&world->info);
}
