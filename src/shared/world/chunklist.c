#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "chunklist.h"

#define CHUNKLIST_ALLOC_COUNT 32

static void chunk_insert(struct ublc_chunklist_node *dst, size_t dst_size, const
		struct ublc_chunk *src);

static void chunklist_expand(struct ublc_chunklist *chunklist);
static void chunklist_contract(struct ublc_chunklist *chunklist);

static size_t pairing_szudzik(long long a, long long b);

struct ublc_chunklist *ublc_chunklist_init(struct ublc_chunklist *chunklist,
		size_t start_size) {
	if (start_size == 0) {
		chunklist->chunks = NULL;
		chunklist->size = 0;
	} else {
		chunklist->size = start_size;

		void *chunks;
		/* NULL may not be 0 on esoteric systems */
		if (NULL == (void *)0) {
			chunks = calloc(start_size, sizeof(struct
						ublc_chunklist_node));
			if (chunks == NULL)
				err(1, "calloc");
		} else {
			chunks = malloc(sizeof(struct ublc_chunklist_node) *
					start_size);
			if (chunks == NULL)
				err(1, "malloc");

			for (size_t i = 0; i < start_size; ++i)
				((struct ublc_chunklist_node *)chunks)[i]
					.state = 0;
		}

		chunklist->chunks = chunks;
	}

	chunklist->count = 0;

	return chunklist;
}

void ublc_chunklist_delete(const struct ublc_chunklist *chunklist) {
	free(chunklist->chunks);
}

struct ublc_chunklist *ublc_chunklist_insert(struct ublc_chunklist *chunklist,
		const struct ublc_chunk *chunk) {
	if (chunklist->size == chunklist->count)
		chunklist_expand(chunklist);

	chunk_insert(chunklist->chunks, chunklist->size, chunk);

	return chunklist;
}

struct ublc_chunklist *ublc_chunklist_remove(struct ublc_chunklist *chunklist,
		long long x, long long z) {
	if (chunklist->count <= chunklist->size / 2)
		chunklist_contract(chunklist);

	struct ublc_chunklist_node *chunks = chunklist->chunks;
	size_t index = pairing_szudzik(x, z) % chunklist->size;

	for (size_t i = 0; i < chunklist->size; ++i) {
		switch (chunklist->chunks[index].state) {
			case 0:
				return NULL;
			case 1:
				if (chunks[index].chunk.xpos == x &&
						chunks[index].chunk.zpos == z) {
					chunklist->chunks[index].state = 2;
					return chunklist;
				}
			case 2:
				index = (index + 1) % chunklist->size;
		}
	}

	return NULL;
}

static void chunk_insert(struct ublc_chunklist_node *dst, size_t dst_size, const
		struct ublc_chunk *src) {
	size_t index = pairing_szudzik(src->xpos, src->zpos) % dst_size;
	while (dst[index].state == 1)
		index = (index + 1) % dst_size;

	memcpy(&(dst[index].chunk), src, sizeof(*src));
	dst[index].state = 1;
}

static void chunk_move(struct ublc_chunklist_node *dst, size_t dst_size, const
		struct ublc_chunklist_node *src, size_t src_size, size_t
		src_count) {
	size_t j = 0;
	for (size_t i = 0; i < src_size && j < src_count; ++i) {
		if (src[i].state != 1)
			continue;

		chunk_insert(dst, dst_size, &(src[i].chunk));

		++j;
	}
}

static void chunklist_expand(struct ublc_chunklist *chunklist) {
	size_t size = CHUNKLIST_ALLOC_COUNT;
	if (chunklist->size != 0)
		size = chunklist->size * 2;

	struct ublc_chunklist_node *chunks;
	if (NULL == (void *)0) {
		chunks = calloc(size, sizeof(*chunks));
		if (chunks == NULL)
			err(1, "calloc");
	} else {
		chunks = malloc(size * sizeof(*chunks));
		if (chunks == NULL)
			err(1, "malloc");

		for (size_t i = 0; i < size; ++i)
			chunks[i].state = 0;
	}
	chunk_move(chunks, size, chunklist->chunks, chunklist->size,
			chunklist->count);
	free(chunklist->chunks);
	chunklist->chunks = chunks;
	chunklist->size = size;
}

static void chunklist_contract(struct ublc_chunklist *chunklist) {
	size_t size = CHUNKLIST_ALLOC_COUNT;
	if (chunklist->size != 0)
		size = chunklist->size / 2;

	struct ublc_chunklist_node *chunks;
	if (NULL == (void *)0) {
		chunks = calloc(size, sizeof(*chunks));
		if (chunks == NULL) {
			warn("calloc");
			return;
		}
	} else {
		chunks = malloc(size * sizeof(*chunks));
		if (chunks == NULL) {
			warn("malloc");
			return;
		}

		for (size_t i = 0; i < size; ++i)
			chunks[i].state = 0;
	}
	chunk_move(chunks, size, chunklist->chunks, chunklist->size,
			chunklist->count);
	free(chunklist->chunks);
	chunklist->chunks = chunks;
	chunklist->size = size;
}


/* http://szudzik.com/ElegantPairing.pdf */
static size_t pairing_szudzik(long long a, long long b) {
	size_t c = a >= 0 ? 2 * a : -2 * a - 1;
	size_t d = b >= 0 ? 2 * b : -2 * b -1;

	return (c + d) * (c + d + 1) / 2 + c;
}
