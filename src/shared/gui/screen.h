#ifndef GUI_SCREEN_H
#define GUI_SCREEN_H 1

#include <stddef.h>
#include <stdint.h>

#include <gui/button.h>

struct gui_screen {
	struct gui_button *ctrllist;
	struct gui_button_info *ctrlinfo;
	size_t ctrllistlen;
	float width;
	float height;
};

void gui_screen_onclick(struct gui_screen *, float x, float y);

void gui_screen_onhover(struct gui_screen *, float x, float y);

#endif /* GUI_SCREEN_H */
