#ifndef UBLC_SOUND
#define UBLC_SOUND 1

#define MA_NO_ENCODING
#define MA_NO_WAV
#define MA_NO_FLAC
#include <miniaudio.h>

extern ma_engine engine;

struct sound {
	struct {
		ma_sound bow[2];
		ma_sound explode;
		ma_sound fizz;
		ma_sound fuse;
		ma_sound pop;
		ma_sound splash;
	} misc;

	struct {
		struct {
			ma_sound ambient[3];
			ma_sound death;
		} pig;

		struct {
			ma_sound hurt[3];
		} player;

		struct {
			ma_sound attack[2];
		} slime;

		struct {
			ma_sound bark[3];
			ma_sound death;
			ma_sound hurt[3];
		} wolf;
	} mob;

	struct {
		struct {
			ma_sound close;
			ma_sound open;
		} door;

		struct {
			ma_sound ambient[2];
			ma_sound ignite;
		} fire;

		struct {
			ma_sound shatter[3];
		} glass;

		struct {
			ma_sound step[4];
		} grass;

		struct {
			ma_sound basedrum;
		} note;
	} tile;

	struct {
		ma_sound click;
	} ui;
};

extern struct sound sound;

ma_result sound_init_from_file_relative(ma_engine *, const char *path, ma_uint32
		flags, ma_sound_group *, ma_fence *, ma_sound *);

ma_result sound_load(ma_engine *);
void sound_unload(void);

#endif /* UBLC_SOUND */
