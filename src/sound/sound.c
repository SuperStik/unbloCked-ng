#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#define MA_NO_ENCODING
#include <miniaudio.c>
#include <SDL3/SDL_filesystem.h>

#include "sound.h"

ma_engine engine;

struct sound_ui sound_ui;

void sound_restart(ma_sound *sound) {
	ma_sound_seek_to_pcm_frame(sound, 0);

	ma_sound_start(sound);
}

ma_result sound_init_from_file_relative(ma_engine *engine, const char *path,
		ma_uint32 flags, ma_sound_group *group, ma_fence *fence,
		ma_sound *sound) {
	const char *base = SDL_GetBasePath();
	size_t baselen = strlen(base);
	size_t size = baselen + strlen(path) + 1;

	char *file = malloc(size);
	if (file == NULL)
		return MA_OUT_OF_MEMORY;

	strncpy(file, base, baselen);
	/* I'm feeling brave */
	strcat(file, path);

	ma_result res = ma_sound_init_from_file(engine, file, flags, group,
			fence, sound);

	free(file);
	return res;
}

ma_result sound_ui_init(ma_engine *engine, struct sound_ui *ui) {
	sound_init_from_file_relative(engine, "resources/sound/ui/click.opus",
			MA_SOUND_FLAG_NO_SPATIALIZATION, NULL, NULL,
			&(ui->click));

	return MA_SUCCESS;
}

void sound_ui_uninit(struct sound_ui *sound) {
	ma_sound_uninit(&(sound->click));
}
