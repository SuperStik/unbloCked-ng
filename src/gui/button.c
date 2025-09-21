#include <stdlib.h>
#include <string.h>

#include "button.h"

struct gui_button *gui_button_init(struct gui_button *button, unsigned id, float
		xpos, float ypos, float width, float height, const
		char *displaystr) {
	button->width = width;
	button->height = height;
	button->xpos = xpos;
	button->ypos = ypos;
	button->id = id;

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

	return button;
}

void gui_button_destroy(struct gui_button *button) {
	free(button->displaystr);
}

int gui_button_mousepressed(struct gui_button *button, float x, float y) {
	if (button->enabled) {
		float xpos = button->xpos;
		float ypos = button->ypos;

		return x >= xpos && y >= ypos && x < (xpos + button->width) &&
			y < (ypos + button->height);
	}

	return 0;
}

