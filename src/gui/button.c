#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "anchor.h"
#include "button.h"

struct gui_button *gui_button_init(struct gui_button *button, struct
		gui_button_info *info, unsigned id, float xpos, float ypos,
		float width, float height, const char *displaystr) {
	info->pos = (gvec(float,2)){xpos, ypos};
	info->anchor = ANC_MIDDLE;
	info->state = 1;
	button->info = info;
	button->width = width;
	button->height = height;
	button->id = id;

	if (displaystr[0] != '\0') {
#ifdef UBLC_NO_STRDUP
		size_t len = strlen(displaystr) + 1;
		char *str = (char *)malloc(len);

		memcpy(str, displaystr, len);
#else
		char *str = strdup(displaystr);
#endif /* UBLC_NO_STRDUP */

		if (str == NULL)
			return NULL;

		button->displaystr = str;
	} else
		button->displaystr = NULL;

	return button;
}

struct gui_button *gui_button_resize(struct gui_button *button, float x, float
		y, float width, float height) {
	return button;
}

void gui_button_destroy(struct gui_button *button) {
	free(button->displaystr);
}

int gui_button_mousepressed(struct gui_button *button, float x, float y) {
	if (button->info->state) {
		warnx("button: %p (%g, %g)", button, x, y);

		float xpos = button->info->pos[0];
		float ypos = button->info->pos[1];

		return x >= xpos && y >= ypos && x < (xpos + button->width) &&
			y < (ypos + button->height);
	}

	return 0;
}

