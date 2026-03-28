#include "screen.h"

static void subscreen_init(struct gui_screen *, enum gui_screen_type type);
static void subscreen_destroy(struct gui_screen *);

struct gui_screen screen;

struct gui_screen *gui_screen_init(struct gui_screen *screen, float w, float h,
		enum gui_screen_type type) {
	screen->type = type;
	screen->width = w;
	screen->height = h;

	pthread_mutex_init(&screen->mutex, NULL);
	gui_screen_lock(screen);

	subscreen_init(screen, type);

	gui_screen_unlock(screen);

	return screen;
}

void gui_screen_destroy(struct gui_screen *screen) {
	gui_screen_lock(screen);

	subscreen_destroy(screen);

	gui_screen_unlock(screen);
	pthread_mutex_destroy(&screen->mutex);
}

void gui_screen_switch(struct gui_screen *screen, enum gui_screen_type type) {
	gui_screen_lock(screen);

	subscreen_destroy(screen);
	screen->type = type;
	subscreen_init(screen, type);

	gui_screen_unlock(screen);
}

void gui_screen_resize(struct gui_screen *screen, float w, float h) {
	gui_screen_lock(screen);

	screen->width = w;
	screen->height = h;

	gui_screen_unlock(screen);
}

void gui_screen_onclick(struct gui_screen *screen) {
	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_onclick(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_HOSTWORLD:
		case GUI_SCREEN_MAX:
			break;
	}
}

void gui_screen_onhover(struct gui_screen *screen, float x, float y) {
	gvec(float,2) pos = {x, y};
	gvec(float,2) area = {screen->width, screen->height};

	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_onhover(&screen->screens.mainmenu, pos,
					area);
			break;
		case GUI_SCREEN_HOSTWORLD:
		case GUI_SCREEN_MAX:
			break;
	}
}

int gui_screen_lock(struct gui_screen *screen) {
	return pthread_mutex_lock(&screen->mutex);
}

int gui_screen_unlock(struct gui_screen *screen) {
	return pthread_mutex_unlock(&screen->mutex);
}

static void subscreen_init(struct gui_screen *screen, enum gui_screen_type
		type) {
	switch(type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_init(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_HOSTWORLD:
		case GUI_SCREEN_MAX:
			break;
	}
}

static void subscreen_destroy(struct gui_screen *screen) {
	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_destroy(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_HOSTWORLD:
		case GUI_SCREEN_MAX:
			break;
	}
}
