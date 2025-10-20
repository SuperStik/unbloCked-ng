#ifndef GUI_BUTTON_H
#define GUI_BUTTON_H 1

#include <stdint.h>

#include <math/vector.h>

struct gui_button_info {
	gvec(float,2) pos;
	uint8_t anchor;
	uint8_t state;
};

struct gui_button {
	struct gui_button_info info;
	char *displaystr;
	float width;
	float height;
	unsigned id;
};

#define GUI_BUTTON_INITDEFAULT(button, id, xpos, ypos, displaystr) gui_button_init(button, id, xpos, ypos, 200.0f, 20.0f, displaystr)

struct gui_button *gui_button_init(struct gui_button *, unsigned id, float xpos,
		float ypos, float width, float height, const char *displaystr);

void gui_button_destroy(struct gui_button *);

int gui_button_mousepressed(struct gui_button *, float x, float y);

#endif /* GUI_BUTTON_H */
