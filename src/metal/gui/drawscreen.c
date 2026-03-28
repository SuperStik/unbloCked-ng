#include "../shaders.h"
#include "../textures.h"
#include "drawscreen.h"

extern struct gui_screen screen;

static void drawsubscreen_init(struct gui_drawscreen *, id device, struct
		texture *, struct shaders *, enum gui_screen_type);

struct gui_drawscreen *gui_drawscreen_init(struct gui_drawscreen *drawscreen, id
		device, struct texture *tex, struct shaders *shdr) {
	enum gui_screen_type type = screen.type;
	drawscreen->type = type;
	drawsubscreen_init(drawscreen, device, tex, shdr, type);

	return drawscreen;
}

void gui_drawscreen_release(struct gui_drawscreen *drawscreen) {
	switch(drawscreen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_drawmainmenu_release(&drawscreen->screens.mainmenu);
			break;
		case GUI_SCREEN_MAX:
			break;
	}
}

void gui_drawscreen_switch(struct gui_drawscreen *drawscreen, id device,
		struct texture *tex, struct shaders *shdr) {
	enum gui_screen_type type = screen.type;
	if (__builtin_expect(type == drawscreen->type, 1))
		return;

	gui_drawscreen_release(drawscreen);

	drawscreen->type = type;
	drawsubscreen_init(drawscreen, device, tex, shdr, type);
}

void gui_drawscreen_draw_opaque(struct gui_drawscreen *screen, id
		render_encoder) {
	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_drawmainmenu_draw_opaque(&screen->screens.mainmenu,
					render_encoder);
			break;
		case GUI_SCREEN_MAX:
			break;
	}
}

void gui_drawscreen_draw_blended(struct gui_drawscreen *screen, id
		render_encoder) {
	switch(screen->type) {
		case GUI_SCREEN_MAINMENU:
			gui_drawmainmenu_draw_blended(&screen->screens.mainmenu,
					render_encoder);
			break;
		case GUI_SCREEN_MAX:
			break;
	}
}

static void drawsubscreen_init(struct gui_drawscreen *drawscreen, id device,
		struct texture *tex, struct shaders *shdr, enum
		gui_screen_type type) {
	switch(type) {
		case GUI_SCREEN_MAINMENU:
			drawscreen->screens.mainmenu.pipeline.button =
				shdr->button;
			drawscreen->screens.mainmenu.pipeline.text = shdr->text;
			drawscreen->screens.mainmenu.texture.font =
				tex->font.font;
			drawscreen->screens.mainmenu.texture.gui = tex->gui.gui;

			gui_drawmainmenu_init(&drawscreen->screens.mainmenu,
					&screen.screens.mainmenu, device);
			break;
		case GUI_SCREEN_MAX:
			break;
	}
}
