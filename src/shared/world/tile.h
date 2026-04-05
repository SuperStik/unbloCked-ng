#ifndef WORLD_TILE_H
#define WORLD_TILE_H 1

struct ublc_tile {
	char *name;
	float resistance;
	float hardness;
	int material;
	unsigned char side_tex[6];
};

extern struct ublc_tile tiles[256];

#endif /* WORLD_TILE_H */
