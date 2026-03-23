#include "screen.h"

struct gui_screen *gui_screen_init(struct gui_screen *screen, float w, float h,
		enum gui_screen_type type) {
	screen->type = type;
	screen->width = w;
	screen->height = h;

	pthread_mutex_init(&screen->mutex, NULL);
	gui_screen_lock(screen);

	switch(type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_init(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_MAX:
			break;
	}

	gui_screen_unlock(screen);

	return screen;
}

void gui_screen_destroy(struct gui_screen *screen) {
	gui_screen_lock(screen);

	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_destroy(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_MAX:
			break;
	}

	gui_screen_unlock(screen);
	pthread_mutex_destroy(&screen->mutex);
}

void gui_screen_resize(struct gui_screen *screen, float w, float h) {
	gui_screen_lock(screen);

	screen->width = w;
	screen->height = h;

	gui_screen_unlock(screen);
}

void gui_screen_onclick(struct gui_screen *screen) {
	gui_screen_lock(screen);

	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_onclick(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_MAX:
			break;
	}

	gui_screen_unlock(screen);
}

void gui_screen_onhover(struct gui_screen *screen, float x, float y) {
	gvec(float,2) pos = {x, y};
	gvec(float,2) area = {screen->width, screen->height};

	gui_screen_lock(screen);

	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_onhover(&screen->screens.mainmenu, pos,
					area);
			break;
		case GUI_SCREEN_MAX:
			break;
	}

	gui_screen_unlock(screen);
}

int gui_screen_lock(struct gui_screen *screen) {
	return pthread_mutex_lock(&screen->mutex);
}

int gui_screen_unlock(struct gui_screen *screen) {
	return pthread_mutex_unlock(&screen->mutex);
}
