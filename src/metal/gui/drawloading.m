#import <Metal/Metal.h>

#include "drawloading.h"
#include "drawtext.h"
#include <math/matrix.h>

void gui_drawloading_init(struct gui_drawloading *loading, id d) {
	id<MTLDevice> device = d;

	float length;
	loading->textvertcount = gui_drawtext_maketextbuf(device,
			&loading->textbuf, &loading->textind, &length,
			"Loading...");

	mtx_gettranslate(loading->texttransform, length / -2.0f, 0.0f, 0.0f);

	[loading->pipeline_text retain];
	[loading->texture_font retain];
}

void gui_drawloading_release(const struct gui_drawloading *loading) {
	[loading->pipeline_text release];
	[loading->texture_font release];

	[loading->textbuf release];
	[loading->textind release];
}

void gui_drawloading_draw_blended(const struct gui_drawloading *loading, id r) {
	id<MTLRenderCommandEncoder> enc = r;

	[enc setRenderPipelineState:loading->pipeline_text];
	
	[enc setFragmentTexture:loading->texture_font atIndex:0];

	gui_drawtext_draw(enc, loading->textbuf, loading->textind,
			loading->texttransform, (gvec(_Float16,4)){1.0f16,
			1.0f16, 1.0f16, 1.0f16}, loading->textvertcount);
}
