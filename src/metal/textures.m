#include <err.h>
#include <stdlib.h>
#include <string.h>

#import <Metal/Metal.h>

#include "../image/png.h"
#include "objc_macros.h"
#include "textures.h"

static void expandalpha(unsigned char **data, int *channels, size_t width,
		size_t height);

static MTLPixelFormat getswizzle(int channels, MTLTextureSwizzleChannels *);

static id<MTLTexture> tex2d(const char *path, id<MTLDevice>,
		id<MTLBlitCommandEncoder>);

struct textures *tex_generate(struct textures *tex, id device, id cmdq) {
	ARP_PUSH();

	id<MTLCommandBuffer> cmdb = [cmdq commandBuffer];
	id<MTLBlitCommandEncoder> enc = [cmdb blitCommandEncoder];

	tex->gui = tex2d("textures/gui/gui.png", device, enc);
	tex->background = tex2d("textures/gui/background.png", device, enc);

	[enc endEncoding];

	[cmdb commit];
	[cmdb waitUntilCompleted];

	ARP_POP();

	return tex;
}

void tex_release(struct textures *tex) {
	[tex->background release];
	[tex->gui release];
}

static void expandalpha(unsigned char **data, int *channels, size_t width,
		size_t height) {
	if (*channels != 3)
		return;

	size_t pixels = width * height;
	size_t size = pixels * 3ul;
	size_t newsize = (size * 4) / 3;

	unsigned char *newdata = realloc(*data, newsize);
	if (newdata == NULL)
		err(1, "realloc");

	size_t ind = 0;
	for (size_t i = 1; i < pixels; ++i) {
		size -= 3;
		memmove(&newdata[ind + 4], &newdata[ind + 3], size);
		newdata[ind + 3] = 0xff;
		ind += 4;
	}
	newdata[ind + 3] = 0xff;

	*data = newdata;
	*channels = 4;
}

static MTLPixelFormat getswizzle(int channels, MTLTextureSwizzleChannels
		*swizzle) {
	switch (channels) {
		case 1:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleOne);
			return MTLPixelFormatR8Unorm;
		case 2:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleGreen);
			return MTLPixelFormatRG8Unorm;
		default:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleGreen,
					MTLTextureSwizzleBlue,
					MTLTextureSwizzleAlpha);
			return MTLPixelFormatRGBA8Unorm;
	}
}

static id<MTLTexture> tex2d(const char *path, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> enc) {
	size_t width, height;
	int channels;
	unsigned char *data;
	MTLPixelFormat fmt;
	MTLTextureSwizzleChannels swizzle;

	data = img_readpngpath(path, &width, &height, &channels);
	expandalpha(&data, &channels, width, height);
	fmt = getswizzle(channels, &swizzle);

	MTLTextureDescriptor *desc = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat:fmt
					     width:width
					    height:height
					 mipmapped:false];
	desc.cpuCacheMode = MTLCPUCacheModeWriteCombined;
	if (channels < 4)
		desc.swizzle = swizzle;

	id<MTLTexture> tex = [device newTextureWithDescriptor:desc];

	MTLRegion replace = MTLRegionMake2D(0, 0, width, height);
	[tex replaceRegion:replace
	       mipmapLevel:0
		 withBytes:data
	       bytesPerRow:(width * channels)];

	[enc optimizeContentsForGPUAccess:tex];

	return tex;
}
