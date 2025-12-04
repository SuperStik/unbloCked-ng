#ifndef TEXTURES_H
#define TEXTURES_H 1

#include <objc/objc.h>

struct textures {
	id background;
	id gui;
	id text;
};

struct textures *tex_generate(struct textures *, id device, id commandqueue);

void tex_release(struct textures *);

#endif /* TEXTURES_H */
