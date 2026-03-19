#ifndef UBLC_CURSOR
#define UBLC_CURSOR 1

#include <SDL3/SDL_mouse.h>

int cursor_set(SDL_SystemCursor);

int cursor_free(void);

#endif /* UBLC_CURSOR */
