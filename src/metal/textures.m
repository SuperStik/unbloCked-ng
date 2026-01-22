#include <err.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#include <Accelerate/Accelerate.h>
#include <dispatch/dispatch.h>
#import <Metal/Metal.h>

#include "../image/png.h"
#include "textures.h"

static size_t expandalpha(unsigned char **data, size_t width, size_t height);

static MTLPixelFormat getswizzle(int channels, MTLTextureSwizzleChannels *);

static id<MTLTexture> tex2d(const char *path, id<MTLDevice>);

static id<MTLTexture> tex2d_array(const char *path, unsigned short tilex,
		unsigned short tiley, id<MTLDevice>, id<MTLBlitCommandEncoder>);

struct textures *tex_generate(struct textures *tex, id device, id cmdq) {
	@autoreleasepool {
		dispatch_queue_t queue = dispatch_get_global_queue(
				DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		dispatch_group_t group = dispatch_group_create();

		dispatch_group_async(group, queue, ^(void) {
				tex->background = tex2d(
						"textures/gui/background.png",
						device);
				});

		dispatch_group_async(group, queue, ^(void) {
				tex->gui = tex2d("textures/gui/gui.png",
						device);
				});

		id<MTLCommandBuffer> cmdb = [cmdq commandBuffer];

		id<MTLBlitCommandEncoder> enc = [cmdb blitCommandEncoder];
		tex->text = tex2d_array("textures/font/default.png", 16, 16,
				device, enc);

		dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		dispatch_release(group);

		[enc optimizeContentsForGPUAccess:tex->background];
		[enc generateMipmapsForTexture:tex->background];

		[enc optimizeContentsForGPUAccess:tex->background];
		[enc generateMipmapsForTexture:tex->background];

		[enc endEncoding];

		[cmdb commit];
	}

	return tex;
}

void tex_release(struct textures *tex) {
	[tex->background release];
	[tex->gui release];
	[tex->text release];
}

static size_t expandalpha(unsigned char **data, size_t width, size_t height) {
	vImage_Buffer src, dst;
	src.data = *data;
	src.height = height;
	src.width = width;
	src.rowBytes = width * 3ul;

	vImageBuffer_Init(&dst, height, width, 32, kvImageNoFlags);

	vImageConvert_RGB888toBGRA8888(&src, nil, 0xFF, &dst, false,
			kvImageNoFlags);

	free(*data);
	*data = dst.data;

	return dst.rowBytes;
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
		case 3:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleGreen,
					MTLTextureSwizzleBlue,
					MTLTextureSwizzleAlpha);
			return MTLPixelFormatBGRA8Unorm;
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
	id<MTLTexture> tex;
	uint32_t width, height;
	int channels;
	unsigned char *data;
	MTLPixelFormat fmt;
	MTLTextureSwizzleChannels swizzle;

	@autoreleasepool {
		NSURL *base = NSBundle.mainBundle.resourceURL;
		NSURL *resources = [NSURL
			fileURLWithFileSystemRepresentation:"resources"
						isDirectory:true
					      relativeToURL:base];
		NSURL *pathurl = [NSURL
			fileURLWithFileSystemRepresentation:path
						isDirectory:false
					      relativeToURL:resources];
		FILE *file = fopen(pathurl.fileSystemRepresentation, "rb");
		data = img_readpng(file, &width, &height, &channels);
		fmt = getswizzle(channels, &swizzle);
		NSUInteger bytesperrow = (NSUInteger)width * channels;

		if (channels == 3) {
			bytesperrow = expandalpha(&data, width, height);
			channels = 4;
		}

		MTLTextureDescriptor *desc = [MTLTextureDescriptor
			texture2DDescriptorWithPixelFormat:fmt
						     width:width
						    height:height
						 mipmapped:true];
		desc.cpuCacheMode = MTLCPUCacheModeWriteCombined;

		if (channels < 4)
			desc.swizzle = swizzle;

		tex = [device newTextureWithDescriptor:desc];
		tex.label = [NSString stringWithFormat:@"%s", path];

		MTLRegion replace = MTLRegionMake2D(0, 0, width, height);
		[tex replaceRegion:replace
		       mipmapLevel:0
			 withBytes:data
		       bytesPerRow:bytesperrow];

		free(data);
	}

	return tex;
}

static id<MTLTexture> tex2d_array(const char *path, unsigned short tx, unsigned
		short ty, id<MTLDevice> device, id<MTLBlitCommandEncoder> enc) {
	NSUInteger arraylen = tx * ty;
	if (arraylen > 2048)
		return nil;

	id<MTLTexture> tex;
	uint32_t totalw, totalh;
	int channels;
	unsigned char *data;
	MTLPixelFormat fmt;
	MTLTextureSwizzleChannels swizzle;

	@autoreleasepool {
		NSURL *base = NSBundle.mainBundle.resourceURL;
		NSURL *resources = [NSURL
			fileURLWithFileSystemRepresentation:"resources"
						isDirectory:true
					      relativeToURL:base];
		NSURL *pathurl = [NSURL
			fileURLWithFileSystemRepresentation:path
						isDirectory:false
					      relativeToURL:resources];
		FILE *file = fopen(pathurl.fileSystemRepresentation, "rb");
		data = img_readpng(file, &totalw, &totalh, &channels);
		if (totalw % tx || totalh % ty) {
			free(data);
			return nil;
		}

		uint32_t width = totalw / tx;
		uint32_t height = totalh / ty;

		fmt = getswizzle(channels, &swizzle);
		NSUInteger bytesperrow = (NSUInteger)totalw * channels;

		if (channels == 3) {
			bytesperrow = expandalpha(&data, width, height);
			channels = 4;
		}

		MTLTextureDescriptor *basedesc = [MTLTextureDescriptor
			texture2DDescriptorWithPixelFormat:fmt
						     width:totalw
						    height:totalh
						 mipmapped:false];
		basedesc.cpuCacheMode = MTLCPUCacheModeWriteCombined;
		id<MTLTexture> basetex = [device
			newTextureWithDescriptor:basedesc];

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

		tex = [device newTextureWithDescriptor:desc];
		tex.label = [NSString stringWithFormat:@"%s", path];

		MTLRegion baseregion = MTLRegionMake2D(0, 0, totalw, totalh);
		[basetex replaceRegion:baseregion
			   mipmapLevel:0
			     withBytes:data
			   bytesPerRow:bytesperrow];

		free(data);

		[enc optimizeContentsForGPUAccess:basetex];

		MTLSize texsize = MTLSizeMake(width, height, 1);
		MTLOrigin dstorigin = MTLOriginMake(0, 0, 0);
		for (NSUInteger i = 0; i < arraylen; ++i) {
			MTLOrigin srcorigin = MTLOriginMake((i % tx) * width,
					(i / ty) * height, 0);
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
	}

	[enc generateMipmapsForTexture:tex];

	return tex;
}
