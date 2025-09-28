#ifndef METAL_SHADERSTORAGE_H
#define METAL_SHADERSTORAGE_H 1

#include <objc/objc.h>

struct shdrstore {
	id button;
	id background;
};

struct shdrstore *shdr_generate(struct shdrstore *, id device);

void shdr_release(struct shdrstore *);

#endif /* METAL_SHADERSTORAGE_H */
