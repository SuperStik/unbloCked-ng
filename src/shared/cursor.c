#include <err.h>
#include <stdlib.h>

#include <SDL3/SDL_init.h>

#include "cursor.h"

static SDL_Cursor *cursor;

static void curs_set(void *id);
static void curs_free(void *curs);

int cursor_set(SDL_SystemCursor id) {
	static SDL_SystemCursor current_id = SDL_SYSTEM_CURSOR_DEFAULT;
	if (__builtin_expect(current_id == id, 1))
		return 1;
	current_id = id;

	SDL_SystemCursor *data = malloc(sizeof(id));
	if (data == NULL)
		err(1, "malloc");

	*data = id;
	return SDL_RunOnMainThread(curs_set, data, false);
}

int cursor_free(void) {
	return SDL_RunOnMainThread(curs_free, cursor, false);
}

static void curs_set(void *data) {
	curs_free(cursor);

	SDL_SystemCursor *id = data;
	cursor = SDL_CreateSystemCursor(*id);
	SDL_SetCursor(cursor);

	free(data);
}

static void curs_free(void *curs) {
	if (curs != NULL) {
		SDL_DestroyCursor(curs);
		cursor = NULL;
	}
}
