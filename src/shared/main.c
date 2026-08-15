#include <err.h>
#include <stdio.h>

#include <SDL3/SDL_init.h>
#include <SDL3/SDL_platform.h>

#include "cursor.h"
#include "gui/screen.h"
#include "main.h"
#include "scaledreso.h"
#include "sound/sound.h"

#include <extras/decoders/libvorbis/miniaudio_libvorbis.c>
#include <extras/decoders/libopus/miniaudio_libopus.c>

char done = 0;

char occluded;
pthread_mutex_t occlusionlock = PTHREAD_MUTEX_INITIALIZER;

static void getresourcemanager(ma_resource_manager *);

#ifdef SDL_PLATFORM_APPLE
/* allow game mode to be used, thank apple for this shit */
char EMBED_INFO_PLIST[] __attribute__((used, section("__TEXT,__info_plist,regular,no_dead_strip"))) = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
"<plist version=\"1.0\">"
	"<dict>"
		"<key>LSApplicationCategoryType</key>"
		"<string>public.app-category.games</string>"
		"<key>LSSupportsGameMode</key>"
		"<true/>"
		"<key>NSHighResolutionCapable</key>"
		"<true/>"
	"</dict>"
"</plist>";
#endif /* SDL_PLATFORM_APPLE */

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

	warnx("Loading sounds...");
	sound_load(&engine);

	warnx("Done!");
	gl_main();

	sound_unload();

	ma_engine_uninit(&engine);
	ma_resource_manager_uninit(&resource_manager);

	cursor_free();

	SDL_Quit();
	return 0;
}

void ev_loop(void) {
	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;

				break;
			case SDL_EVENT_WINDOW_EXPOSED:
				if (occluded) {
					occluded = 0;
					pthread_mutex_unlock(&occlusionlock);
				}

				break;
			case SDL_EVENT_WINDOW_RESIZED:
				;
				float w = (float)ev.window.data1;
				float h = (float)ev.window.data2;
				scaledreso(&w, &h);

				gui_screen_resize(&screen, w, h);

				break;
			case SDL_EVENT_WINDOW_OCCLUDED:
				if (!occluded) {
					occluded = 1;
					pthread_mutex_lock(&occlusionlock);
				}

				break;
			case SDL_EVENT_MOUSE_MOTION:
				;
				float cur_x = ev.motion.x;
				float cur_y = ev.motion.y;
				scaledreso(&cur_x, &cur_y);

				gui_screen_onhover(&screen, cur_x, cur_y);

				break;
			case SDL_EVENT_MOUSE_BUTTON_DOWN:
				if (ev.button.button == 1) {
					float cur_x = ev.button.x;
					float cur_y = ev.button.y;
					scaledreso(&cur_x, &cur_y);

					gui_screen_onclick(&screen, cur_x,
							cur_y);
				}

				break;
		}
	}

	if (occluded)
		pthread_mutex_unlock(&occlusionlock);
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
