#ifndef WORLD_CHUNKLIST_H
#define WORLD_CHUNKLIST_H 1

#include <world/chunk.h>

struct ublc_chunklist {
	struct ublc_chunk *chunks;
	size_t size;
	size_t count;
};

struct ublc_chunklist *ublc_chunklist_init(struct ublc_chunklist *, size_t
		start_size);
void ublc_chunklist_delete(const struct ublc_chunklist *);

#endif
