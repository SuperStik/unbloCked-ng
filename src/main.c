#include <err.h>
#include <stdio.h>

#include <SDL3/SDL_init.h>

#include "gui/screen.h"
#include "metal/main.h"
#include "sound/sound.h"

#include <extras/decoders/libvorbis/miniaudio_libvorbis.c>
#include <extras/decoders/libopus/miniaudio_libopus.c>

struct gui_screen *currentscreen;

static void getresourcemanager(ma_resource_manager *);

int main(void) {
	warnx("Hello unbloCked!");
	
	warnx("Initializing SDL...");
	if (!SDL_Init(SDL_INIT_VIDEO))
		errx(1, "%s", SDL_GetError());

	warnx("Initializing miniaudio...");
	ma_resource_manager resource_manager;
	getresourcemanager(&resource_manager);

	ma_engine_config config = ma_engine_config_init();
	config.pResourceManager = &resource_manager;

	ma_result result = ma_engine_init(&config, &engine);
	if (result != MA_SUCCESS)
		errx(1, "ma_engine_init: %s", ma_result_description(result));

	sound_ui_init(&engine, &sound_ui);

	warnx("Done!");
	MTL_main();

	sound_ui_uninit(&sound_ui);

	ma_engine_uninit(&engine);
	ma_resource_manager_uninit(&resource_manager);

	SDL_Quit();
	return 0;
}

static void getresourcemanager(ma_resource_manager *manager) {
	ma_resource_manager_config config;
	config = ma_resource_manager_config_init();
	ma_decoding_backend_vtable* xiph_backends[] = {
		ma_decoding_backend_libvorbis,
		ma_decoding_backend_libopus
	};

	config.ppCustomDecodingBackendVTables = xiph_backends;
	config.customDecodingBackendCount = sizeof(xiph_backends) /
		sizeof(xiph_backends[0]);
	config.pCustomDecodingBackendUserData = NULL;

	ma_result result = ma_resource_manager_init(&config, manager);
	if (result != MA_SUCCESS)
		errx(1, "ma_resource_manager_init: %s", ma_result_description(
					result));
}
