#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "drawbutton.h"
#include <gui/anchor.h>

#define BUFFER_OPTIONS (MTLResourceCPUCacheModeWriteCombined|\
		MTLResourceHazardTrackingModeUntracked)

static inline void setvertbuf(id<MTLBuffer>, id<MTLRenderCommandEncoder>);

id gui_drawbutton_getverts(id d, float width, float height) {
	id<MTLDevice> device = d;

	float wd2 = width / 2.0f;
	float hd2 = height / 2.0f;
	float ustart = 200.0f - wd2;

	const struct gui_buttonverts verts[] = {
		{{-wd2, -hd2}, {0.0f, 66.0f / 128.0f}},
		{{0.0f, -hd2}, {wd2 / 256.0f, 66.0f / 128.0f}},
		{{0.0f, hd2}, {wd2 / 256.0f, 46.0f / 128.0f}},
		{{-wd2, hd2}, {0.0f, 46.0 / 128.0f}},

		{{0.0f, -hd2}, {ustart / 256.0f, 66.0f / 128.0f}},
		{{wd2, -hd2}, {200.0f / 256.0f, 66.0f / 128.0f}},
		{{wd2, hd2}, {200.0f / 256.0f, 46.0f / 128.0f}},
		{{0.0f, hd2}, {ustart / 256.0f, 46.0f / 128.0f}}
	};

	return [device newBufferWithBytes:verts
				   length:sizeof(verts)
				  options:BUFFER_OPTIONS];
}

id gui_drawbutton_getinds(id d) {
	id<MTLDevice> device = d;

	const uint16_t indices[] = {
		3, 1, 0,
		2, 1, 3,

		7, 5, 4,
		6, 5, 7
	};

	return [device newBufferWithBytes:indices
				   length:sizeof(indices)
				  options:BUFFER_OPTIONS];
}

void gui_drawbutton_prepare(id e, const struct gui_button_info *buttons,
		unsigned long count) {
	id<MTLRenderCommandEncoder> enc = e;

	[enc setVertexBytes:buttons length:sizeof(*buttons) * count atIndex:4];
}

void gui_drawbutton_draw(id e, id vertbuf, id indbuf) {
	id<MTLRenderCommandEncoder> enc = e;

	setvertbuf(vertbuf, enc);

	[enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle
			indexCount:12
			 indexType:MTLIndexTypeUInt16
		       indexBuffer:indbuf
		 indexBufferOffset:0];
}

void gui_drawbutton_draw_inst(id e, id vertbuf, id indbuf, unsigned long
		count) {
	id<MTLRenderCommandEncoder> enc = e;

	setvertbuf(vertbuf, enc);

	[enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle
			indexCount:12
			 indexType:MTLIndexTypeUInt16
		       indexBuffer:indbuf
		 indexBufferOffset:0
		     instanceCount:count];
}

void gui_drawbutton_draw_instbase(id e, id vertbuf, id indbuf, unsigned long
		count, unsigned long base) {
	id<MTLRenderCommandEncoder> enc = e;

	setvertbuf(vertbuf, enc);

	[enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle
			indexCount:12
			 indexType:MTLIndexTypeUInt16
		       indexBuffer:indbuf
		 indexBufferOffset:0
		     instanceCount:count
			baseVertex:0
		      baseInstance:base];
}

static inline void setvertbuf(id<MTLBuffer> vertbuf, id<MTLRenderCommandEncoder>
		enc) {
	[enc setVertexBuffer:vertbuf offset:0 atIndex:16];
}
