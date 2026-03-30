#import <Metal/Metal.h>

#include "drawbutton.h"
#include "drawhostworld.h"
#include "drawtext.h"
#include <math/matrix.h>

void gui_drawhostworld_init(struct gui_drawhostworld *menu, struct gui_hostworld
		*screen, id d) {
	menu->buttoninfo = screen->buttoninfo;

	id<MTLDevice> device = d;
	menu->buttonverts[0] = gui_drawbutton_getverts(device, 70.0f, 20.0f);
	menu->buttonverts[1] = gui_drawbutton_getverts(device, 150.0f, 20.0f);
	menu->buttoninds = gui_drawbutton_getinds(device);

	const char *strings[5];
	for (int i = 0; i < 5; ++i)
		strings[i] = screen->buttons[i].displaystr;

	float lengths[5];
	gui_drawtext_maketextbuf_multi(device, &menu->textbuf, &menu->textind,
			lengths, strings, 5, menu->textvertcounts);

	for (int i = 0; i < 5; ++i) {
		float length = lengths[i] / 2.0f;
		gvec(float,2) pos = screen->buttoninfo[i].pos;
		pos[0] -= length;

		mat_gettranslate(&menu->texttransforms[i * 4], pos[0], pos[1] -
				4.0f, 0.0f);
	}

	[menu->pipeline.button retain];
	[menu->pipeline.text retain];

	[menu->texture.font retain];
	[menu->texture.gui retain];
}

void gui_drawhostworld_release(const struct gui_drawhostworld *menu) {
	for (int i = 0; i < 2; ++i)
		[menu->buttonverts[i] release];
	[menu->buttoninds release];

	[menu->textbuf release];
	[menu->textind release];

	[menu->pipeline.button release];
	[menu->pipeline.text release];

	[menu->texture.font release];
	[menu->texture.gui release];
}

void gui_drawhostworld_draw_opaque(const struct gui_drawhostworld *menu, id r) {
	id<MTLRenderCommandEncoder> enc = r;

	[enc setRenderPipelineState:menu->pipeline.button];

	[enc setFragmentTexture:menu->texture.gui atIndex:0];

	gui_drawbutton_prepare(enc, menu->buttoninfo, 5);

	id buttoninds = menu->buttoninds;
	gui_drawbutton_draw_inst(enc, menu->buttonverts[0], buttoninds, 2);
	gui_drawbutton_draw_instbase(enc, menu->buttonverts[1], buttoninds, 3,
			2);
}

void gui_drawhostworld_draw_blended(const struct gui_drawhostworld *menu, id
		r) {
	id<MTLRenderCommandEncoder> enc = r;

	[enc setRenderPipelineState:menu->pipeline.text];

	[enc setFragmentTexture:menu->texture.font atIndex:0];

	gvec(_Float16,4) colors[5];
	for (int i = 0; i < 5; ++i) {
		switch(menu->buttoninfo[i].state) {
			case GUI_BUTTON_STATE_DISABLED:
				colors[i] = (gvec(_Float16,4)){
					1.0f16 / 3.0f16,
					1.0f16 / 3.0f16,
					1.0f16 / 3.0f16,
					1.0f16
				};
				break;
			case GUI_BUTTON_STATE_HOVERED:
				colors[i] = (gvec(_Float16,4)){
					1.0f16,
					1.0f16,
					1.0f16 / 3.0f16,
					1.0f16
				};
				break;
			default:
				colors[i] = (gvec(_Float16,4)){
					1.0f16,
					1.0f16,
					1.0f16,
					1.0f16
				};
		}
	}

	gui_drawtext_draw_multi(enc, menu->textbuf, menu->textind,
			menu->texttransforms, colors, menu->textvertcounts, 5);
}
