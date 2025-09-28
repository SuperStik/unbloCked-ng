#ifndef METAL_SHADERSTORAGE_H
#define METAL_SHADERSTORAGE_H 1

#include <objc/objc.h>

struct shaders {
	id button;
	id background;
};

struct shaders *shdr_generate(struct shaders *, id device);

void shdr_release(struct shaders *);

#endif /* METAL_SHADERSTORAGE_H */
