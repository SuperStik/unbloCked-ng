#ifndef GUI_SCREEN_H
#define GUI_SCREEN_H 1

#include <pthread.h>
#include <stddef.h>
#include <stdint.h>

#include <gui/hostworld.h>
#include <gui/mainmenu.h>

enum gui_screen_type {
	GUI_SCREEN_MAINMENU,
	GUI_SCREEN_HOSTWORLD,
	GUI_SCREEN_MAX
};

struct gui_screen {
	pthread_mutex_t mutex;
	enum gui_screen_type type;
	union {
		struct gui_mainmenu mainmenu;
		struct gui_hostworld hostworld;
	} screens;
	float width;
	float height;
};

extern struct gui_screen screen;

struct gui_screen *gui_screen_init(struct gui_screen *, float width, float
		height, enum gui_screen_type);

void gui_screen_destroy(struct gui_screen *);

void gui_screen_switch(struct gui_screen *, enum gui_screen_type);

void gui_screen_resize(struct gui_screen *, float width, float height);

void gui_screen_onclick(struct gui_screen *, float x, float y);

void gui_screen_onhover(struct gui_screen *, float x, float y);

int gui_screen_lock(struct gui_screen *);
int gui_screen_unlock(struct gui_screen *);

#endif /* GUI_SCREEN_H */
