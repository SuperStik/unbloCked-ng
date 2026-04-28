#include <string.h>

#include "chunk.h"

static void chunk_init_base(struct ublc_chunk *restrict, long long xpos, long
		long zpos);

void ublc_chunk_init_empty(struct ublc_chunk *restrict chunk, long long xpos,
		long long zpos) {
	chunk_init_base(chunk, xpos, zpos);
	memset(&chunk->blocks, 0, CHUNK_BLOCKS);
}

void ublc_chunk_init_blocks(struct ublc_chunk *restrict chunk, long long xpos,
		long long zpos, const unsigned char blocks[CHUNK_BLOCKS]) {
	chunk_init_base(chunk, xpos, zpos);
	memcpy(&chunk->blocks, blocks, CHUNK_BLOCKS);
}

static void chunk_init_base(struct ublc_chunk *restrict chunk, long long xpos,
		long long zpos) {
	chunk->xpos = xpos;
	chunk->zpos = zpos;
}
