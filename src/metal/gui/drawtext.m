#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#import <Metal/Metal.h>

#include "drawtext.h"

#define BUFFER_OPTIONS (MTLResourceCPUCacheModeWriteCombined | \
		MTLResourceHazardTrackingModeUntracked)

struct transcolor {
	gvec(float,4) trans[4];
	gvec(_Float16,4) color;
};

static unsigned filltextarray(struct gui_textvert *array, uint16_t *indices,
		float *textlength, const unsigned char *str, size_t len);

static inline unsigned char getcolor(unsigned char color);

const static _Float16 fontwidth[256] = {
	0.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	0.5f16, 0.25f16, 0.625f16, 0.75f16,
	0.75f16, 0.875f16, 0.875f16, 0.375f16,
	0.625f16, 0.625f16, 1.0f16, 0.75f16,
	0.25f16, 0.75f16, 0.25f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.25f16, 0.25f16,
	0.625f16, 0.75f16, 0.625f16, 0.75f16,
	0.875f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.5f16,
	0.75f16, 0.5f16, 0.75f16, 0.75f16,
	0.375f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.625f16, 0.75f16,
	0.75f16, 0.25f16, 0.75f16, 0.625f16,
	0.375f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.75f16,
	0.5f16, 0.75f16, 0.75f16, 0.75f16,
	0.75f16, 0.75f16, 0.75f16, 0.625f16,
	0.25f16, 0.625f16, 0.875f16, 0.75f16,
	0.875f16, 1.0f16, 0.875f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 0.875f16,
	1.0f16, 0.875f16, 0.875f16, 0.85f16,
	1.0f16, 0.75f16, 1.0f16, 1.0f16,
	0.875f16, 1.0f16, 1.0f16, 0.875f16,
	0.875f16, 0.875f16, 1.0f16, 1.0f16,
	0.875f16, 1.0f16, 0.875f16, 1.0f16,
	1.0f16, 0.875f16, 1.0f16, 1.0f16,
	1.0f16, 0.75f16, 0.875f16, 1.0f16,
	0.875f16, 0.875f16, 1.0f16, 0.875f16,
	0.875f16, 0.875f16, 0.875f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 1.0f16, 1.0f16, 1.0f16,
	1.0f16, 0.875f16, 0.875f16, 1.0f16,
	0.875f16, 1.0f16, 1.0f16, 1.0f16,
	0.875f16, 1.0f16, 1.0f16, 0.875f16,
	1.0f16, 1.0f16, 0.75f16, 0.875f16,
	0.875f16, 0.875f16, 0.875f16, 0.875f16,
	1.0f16, 1.0f16, 0.875f16, 1.0f16,
	0.875f16, 1.0f16, 1.0f16, 1.0f16,
	0.875f16, 0.75f16, 1.0f16, 0.0f16
};

unsigned long gui_drawtext_maketextbuf(id d, id *buf, id *ind, float *length,
		const char *str) {
	const size_t len = strlen(str);

	if (__builtin_expect((len * 6) > UINT16_MAX, 0)) {
		buf = nil;
		ind = nil;
		return 0ul;
	}

	id<MTLDevice> device = d;
	id<MTLBuffer> *indexbuf = ind;
	id<MTLBuffer> *vertbuf = buf;

	const size_t vertsize = sizeof(struct gui_textvert) * 4 * len;
	const size_t indsize = sizeof(uint16_t) * 6 * len;

	/* cursed LMAO */
	const size_t totalsize = vertsize + indsize;
	struct gui_textvert *array = malloc(totalsize);
	uint16_t *indices = (void *)array + vertsize;

	unsigned count = filltextarray(array, indices, length, (const unsigned
				char *)str, len);

	*vertbuf = [device
		newBufferWithBytes:array
			    length:sizeof(struct gui_textvert) * 4 * count
			   options:BUFFER_OPTIONS];
	(*vertbuf).label = @"buffer.text.vertices";

	unsigned long vertcount = count * 6ul;
	*indexbuf = [device newBufferWithBytes:indices
					length:sizeof(uint16_t) * vertcount
				       options:BUFFER_OPTIONS];
	(*indexbuf).label = @"buffer.text.indices";

	free(array);

	return vertcount;
};

void gui_drawtext_draw(id e, id b, id i, const gvec(float,4) transform[4],
		gvec(_Float16,4) color, unsigned count) {
	id<MTLRenderCommandEncoder> enc = e;
	id<MTLBuffer> buffer = b;
	id<MTLBuffer> indices = i;
	struct transcolor transcolor;
	memcpy(&transcolor.trans, transform, sizeof(transcolor.trans));
	transcolor.color = color;

	[enc setVertexBytes:&transcolor
		     length:sizeof(transcolor)
		    atIndex:1];
	[enc setVertexBuffer:buffer offset:0 atIndex:16];

	[enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle
			indexCount:count
			 indexType:MTLIndexTypeUInt16
		       indexBuffer:indices
		 indexBufferOffset:0
		     instanceCount:2];
}

static unsigned filltextarray(struct gui_textvert *array, uint16_t *indices,
		float *textlength, const unsigned char *str, size_t len) {
	uint16_t indcount = 0;
	unsigned count = 0;

	float xpos = 0.0f;
	unsigned char color = 17;
	for (size_t i = 0; i < len; ++i) {
		size_t bufind = count * 4;
		unsigned char character = str[i];
		_Float16 width = fontwidth[character];

		if (character == 0xFF) {
			color = getcolor((unsigned char)str[i+1]);
			++i;
			continue;
		}

		if (character == ' ' || character == 0) {
			xpos += (width * 8.0f);
			continue;
		}

		array[bufind].pos = (gvec(float,2)){xpos, 8.0f};
		array[bufind].uv = (gvec(_Float16,2)){0.0f16, 0.0f16};
		array[bufind].character = character;
		array[bufind].color = color;

		array[bufind+1].pos = (gvec(float,2)){xpos, 0.0f};
		array[bufind+1].uv = (gvec(_Float16,2)){0.0f16, 1.0f16};
		array[bufind+1].character = character;
		array[bufind+1].color = color;

		xpos += (width * 8.0f);

		array[bufind+2].pos = (gvec(float,2)){xpos, 8.0f};
		array[bufind+2].uv = (gvec(_Float16,2)){width, 0.0f16};
		array[bufind+2].character = character;
		array[bufind+2].color = color;

		array[bufind+3].pos = (gvec(float,2)){xpos, 0.0f};
		array[bufind+3].uv = (gvec(_Float16,2)){width, 1.0f16};
		array[bufind+3].character = character;
		array[bufind+3].color = color;

		indices[indcount] = bufind + 2;
		indices[indcount+1] = bufind + 1;
		indices[indcount+2] = bufind;
		indices[indcount+3] = bufind + 2;
		indices[indcount+4] = bufind + 3;
		indices[indcount+5] = bufind + 1;
		indcount += 6;

		++count;
	}

	if (textlength != NULL)
		*textlength = xpos;

	return count;
}

static inline unsigned char getcolor(unsigned char character) {
	unsigned char color;
	switch (character) {
		case '0' ... '9':
			color = character - '0';
			break;
		case 'A' ... 'F':
			color = character - '7';
			break;
		case 'a' ... 'f':
			color = character - 'W';
			break;
		default:
			color = 17;
	}

	return color;
}
