#include <SDL3/SDL_init.h>

#include "cursor.h"

static SDL_Cursor *cursor;

int cursor_set(SDL_SystemCursor id) {
	cursor_free();

	cursor = SDL_CreateSystemCursor(id);
	if (cursor == NULL)
		return 0;

	return (int)SDL_SetCursor(cursor);
}

void cursor_free(void) {
	if (cursor != NULL) {
		SDL_DestroyCursor(cursor);
		cursor = NULL;
	}
}
