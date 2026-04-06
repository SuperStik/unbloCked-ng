#include <err.h>
#include <stdlib.h>

#include "chunklist.h"

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
			chunks = calloc(start_size, sizeof(struct ublc_chunk));
			if (chunks == NULL)
				err(1, "calloc");
		} else {
			chunks = malloc(sizeof(struct ublc_chunk) * start_size);
			if (chunks == NULL)
				err(1, "malloc");

			for (size_t i = 0; i < start_size; ++i)
				((struct ublc_chunk *)chunks)[i].world = NULL;
		}

		chunklist->chunks = chunks;
	}

	chunklist->count = 0;

	return chunklist;
}

void ublc_chunklist_delete(const struct ublc_chunklist *chunklist) {
	free(chunklist->chunks);
}
