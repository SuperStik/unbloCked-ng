#ifndef TEXTURES_H
#define TEXTURES_H 1

#include <objc/objc.h>

struct texture {
	struct {
		id bg;
		id icons;
	} achievement;

	struct {
		id cloth;
		id chain;
		id iron;
		id gold;
		id diamond;
		id power;
	} armor;

	struct {
		id kz;
	} art;

	struct {
		id clouds;
		id rain;
		id snow;
	} environment;

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

	struct {
		id arrows;
		id boat;
		id cart;
		id door;
		id sign;
	} item;

	struct {
		id dial;
		id foliagecolor;
		id footprint;
		id grasscolor;
		id mapbg;
		id mapicons;
		id particles;
		id pumpkinblur;
		id shadow;
		id vignette;
		id water;
		id watercolor;
	} misc;

	struct {
		id chicken;
		id cow;
		id creeper;
		id ghast;
		id human;
		id pig;
		id pigman;
		id pigzombie;
		id saddle;
		id sheep_fur;
		id sheep;
		id silverfish;
		id skeleton;
		id slime;
		id spider_eyes;
		id spider;
		id squid;
		id wolf;
		id zombie;
	} mob;

	struct {
		id celestial;
		id terrain;
	} terrain;
};

struct texture *tex_load(struct texture *, id commandqueue);
void tex_unload(struct texture *);

#endif /* TEXTURES_H */
