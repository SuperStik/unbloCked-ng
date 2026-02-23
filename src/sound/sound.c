#include <stddef.h>

#include "sound.h"

ma_engine engine;

void sound_restart(ma_sound *sound) {
	ma_sound_seek_to_pcm_frame(sound, 0);

	ma_sound_start(sound);
}
