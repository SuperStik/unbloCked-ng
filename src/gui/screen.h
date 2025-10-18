#ifndef GUI_SCREEN_H
#define GUI_SCREEN_H 1

#include <stdint.h>
#include <sys/types.h>

#include <gui/button.h>

struct gui_screen {
	struct gui_button *ctrllist;
	size_t ctrllistlen;
	float width;
	float height;
};

ssize_t gui_screen_onclick(struct gui_screen *, float x, float y);
#endif /* GUI_SCREEN_H */
