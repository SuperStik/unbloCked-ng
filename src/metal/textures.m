#include <err.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <Accelerate/Accelerate.h>
#import <Metal/Metal.h>

#include <image/png.h>
#include "textures.h"

static size_t expandalpha(unsigned char **data, size_t width, size_t height,
		size_t bytesperrow, int bit_depth);

static MTLPixelFormat getswizzle(int channels, int bit_depth,
		MTLTextureSwizzleChannels *);

static id<MTLTexture> tex2d_ex(const char *path, id<MTLDevice>, int flags);

static id<MTLTexture> tex2d_array_ex(const char *path, unsigned short tilex,
		unsigned short tiley, id<MTLDevice>, id<MTLBlitCommandEncoder>,
		int flags);

#define TEX_FLAG_NONE 0
#define TEX_FLAG_NO_MIP 1
#define TEX_FLAG_WRITE 2

#define tex2d(path, device) tex2d_ex(path, device, TEX_FLAG_NONE)
#define tex2d_array(path, tilex, tiley, device, blit) tex2d_array_ex(path,\
		tilex, tiley, device, blit, TEX_FLAG_NONE)
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

static inline void tex_load_art(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {
	tex->art.kz = tex2d("textures/art/kz.png", device);

	[blit optimizeContentsForGPUAccess:tex->art.kz];

	[blit generateMipmapsForTexture:tex->art.kz];
}

static inline void tex_load_environment(struct texture *tex, id<MTLDevice>
		device, id<MTLBlitCommandEncoder> blit) {
	tex->environment.clouds = tex2d("textures/environment/clouds.png",
			device);
	tex->environment.rain = tex2d("textures/environment/rain.png", device);
	tex->environment.snow = tex2d("textures/environment/snow.png", device);

	[blit optimizeContentsForGPUAccess:tex->environment.clouds];
	[blit optimizeContentsForGPUAccess:tex->environment.rain];
	[blit optimizeContentsForGPUAccess:tex->environment.snow];

	[blit generateMipmapsForTexture:tex->environment.clouds];
	[blit generateMipmapsForTexture:tex->environment.rain];
	[blit generateMipmapsForTexture:tex->environment.snow];
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

static inline void tex_load_item(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {
	tex->item.arrows = tex2d_array("textures/item/arrows.png", 1, 2, device,
			blit);
	tex->item.boat = tex2d("textures/item/boat.png", device);
	tex->item.cart = tex2d("textures/item/cart.png", device);
	tex->item.door = tex2d("textures/item/door.png", device);
	tex->item.sign = tex2d("textures/item/sign.png", device);


	[blit optimizeContentsForGPUAccess:tex->item.boat];
	[blit optimizeContentsForGPUAccess:tex->item.cart];
	[blit optimizeContentsForGPUAccess:tex->item.door];
	[blit optimizeContentsForGPUAccess:tex->item.sign];

	[blit generateMipmapsForTexture:tex->item.arrows];
	[blit generateMipmapsForTexture:tex->item.boat];
	[blit generateMipmapsForTexture:tex->item.cart];
	[blit generateMipmapsForTexture:tex->item.door];
	[blit generateMipmapsForTexture:tex->item.sign];
}

static inline void tex_load_misc(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {
	tex->misc.dial = tex2d("textures/misc/dial.png", device);
	tex->misc.foliagecolor = tex2d("textures/misc/foliagecolor.png",
			device);
	tex->misc.footprint = tex2d("textures/misc/footprint.png", device);
	tex->misc.grasscolor = tex2d("textures/misc/grasscolor.png", device);
	tex->misc.mapbg = tex2d("textures/misc/mapbg.png", device);
	tex->misc.mapicons = tex2d_array("textures/misc/mapicons.png", 2, 1,
			device, blit);
	tex->misc.particles = tex2d_array("textures/misc/particles.png", 8, 3,
			device, blit);
	tex->misc.pumpkinblur = tex2d("textures/misc/pumpkinblur.png", device);
	tex->misc.shadow = tex2d("textures/misc/shadow.png", device);
	tex->misc.vignette = tex2d("textures/misc/vignette.png", device);
	tex->misc.water = tex2d("textures/misc/water.png", device);
	tex->misc.watercolor = tex2d("textures/misc/watercolor.png", device);

	[blit optimizeContentsForGPUAccess:tex->misc.dial];
	[blit optimizeContentsForGPUAccess:tex->misc.foliagecolor];
	[blit optimizeContentsForGPUAccess:tex->misc.footprint];
	[blit optimizeContentsForGPUAccess:tex->misc.grasscolor];
	[blit optimizeContentsForGPUAccess:tex->misc.mapbg];
	[blit optimizeContentsForGPUAccess:tex->misc.pumpkinblur];
	[blit optimizeContentsForGPUAccess:tex->misc.shadow];
	[blit optimizeContentsForGPUAccess:tex->misc.vignette];
	[blit optimizeContentsForGPUAccess:tex->misc.water];
	[blit optimizeContentsForGPUAccess:tex->misc.watercolor];

	[blit generateMipmapsForTexture:tex->misc.dial];
	[blit generateMipmapsForTexture:tex->misc.foliagecolor];
	[blit generateMipmapsForTexture:tex->misc.footprint];
	[blit generateMipmapsForTexture:tex->misc.grasscolor];
	[blit generateMipmapsForTexture:tex->misc.mapbg];
	[blit generateMipmapsForTexture:tex->misc.mapicons];
	[blit generateMipmapsForTexture:tex->misc.particles];
	[blit generateMipmapsForTexture:tex->misc.pumpkinblur];
	[blit generateMipmapsForTexture:tex->misc.shadow];
	[blit generateMipmapsForTexture:tex->misc.vignette];
	[blit generateMipmapsForTexture:tex->misc.water];
	[blit generateMipmapsForTexture:tex->misc.watercolor];
}

static inline void tex_load_mob(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {
	tex->mob.chicken = tex2d("textures/mob/chicken.png", device);
	tex->mob.cow = tex2d("textures/mob/cow.png", device);
	tex->mob.creeper = tex2d("textures/mob/creeper.png", device);
	tex->mob.ghast = tex2d_array("textures/mob/ghast.png", 1, 2, device,
			blit);
	tex->mob.human = tex2d("textures/mob/human.png", device);
	tex->mob.pig = tex2d("textures/mob/pig.png", device);
	tex->mob.pigman = tex2d("textures/mob/pigman.png", device);
	tex->mob.pigzombie = tex2d("textures/mob/pigzombie.png", device);
	tex->mob.saddle = tex2d("textures/mob/saddle.png", device);
	tex->mob.sheep_fur = tex2d("textures/mob/sheep_fur.png", device);
	tex->mob.sheep = tex2d("textures/mob/sheep.png", device);
	tex->mob.silverfish = tex2d("textures/mob/silverfish.png", device);
	tex->mob.skeleton = tex2d("textures/mob/skeleton.png", device);
	tex->mob.slime = tex2d("textures/mob/slime.png", device);
	tex->mob.spider_eyes = tex2d("textures/mob/spider_eyes.png", device);
	tex->mob.spider = tex2d("textures/mob/spider.png", device);
	tex->mob.squid = tex2d("textures/mob/squid.png", device);
	tex->mob.wolf = tex2d_array("textures/mob/wolf.png", 1, 3, device,
			blit);
	tex->mob.zombie = tex2d("textures/mob/zombie.png", device);

	[blit optimizeContentsForGPUAccess:tex->mob.chicken];
	[blit optimizeContentsForGPUAccess:tex->mob.cow];
	[blit optimizeContentsForGPUAccess:tex->mob.creeper];
	[blit optimizeContentsForGPUAccess:tex->mob.human];
	[blit optimizeContentsForGPUAccess:tex->mob.pig];
	[blit optimizeContentsForGPUAccess:tex->mob.pigman];
	[blit optimizeContentsForGPUAccess:tex->mob.pigzombie];
	[blit optimizeContentsForGPUAccess:tex->mob.saddle];
	[blit optimizeContentsForGPUAccess:tex->mob.sheep_fur];
	[blit optimizeContentsForGPUAccess:tex->mob.sheep];
	[blit optimizeContentsForGPUAccess:tex->mob.silverfish];
	[blit optimizeContentsForGPUAccess:tex->mob.skeleton];
	[blit optimizeContentsForGPUAccess:tex->mob.slime];
	[blit optimizeContentsForGPUAccess:tex->mob.spider_eyes];
	[blit optimizeContentsForGPUAccess:tex->mob.spider];
	[blit optimizeContentsForGPUAccess:tex->mob.squid];
	[blit optimizeContentsForGPUAccess:tex->mob.zombie];

	[blit generateMipmapsForTexture:tex->mob.chicken];
	[blit generateMipmapsForTexture:tex->mob.cow];
	[blit generateMipmapsForTexture:tex->mob.creeper];
	[blit generateMipmapsForTexture:tex->mob.ghast];
	[blit generateMipmapsForTexture:tex->mob.human];
	[blit generateMipmapsForTexture:tex->mob.pig];
	[blit generateMipmapsForTexture:tex->mob.pigman];
	[blit generateMipmapsForTexture:tex->mob.pigzombie];
	[blit generateMipmapsForTexture:tex->mob.saddle];
	[blit generateMipmapsForTexture:tex->mob.sheep_fur];
	[blit generateMipmapsForTexture:tex->mob.sheep];
	[blit generateMipmapsForTexture:tex->mob.silverfish];
	[blit generateMipmapsForTexture:tex->mob.skeleton];
	[blit generateMipmapsForTexture:tex->mob.slime];
	[blit generateMipmapsForTexture:tex->mob.spider_eyes];
	[blit generateMipmapsForTexture:tex->mob.spider];
	[blit generateMipmapsForTexture:tex->mob.squid];
	[blit generateMipmapsForTexture:tex->mob.wolf];
	[blit generateMipmapsForTexture:tex->mob.zombie];
}

static inline void tex_load_terrain(struct texture *tex, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> blit) {
	tex->terrain.celestial = tex2d_array("textures/terrain/celestial.png",
			2, 1, device, blit);
	tex->terrain.terrain = tex2d_array_ex("textures/terrain/terrain.png",
			16, 16, device, blit, TEX_FLAG_WRITE);

	[blit generateMipmapsForTexture:tex->terrain.celestial];
	[blit generateMipmapsForTexture:tex->terrain.terrain];
}

/* TODO: make parallel */
struct texture *tex_load(struct texture *tex, id c) {
	id<MTLCommandQueue> cmdq = c;
	id<MTLDevice> device = cmdq.device;

	@autoreleasepool {
		id<MTLCommandBuffer> cmdb = [cmdq commandBuffer];
		id<MTLBlitCommandEncoder> blit = [cmdb blitCommandEncoder];

		tex_load_achievement(tex, device, blit);
		tex_load_armor(tex, device, blit);
		tex_load_art(tex, device, blit);
		tex_load_environment(tex, device, blit);
		tex_load_font(tex, device, blit);
		tex_load_gui(tex, device, blit);
		tex_load_item(tex, device, blit);
		tex_load_misc(tex, device, blit);
		tex_load_mob(tex, device, blit);
		tex_load_terrain(tex, device, blit);

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

static id<MTLTexture> tex2d_ex(const char *path, id<MTLDevice> device, int
		flags) {
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
	const char *pathstr = pathurl.fileSystemRepresentation;
	FILE *file = fopen(pathstr, "rb");
	if (file == NULL) {
		warn("fopen: %s", pathstr);
		return nil;
	}

	data = img_readpng(file, &width, &height, &channels, &bit_depth,
			&bytesperrow);
	fclose(file);
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
					 mipmapped:!(flags & TEX_FLAG_NO_MIP)];
	desc.cpuCacheMode = MTLCPUCacheModeWriteCombined;

	if (channels < 4)
		desc.swizzle = swizzle;

	if (flags & TEX_FLAG_WRITE)
		desc.usage = MTLTextureUsageShaderRead |
			MTLTextureUsageShaderWrite;

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

static id<MTLTexture> tex2d_array_ex(const char *path, unsigned short tx,
		unsigned short ty, id<MTLDevice> device,
		id<MTLBlitCommandEncoder> enc, int flags) {
	NSUInteger arraylen = tx * ty;
	if (arraylen > 2048)
		return nil;

	id<MTLTexture> basetex = tex2d_ex(path, device, TEX_FLAG_NO_MIP);

	uint32_t width = basetex.width / tx;
	uint32_t height = basetex.height / ty;

	MTLTextureDescriptor *desc = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat:basetex.pixelFormat
					     width:width
					    height:height
					 mipmapped:!(flags & TEX_FLAG_NO_MIP)];
	desc.textureType = MTLTextureType2DArray;
	desc.arrayLength = arraylen;
	desc.storageMode = MTLStorageModePrivate;

	desc.swizzle = basetex.swizzle;

	if (flags & TEX_FLAG_WRITE)
		desc.usage = MTLTextureUsageShaderRead |
			MTLTextureUsageShaderWrite;

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
