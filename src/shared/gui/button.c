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

int gui_button_inarea(struct gui_button *button, gvec(float,2) pos,
		gvec(float,2) area) {
	if (button->info->state) {
		pos = anc_getoffset(button->info->anchor, area, pos);

		gvec(float,2) button_pos = button->info->pos;
		gvec(float,2) button_size = {button->width, button->height};
		button_size /= 2.0f;

		gvec(float,2) pos_lo = button_pos - button_size;
		gvec(float,2) pos_hi = button_pos + button_size;

		return pos[0] >= pos_lo[0] && pos[1] >= pos_lo[1] && pos[0] <
			pos_hi[0] && pos[1] < pos_hi[1];
	}

	return 0;
}

