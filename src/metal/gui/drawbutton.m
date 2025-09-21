#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "drawbutton.h"

void gui_drawbutton_initbufs(struct objc_object *d, struct objc_object **v,
		struct objc_object **i, float xpos, float ypos, float width,
		float height) {
	id<MTLDevice> device = (__bridge id<MTLDevice>)d;
	id<MTLBuffer> *vertbuf = (__bridge id<MTLBuffer> *)v;
	id<MTLBuffer> *indbuf = (__bridge id<MTLBuffer> *)i;

	float wd2 = width * 0.5f;
	float ustart = 200.0f - wd2;

	struct gui_buttonverts verts[] = {
		{{xpos, ypos}, {0.0f, 46.0f / 256.0f}},
		{{xpos + wd2, ypos}, {wd2 / 256.0f, 46.0f / 256.0f}},
		{{xpos + wd2, ypos + height}, {wd2 / 256.0f, 66.0f / 256.0f}},
		{{xpos, ypos + height}, {0.0f, 66.0 / 256.0f}},

		{{xpos + wd2, ypos}, {ustart, 46.0f / 256.0f}},
		{{xpos + width, ypos}, {200.0f / 256.0f, 46.0f / 256.0f}},
		{{xpos + width, ypos + height}, {200.0f / 256.0f, 66.0f /
							256.0f}},
		{{xpos + wd2, ypos + height}, {ustart, 66.0f / 256.0f}}
	};

	uint16_t indices[] = {
		3, 1, 0,
		2, 1, 3,

		7, 5, 4,
		6, 5, 7
	};

	*vertbuf = [device
		newBufferWithBytes:verts
			    length:sizeof(verts)
			   options:MTLResourceCPUCacheModeWriteCombined];
	*indbuf = [device
		newBufferWithBytes:indices
			    length:sizeof(indices)
			   options:MTLResourceCPUCacheModeWriteCombined];
}

void gui_drawbutton_draw(struct gui_drawbutton *button, struct objc_object *e) {
	id<MTLRenderCommandEncoder> enc = (__bridge id<MTLRenderCommandEncoder>)
			e;
	NSLog(@"%@", enc);
}
