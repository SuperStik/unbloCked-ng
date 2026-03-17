#import <Metal/Metal.h>

#include "drawbutton.h"
#include "drawmainmenu.h"
#include "drawtext.h"
#include <gui/button.h>
#include <gui/screen.h>

void gui_drawmainmenu_init(struct gui_drawmainmenu *menu, struct gui_screen *
		screen, id d) {
	menu->screen = screen;

	id<MTLDevice> device = d;
	menu->buttonverts = gui_drawbutton_getverts(device, 200.0f, 16.0f);
	menu->buttoninds = gui_drawbutton_getinds(device);

	for (int i = 0; i < 5; ++i)
		menu->textvertcounts[i] = gui_drawtext_maketextbuf(device,
				&menu->textbufs[i], &menu->textinds[i],
				screen->ctrllist[i].displaystr);

	[menu->pipeline.button retain];
	[menu->pipeline.text retain];

	[menu->texture.font retain];
	[menu->texture.gui retain];
}

void gui_drawmainmenu_draw_opaque(const struct gui_drawmainmenu *menu, id r) {
	id<MTLRenderCommandEncoder> enc = r;

	[enc setRenderPipelineState:menu->pipeline.button];

	[enc setFragmentTexture:menu->texture.gui atIndex:0];

	gui_drawbutton_draw(menu->buttonverts, menu->buttoninds, enc,
			menu->screen->ctrlinfo, menu->screen->ctrllistlen);
}

void gui_drawmainmenu_draw_blended(const struct gui_drawmainmenu *menu, id r) {
	id<MTLRenderCommandEncoder> enc = r;

	[enc setRenderPipelineState:menu->pipeline.text];

	[enc setFragmentTexture:menu->texture.font atIndex:0];

	for (int i = 0; i < 5; ++i)
	gui_drawtext_draw(enc, menu->textbufs[i], menu->textinds[i],
			menu->textvertcounts[i]);
}

void gui_drawmainmenu_release(const struct gui_drawmainmenu *menu) {
	[menu->buttonverts release];
	[menu->buttoninds release];

	for (int i = 0; i < 5; ++i) {
		[menu->textbufs[i] release];
		[menu->textinds[i] release];
	}

	[menu->pipeline.button release];
	[menu->pipeline.text release];

	[menu->texture.font release];
	[menu->texture.gui release];
}
