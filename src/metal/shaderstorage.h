#ifndef METAL_SHADERSTORAGE_H
#define METAL_SHADERSTORAGE_H 1

#include <objc/objc.h>

struct shdrstore {
	struct objc_object *buttons;
};

struct shdrstore *shdr_generate(struct shdrstore *, struct objc_object *device);

void shdr_release(struct shdrstore *);

#endif /* METAL_SHADERSTORAGE_H */
