#include <err.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_video.h>

#include "main.h"

#define WIDTH 640
#define HEIGHT 480

static char done = 0;

void MTL_main(void) {
	SDL_Window *window = SDL_CreateWindow("unbloCked", WIDTH, HEIGHT,
			SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY |
			SDL_WINDOW_METAL);
	if (window == NULL)
		errx(1, "%s", SDL_GetError());

	if (!SDL_SetWindowMinimumSize(window, WIDTH, HEIGHT))
		warnx("%s", SDL_GetError());

	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;
				break;
		}
	}

	SDL_DestroyWindow(window);
}
