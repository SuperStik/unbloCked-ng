#include <string.h>

#include "chunk.h"

static void chunk_init_base(struct ublc_chunk *restrict, struct ublc_world *restrict, long long
		xpos, long long ypos);

void ublc_chunk_init_empty(struct ublc_chunk *restrict chunk, struct
		ublc_world *restrict world, long long xpos, long long zpos) {
	chunk_init_base(chunk, world, xpos, zpos);
	memset(&chunk->blocks, 0, CHUNK_BLOCKS);
}

void ublc_chunk_init_blocks(struct ublc_chunk *restrict chunk, struct
		ublc_world *restrict world, long long xpos, long long zpos,
		const unsigned char blocks[CHUNK_BLOCKS]) {
	chunk_init_base(chunk, world, xpos, zpos);
	memcpy(&chunk->blocks, blocks, CHUNK_BLOCKS);
}

static void chunk_init_base(struct ublc_chunk *restrict chunk, struct
		ublc_world *restrict world, long long xpos, long long zpos) {
	chunk->world = world;
	chunk->xpos = xpos;
	chunk->zpos = zpos;
}
