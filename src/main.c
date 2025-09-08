#include <err.h>
#include <stdio.h>

#include <SDL3/SDL_init.h>

#include "metal/main.h"

int main(void) {
	warnx("Hello unbloCked!");
	SDL_Init(SDL_INIT_VIDEO);

	MTL_main();

	SDL_Quit();
	return 0;
}
