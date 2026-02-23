#include <err.h>
#include <stdio.h>

#include <SDL3/SDL_init.h>

#include "gui/screen.h"
#include "metal/main.h"
#include "sound/sound.h"

struct gui_screen *currentscreen;

int main(void) {
	warnx("Hello unbloCked!");
	
	warnx("Initializing SDL...");
	if (!SDL_Init(SDL_INIT_VIDEO))
		errx(1, "%s", SDL_GetError());

	warnx("Initializing miniaudio...");
	ma_result result = ma_engine_init(NULL, &engine);
	if (result != MA_SUCCESS)
		errx(1, "ma_engine_init: %s", ma_result_description(result));

	sound_ui_init(&engine, &sound_ui);

	warnx("Done!");
	MTL_main();

	sound_ui_uninit(&sound_ui);

	ma_engine_uninit(&engine);

	SDL_Quit();
	return 0;
}
