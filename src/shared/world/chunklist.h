#ifndef WORLD_CHUNKLIST_H
#define WORLD_CHUNKLIST_H 1

#include <stddef.h>
#include <world/chunk.h>

struct ublc_chunklist {
	struct ublc_chunk **chunks;
	size_t size;
	size_t count;
};

#define HELLO_C
struct ublc_chunklist *ublc_chunklist_init(struct ublc_chunklist *, size_t
		start_size);
void ublc_chunklist_delete(const struct ublc_chunklist *);

struct ublc_chunk *ublc_chunklist_get(const struct ublc_chunklist *, long long
		x, long long z);

struct ublc_chunk *ublc_chunklist_insert(struct ublc_chunklist *, struct
		ublc_chunk *);
struct ublc_chunk *ublc_chunklist_remove(struct ublc_chunklist *, long long x,
		long long z);

#endif
