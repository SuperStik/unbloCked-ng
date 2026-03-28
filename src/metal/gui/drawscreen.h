#ifndef GUI_DRAWSCREEN
#define GUI_DRAWSCREEN 1

#include <objc/objc.h>

#include <gui/screen.h>
#include <metal/gui/drawmainmenu.h>
#include <metal/textures.h>
#include <metal/shaders.h>

struct gui_drawscreen {
	enum gui_screen_type type;
	union {
		struct gui_drawmainmenu mainmenu;
	} screens;
};

struct gui_drawscreen *gui_drawscreen_init(struct gui_drawscreen *, id device,
		struct texture *, struct shaders *);

void gui_drawscreen_release(struct gui_drawscreen *);

void gui_drawscreen_switch(struct gui_drawscreen *, id device, struct texture *,
		struct shaders *);

void gui_drawscreen_draw_opaque(struct gui_drawscreen *, id render_encoder);
void gui_drawscreen_draw_blended(struct gui_drawscreen *, id render_encoder);

#endif /* GUI_DRAWSCREEN */
