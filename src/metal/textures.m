#include <err.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <Accelerate/Accelerate.h>
#import <Metal/Metal.h>

#include "../image/png.h"
#include "textures.h"

static size_t expandalpha(unsigned char **data, size_t width, size_t height,
		size_t bytesperrow, int bit_depth);

static MTLPixelFormat getswizzle(int channels, int bit_depth,
		MTLTextureSwizzleChannels *);

static id<MTLTexture> tex2d(const char *path, id<MTLDevice>);

static id<MTLTexture> tex2d_array(const char *path, unsigned short tilex,
		unsigned short tiley, id<MTLDevice>, id<MTLBlitCommandEncoder>);

static inline void tex_load_achievement(struct texture *tex, id<MTLDevice>
		device, id<MTLBlitCommandEncoder> blit) {
	tex->achievement.bg = tex2d("textures/achievement/bg.png", device);
	tex->achievement.icons = tex2d_array("textures/achievement/icons.png",
			16, 16, device, blit);

	[blit optimizeContentsForGPUAccess:tex->achievement.bg];

	[blit generateMipmapsForTexture:tex->achievement.bg];
	[blit generateMipmapsForTexture:tex->achievement.icons];
}

static inline void tex_load_armor(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {
	tex->armor.cloth = tex2d_array("textures/armor/cloth.png", 1, 2, device,
			blit);
	tex->armor.chain = tex2d_array("textures/armor/chain.png", 1, 2, device,
			blit);
	tex->armor.iron = tex2d_array("textures/armor/iron.png", 1, 2, device,
			blit);
	tex->armor.gold = tex2d_array("textures/armor/gold.png", 1, 2, device,
			blit);
	tex->armor.diamond = tex2d_array("textures/armor/diamond.png", 1, 2,
			device, blit);
	tex->armor.power = tex2d("textures/armor/power.png", device);

	[blit optimizeContentsForGPUAccess:tex->armor.power];

	[blit generateMipmapsForTexture:tex->armor.cloth];
	[blit generateMipmapsForTexture:tex->armor.chain];
	[blit generateMipmapsForTexture:tex->armor.iron];
	[blit generateMipmapsForTexture:tex->armor.gold];
	[blit generateMipmapsForTexture:tex->armor.diamond];
	[blit generateMipmapsForTexture:tex->armor.power];
}

static inline void tex_load_font(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {

	tex->font.font = tex2d_array("textures/font/font.png", 16, 16, device,
			blit);

	[blit generateMipmapsForTexture:tex->font.font];
}

static inline void tex_load_gui(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {
	tex->gui.background = tex2d("textures/gui/background.png", device);
	tex->gui.container = tex2d("textures/gui/container.png", device);
	tex->gui.crafting = tex2d("textures/gui/crafting.png", device);
	tex->gui.furnace = tex2d("textures/gui/furnace.png", device);
	tex->gui.gui = tex2d("textures/gui/gui.png", device);
	tex->gui.icons = tex2d("textures/gui/icons.png", device);
	tex->gui.inventory = tex2d("textures/gui/inventory.png", device);
	tex->gui.items = tex2d_array("textures/gui/items.png", 16, 16, device,
			blit);
	tex->gui.particles = tex2d_array("textures/gui/particles.png", 8, 1,
			device, blit);
	tex->gui.slot = tex2d("textures/gui/slot.png", device);
	tex->gui.trap = tex2d("textures/gui/trap.png", device);
	tex->gui.unknown_pack = tex2d("textures/gui/unknown_pack.png", device);

	[blit optimizeContentsForGPUAccess:tex->gui.background];
	[blit optimizeContentsForGPUAccess:tex->gui.container];
	[blit optimizeContentsForGPUAccess:tex->gui.crafting];
	[blit optimizeContentsForGPUAccess:tex->gui.furnace];
	[blit optimizeContentsForGPUAccess:tex->gui.gui];
	[blit optimizeContentsForGPUAccess:tex->gui.icons];
	[blit optimizeContentsForGPUAccess:tex->gui.inventory];
	[blit optimizeContentsForGPUAccess:tex->gui.slot];
	[blit optimizeContentsForGPUAccess:tex->gui.trap];
	[blit optimizeContentsForGPUAccess:tex->gui.unknown_pack];

	[blit generateMipmapsForTexture:tex->gui.background];
	[blit generateMipmapsForTexture:tex->gui.container];
	[blit generateMipmapsForTexture:tex->gui.crafting];
	[blit generateMipmapsForTexture:tex->gui.furnace];
	[blit generateMipmapsForTexture:tex->gui.gui];
	[blit generateMipmapsForTexture:tex->gui.icons];
	[blit generateMipmapsForTexture:tex->gui.inventory];
	[blit generateMipmapsForTexture:tex->gui.items];
	[blit generateMipmapsForTexture:tex->gui.particles];
	[blit generateMipmapsForTexture:tex->gui.slot];
	[blit generateMipmapsForTexture:tex->gui.trap];
	[blit generateMipmapsForTexture:tex->gui.unknown_pack];
}

/* TODO: make parallel */
struct texture *tex_load(struct texture *tex, id c) {
	id<MTLCommandQueue> cmdq = c;
	id<MTLDevice> device = cmdq.device;

	@autoreleasepool {
		id<MTLCommandBuffer> cmdb = [cmdq commandBuffer];
		id<MTLBlitCommandEncoder> blit = [cmdb blitCommandEncoder];

		tex_load_font(tex, device, blit);
		tex_load_gui(tex, device, blit);

		[blit endEncoding];
		[cmdb commit];
		[cmdb waitUntilCompleted];
	}

	return tex;
}

void tex_unload(struct texture *tex) {
	id<MTLTexture> *texarray = (id<MTLTexture> *)tex;
	const size_t count = sizeof(struct texture) / sizeof(id<MTLTexture>);
	for (size_t i = 0; i < count; ++i)
		[texarray[i] release];
}

static size_t expandalpha(unsigned char **data, size_t width, size_t height,
		size_t bytesperrow, int bit_depth) {
	vImage_Buffer src, dst;
	src.data = *data;
	src.height = height;
	src.width = width;
	src.rowBytes = bytesperrow;

	vImageBuffer_Init(&dst, height, width, 32 * (bit_depth / 8),
			kvImageNoFlags);

	if (bit_depth == 16)
		vImageConvert_RGB16UtoRGBA16U(&src, nil, 0xFFFF, &dst, false,
				kvImageNoFlags);
	else
		vImageConvert_RGB888toBGRA8888(&src, nil, 0xFF, &dst, false,
				kvImageNoFlags);

	free(*data);
	*data = dst.data;

	return dst.rowBytes;
}

static MTLPixelFormat getswizzle(int channels, int bit_depth,
		MTLTextureSwizzleChannels *swizzle) {
	switch (channels) {
		case 1:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleOne);
			return bit_depth == 16 ? MTLPixelFormatR8Unorm :
				MTLPixelFormatR8Unorm;
		case 2:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleRed,
					MTLTextureSwizzleGreen);
			return bit_depth == 16 ? MTLPixelFormatRG16Unorm :
				MTLPixelFormatRG8Unorm;
		case 3:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleGreen,
					MTLTextureSwizzleBlue,
					MTLTextureSwizzleAlpha);
			return bit_depth == 16 ? MTLPixelFormatRGBA16Unorm :
				MTLPixelFormatBGRA8Unorm;
		default:
			*swizzle = MTLTextureSwizzleChannelsMake(
					MTLTextureSwizzleRed,
					MTLTextureSwizzleGreen,
					MTLTextureSwizzleBlue,
					MTLTextureSwizzleAlpha);
			return bit_depth == 16 ? MTLPixelFormatRGBA16Unorm :
				MTLPixelFormatRGBA8Unorm;
	}
}

static id<MTLTexture> tex2d(const char *path, id<MTLDevice> device) {
	id<MTLTexture> tex;

	uint32_t width, height;
	int channels, bit_depth;
	size_t bytesperrow;
	unsigned char *data;
	MTLPixelFormat fmt;
	MTLTextureSwizzleChannels swizzle;

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
	data = img_readpng(file, &width, &height, &channels, &bit_depth,
			&bytesperrow);
	fmt = getswizzle(channels, bit_depth, &swizzle);

	if (channels == 3) {
		bytesperrow = expandalpha(&data, width, height, bytesperrow,
				bit_depth);
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

	return tex;
}

static id<MTLTexture> tex2d_array(const char *path, unsigned short tx, unsigned
		short ty, id<MTLDevice> device, id<MTLBlitCommandEncoder> enc) {
	NSUInteger arraylen = tx * ty;
	if (arraylen > 2048)
		return nil;

	id<MTLTexture> basetex = tex2d(path, device);
	uint32_t width = basetex.width / tx;
	uint32_t height = basetex.height / ty;

	MTLTextureDescriptor *desc = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat:basetex.pixelFormat
					     width:width
					    height:height
					 mipmapped:true];
	desc.textureType = MTLTextureType2DArray;
	desc.arrayLength = arraylen;
	desc.storageMode = MTLStorageModePrivate;

	desc.swizzle = basetex.swizzle;

	id<MTLTexture> tex = [device newTextureWithDescriptor:desc];
	tex.label = [NSString stringWithFormat:@"%s", path];

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

	return tex;
}
