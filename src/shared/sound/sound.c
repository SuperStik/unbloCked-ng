#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#define MA_NO_ENCODING
#define MA_NO_WAV
#define MA_NO_FLAC
#include <miniaudio.c>
#include <SDL3/SDL_filesystem.h>

#include "sound.h"

ma_engine engine;

struct sound sound;

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

static void sound_load_misc(ma_engine *engine, ma_fence *fence) {
	sound_init_from_file_relative(engine, "resources/sound/misc/bow1.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.misc.bow[0]);
	sound_init_from_file_relative(engine, "resources/sound/misc/bow2.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.misc.bow[1]);
	sound_init_from_file_relative(engine, "resources/sound/misc/fizz.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.misc.fizz);
	sound_init_from_file_relative(engine, "resources/sound/misc/fuse.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.misc.fuse);
	sound_init_from_file_relative(engine, "resources/sound/misc/pop.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.misc.pop);
	sound_init_from_file_relative(engine, "resources/sound/misc/splash.mp3",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.misc.splash);
}

static void sound_load_mob(ma_engine *engine, ma_fence *fence) {
	/* pig */
	sound_init_from_file_relative(engine,
			"resources/sound/mob/pig/ambient1.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.pig.ambient[0]);
	sound_init_from_file_relative(engine,
			"resources/sound/mob/pig/ambient2.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.pig.ambient[1]);
	sound_init_from_file_relative(engine,
			"resources/sound/mob/pig/ambient3.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.pig.ambient[2]);
	sound_init_from_file_relative(engine,
			"resources/sound/mob/pig/death.ogg",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.pig.death);

	/* player */
	sound_init_from_file_relative(engine,
			"resources/sound/mob/player/hurt1.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.player.hurt[0]);
	sound_init_from_file_relative(engine,
			"resources/sound/mob/player/hurt2.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.player.hurt[1]);
	sound_init_from_file_relative(engine,
			"resources/sound/mob/player/hurt3.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.player.hurt[2]);

	/* slime */
	sound_init_from_file_relative(engine,
			"resources/sound/mob/slime/attack1.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.slime.attack[0]);
	sound_init_from_file_relative(engine,
			"resources/sound/mob/slime/attack2.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE, NULL, fence,
			&sound.mob.slime.attack[1]);
}

static void sound_load_ui(ma_engine *engine, ma_fence *fence) {
	sound_init_from_file_relative(engine, "resources/sound/ui/click.opus",
			MA_SOUND_FLAG_ASYNC | MA_SOUND_FLAG_DECODE |
			MA_SOUND_FLAG_NO_SPATIALIZATION |
			MA_SOUND_FLAG_NO_PITCH, NULL, fence, &sound.ui.click);
}

ma_result sound_load(ma_engine *engine) {
	ma_fence fence;
	ma_result result = ma_fence_init(&fence);
	if (result != MA_SUCCESS)
		return result;

	sound_load_misc(engine, &fence);
	sound_load_mob(engine, &fence);
	sound_load_ui(engine, &fence);

	ma_fence_wait(&fence);
	ma_fence_uninit(&fence);

	return MA_SUCCESS;
}

static void sound_unload_misc(void) {
	for (int i = 0; i < 2; ++i)
		ma_sound_uninit(&sound.misc.bow[i]);
	ma_sound_uninit(&sound.misc.explode);
	ma_sound_uninit(&sound.misc.fizz);
	ma_sound_uninit(&sound.misc.fuse);
	ma_sound_uninit(&sound.misc.pop);
	ma_sound_uninit(&sound.misc.splash);
}

static void sound_unload_mob(void) {
	/* pig */
	for (int i = 0; i < 3; ++i)
		ma_sound_uninit(&sound.mob.pig.ambient[i]);
	ma_sound_uninit(&sound.mob.pig.death);

	/* player */
	for (int i = 0; i < 3; ++i)
		ma_sound_uninit(&sound.mob.player.hurt[i]);

	/* slime */
	for (int i = 0; i < 2; ++i)
		ma_sound_uninit(&sound.mob.slime.attack[i]);
}

static void sound_unload_ui(void) {
	ma_sound_uninit(&sound.ui.click);
}

void sound_unload(void) {
	sound_unload_misc();
	sound_unload_mob();
	sound_unload_ui();
}
