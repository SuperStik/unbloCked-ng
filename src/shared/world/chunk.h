#ifndef WORLD_CHUNK_H
#define WORLD_CHUNK_H 1

#define CHUNK_SIDE 16UL
#define CHUNK_HEIGHT 128UL
#define CHUNK_BLOCKS ((CHUNK_SIDE) * (CHUNK_SIDE) * (CHUNK_HEIGHT))

struct ublc_chunk {
	long long xpos;
	long long zpos;
	unsigned char blocks[CHUNK_BLOCKS];
};

void ublc_chunk_init_empty(struct ublc_chunk *restrict, long long xpos, long
		long zpos);
void ublc_chunk_init_blocks(struct ublc_chunk *restrict, long long xpos, long
		long zpos, const unsigned char blocks[CHUNK_BLOCKS]);

#endif /* WORLD_CHUNK_H */
