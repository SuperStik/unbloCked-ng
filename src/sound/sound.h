#ifndef UBLC_SOUND
#define UBLC_SOUND 1

#define MA_NO_ENCODING
#include <miniaudio.h>

extern ma_engine engine;

extern struct sound_ui sound_ui;

struct sound_ui {
	ma_sound click;
};

void sound_restart(ma_sound *);

ma_result sound_init_from_file_relative(ma_engine *, const char *path, ma_uint32
		flags, ma_sound_group *, ma_fence *, ma_sound *);

ma_result sound_ui_init(ma_engine *, struct sound_ui *);
void sound_ui_uninit(struct sound_ui *);

#endif /* UBLC_SOUND */
