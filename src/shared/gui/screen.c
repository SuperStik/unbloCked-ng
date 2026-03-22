#include "screen.h"

struct gui_screen *gui_screen_init(struct gui_screen *screen, float w, float h,
		enum gui_screen_type type) {
	screen->type = type;
	screen->width = w;
	screen->height = h;

	switch(type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_init(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_MAX:
			break;
	}

	return screen;
}

void gui_screen_destroy(struct gui_screen *screen) {
	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_destroy(&screen->screens.mainmenu);
			break;
		case GUI_SCREEN_MAX:
			break;
	}
}

void gui_screen_resize(struct gui_screen *screen, float w, float h) {
	screen->width = w;
	screen->height = h;
}

void gui_screen_onclick(struct gui_screen *screen) {
	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_mainmenu_onclick(&screen->screens.mainmenu);
			break;
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
		case GUI_SCREEN_MAX:
			break;
	}
}
