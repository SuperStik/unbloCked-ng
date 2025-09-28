#ifndef TEXTURES_H
#define TEXTURES_H 1

#include <objc/objc.h>

struct textures {
	id background;
	id gui;
};

struct textures *tex_generate(struct textures *, id device);

void tex_release(struct textures *);

#endif /* TEXTURES_H */
