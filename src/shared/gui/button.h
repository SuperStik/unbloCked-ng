#ifndef GUI_BUTTON_H
#define GUI_BUTTON_H 1

#include <stdint.h>

#include <math/vector.h>

typedef void (*gui_button_onclick)(float, float);

struct gui_button_info {
	gvec(float,2) pos;
	uint8_t anchor;
	uint8_t state;
};

struct gui_button {
	struct gui_button_info *info;
	gui_button_onclick onclick;
	char *displaystr;
	float width;
	float height;
};

#define GUI_BUTTON_STATE_DISABLED 0
#define GUI_BUTTON_STATE_ENABLED 1
#define GUI_BUTTON_STATE_HOVERED 2

struct gui_button *gui_button_init(struct gui_button *, struct
		gui_button_info *, gui_button_onclick, float xpos, float ypos,
		float width, float height, const char *displaystr);

struct gui_button *gui_button_resize(struct gui_button *, float x, float y,
		float width, float height);

void gui_button_destroy(struct gui_button *);

int gui_button_inarea(struct gui_button *, gvec(float,2) position, gvec(float,2)
		area);

#endif /* GUI_BUTTON_H */
