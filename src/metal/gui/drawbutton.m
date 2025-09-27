#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "drawbutton.h"

id gui_drawbutton_getverts(id d, float xpos,
		float ypos, float width, float height) {
	id<MTLDevice> device = d;

	float wd2 = width * 0.5f;
	float ustart = 200.0f - wd2;

	const struct gui_buttonverts verts[] = {
		{{xpos, ypos}, {0.0f, 46.0f / 256.0f}},
		{{xpos + wd2, ypos}, {wd2 / 256.0f, 46.0f / 256.0f}},
		{{xpos + wd2, ypos + height}, {wd2 / 256.0f, 66.0f / 256.0f}},
		{{xpos, ypos + height}, {0.0f, 66.0 / 256.0f}},

		{{xpos + wd2, ypos}, {ustart / 256.0f, 46.0f / 256.0f}},
		{{xpos + width, ypos}, {200.0f / 256.0f, 46.0f / 256.0f}},
		{{xpos + width, ypos + height}, {200.0f / 256.0f, 66.0f /
							256.0f}},
		{{xpos + wd2, ypos + height}, {ustart / 256.0f, 66.0f / 256.0f}}
	};

	return [device
		newBufferWithBytes:verts
			    length:sizeof(verts)
			   options:MTLResourceCPUCacheModeWriteCombined];
}

id gui_drawbutton_getinds(id d) {
	id<MTLDevice> device = d;

	const uint16_t indices[] = {
		3, 1, 0,
		2, 1, 3,

		7, 5, 4,
		6, 5, 7
	};

	return [device
		newBufferWithBytes:indices
			    length:sizeof(indices)
			   options:MTLResourceCPUCacheModeWriteCombined];
}

void gui_drawbutton_draw(struct gui_drawbutton *button, id e) {
	id<MTLRenderCommandEncoder> enc = e;
	NSLog(@"%@", enc);
}
