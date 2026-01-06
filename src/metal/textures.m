#include <err.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#include <dispatch/dispatch.h>
#import <Metal/Metal.h>

#include "../image/png.h"
#include "objc_macros.h"
#include "textures.h"

static void expandalpha(unsigned char **data, int *channels, size_t width,
		size_t height);

static MTLPixelFormat getswizzle(int channels, MTLTextureSwizzleChannels *);

static id<MTLTexture> tex2d(const char *path, id<MTLDevice>);

static id<MTLTexture> tex2d_array(const char *path, unsigned short tilex,
		unsigned short tiley, id<MTLDevice>, id<MTLBlitCommandEncoder>);

struct textures *tex_generate(struct textures *tex, id device, id cmdq) {
	ARP_PUSH();

	dispatch_queue_t queue = dispatch_get_global_queue(
			DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_group_t group = dispatch_group_create();

	dispatch_group_async(group, queue, ^(void) {
		tex->background = tex2d("textures/gui/background.png", device);
	});

	dispatch_group_async(group, queue, ^(void) {
		tex->gui = tex2d("textures/gui/gui.png", device);
	});

	id<MTLCommandBuffer> cmdb = [cmdq commandBuffer];

	id<MTLBlitCommandEncoder> enc = [cmdb blitCommandEncoder];
	tex->text = tex2d_array("textures/font/default.png", 16, 16, device,
			enc);

	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_release(group);

	[enc optimizeContentsForGPUAccess:tex->background];
	[enc generateMipmapsForTexture:tex->background];

	[enc optimizeContentsForGPUAccess:tex->background];
	[enc generateMipmapsForTexture:tex->background];

	[enc endEncoding];

	[cmdb commit];

	ARP_POP();

	return tex;
}

void tex_release(struct textures *tex) {
	[tex->background release];
	[tex->gui release];
	[tex->text release];
}

static void expandalpha(unsigned char **data, int *channels, size_t width,
		size_t height) {
	if (*channels != 3)
		return;

	size_t pixels = width * height;
	size_t size = pixels * 3ul;
	size_t newsize = pixels * 4ul;

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

static id<MTLTexture> tex2d(const char *path, id<MTLDevice> device) {
	uint32_t width, height;
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
					 mipmapped:true];
	desc.cpuCacheMode = MTLCPUCacheModeWriteCombined;

	if (channels < 4)
		desc.swizzle = swizzle;

	id<MTLTexture> tex = [device newTextureWithDescriptor:desc];
	tex.label = [NSString stringWithFormat:@"texture2D [%s]", path];

	MTLRegion replace = MTLRegionMake2D(0, 0, width, height);
	[tex replaceRegion:replace
	       mipmapLevel:0
		 withBytes:data
	       bytesPerRow:(width * channels)];

	free(data);

	return tex;
}

static id<MTLTexture> tex2d_array(const char *path, unsigned short tx, unsigned
		short ty, id<MTLDevice> device, id<MTLBlitCommandEncoder> enc) {
	NSUInteger arraylen = tx * ty;
	if (arraylen > 2048)
		return nil;

	uint32_t totalw, totalh;
	int channels;
	unsigned char *data;
	MTLPixelFormat fmt;
	MTLTextureSwizzleChannels swizzle;

	data = img_readpngpath(path, &totalw, &totalh, &channels);
	if (totalw % tx || totalh % ty) {
		free(data);
		return nil;
	}

	uint32_t width = totalw / tx;
	uint32_t height = totalh / ty;

	expandalpha(&data, &channels, width, height);

	fmt = getswizzle(channels, &swizzle);

	MTLTextureDescriptor *basedesc = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat:fmt
					     width:totalw
					    height:totalh
					 mipmapped:false];
	basedesc.cpuCacheMode = MTLCPUCacheModeWriteCombined;
	id<MTLTexture> basetex = [device newTextureWithDescriptor:basedesc];

	MTLTextureDescriptor *desc = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat:fmt
					     width:width
					    height:height
					 mipmapped:true];
	desc.textureType = MTLTextureType2DArray;
	desc.arrayLength = arraylen;
	desc.storageMode = MTLStorageModePrivate;

	if (channels < 4)
		desc.swizzle = swizzle;

	id<MTLTexture> tex = [device newTextureWithDescriptor:desc];
	tex.label = [NSString stringWithFormat:@"texture2Darray [%s]", path];

	MTLRegion baseregion = MTLRegionMake2D(0, 0, totalw, totalh);
	[basetex replaceRegion:baseregion
		   mipmapLevel:0
		     withBytes:data
		   bytesPerRow:(totalw * channels)];

	free(data);

	[enc optimizeContentsForGPUAccess:basetex];

	MTLSize texsize = MTLSizeMake(width, height, 1);
	MTLOrigin dstorigin = MTLOriginMake(0, 0, 0);
	for (NSUInteger i = 0; i < arraylen; ++i) {
		MTLOrigin srcorigin = MTLOriginMake((i % tx) * width, (i / ty) *
				height, 0);
		[enc copyFromTexture:basetex
			 sourceSlice:0
			 sourceLevel:0
			sourceOrigin:srcorigin
			  sourceSize:texsize
			   toTexture:tex
		    destinationSlice:i
		    destinationLevel:0
		   destinationOrigin:dstorigin];
	}

	[basetex release];

	[enc generateMipmapsForTexture:tex];

	return tex;
}
