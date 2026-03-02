#ifndef TEXTURES_H
#define TEXTURES_H 1

#include <objc/objc.h>

struct texture {
	struct {
		id font;
	} font;

	struct {
		id background;
		id container;
		id crafting;
		id furnace;
		id gui;
		id icons;
		id inventory;
		id items;
		id particles;
		id slot;
		id trap;
		id unknown_pack;
	} gui;
};

struct texture *tex_load(struct texture *, id commandqueue);
void tex_unload(struct texture *);

#endif /* TEXTURES_H */
