#ifndef GUI_SCREEN_H
#define GUI_SCREEN_H 1

#include <stddef.h>
#include <stdint.h>

struct gui_screen {
	void *cntllist;
	size_t cntllistlen;
	uint32_t width;
	uint32_t height;
};

#endif /* GUI_SCREEN_H */
