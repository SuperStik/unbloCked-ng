#include <SDL3/SDL_init.h>

#include "cursor.h"

static SDL_Cursor *cursor;

int cursor_set(SDL_SystemCursor id) {
	static SDL_SystemCursor current_id = SDL_SYSTEM_CURSOR_DEFAULT;
	if (__builtin_expect(current_id == id, 1))
		return 1;
	current_id = id;

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
