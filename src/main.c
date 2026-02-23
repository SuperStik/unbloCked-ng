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
	SDL_Init(SDL_INIT_VIDEO);

	warnx("Initializing miniaudio...");
	ma_engine_init(NULL, &engine);

	warnx("Done!");
	MTL_main();

	ma_engine_uninit(&engine);

	SDL_Quit();
	return 0;
}
