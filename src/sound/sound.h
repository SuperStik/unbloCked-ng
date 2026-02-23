#ifndef UBLC_SOUND
#define UBLC_SOUND 1

#define MA_NO_ENCODING
#define MA_NO_FLAC
#define MA_NO_MP3
#define MA_NO_WAV
#include <sound/miniaudio.h>

extern ma_engine engine;

void sound_restart(ma_sound *);

#endif /* UBLC_SOUND */
