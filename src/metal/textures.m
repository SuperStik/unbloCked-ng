#import <Metal/Metal.h>

#include "../image/png.h"
#include "objc_macros.h"
#include "textures.h"

static void expandalpha(unsigned char **data, int *channels, size_t width,
		size_t height);

struct textures *tex_generate(struct textures *tex, id device) {
	size_t width, height;
	int channels;
	unsigned char *texguidata = img_readpngpath("textures/gui/gui.png",
			&width, &height, &channels);
	expandalpha(&texguidata, &channels, width, height);

	ARP_PUSH();

	MTLTextureDescriptor *desc = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
					     width:width
					    height:height
					 mipmapped:false];
	desc.cpuCacheMode = MTLCPUCacheModeWriteCombined;
	tex->gui = [device newTextureWithDescriptor:desc];

	ARP_POP();

	MTLRegion replace = MTLRegionMake2D(0, 0, width, height);
	[tex->gui replaceRegion:replace
		    mipmapLevel:0
		      withBytes:texguidata
		    bytesPerRow:(width * channels)];

	free(texguidata);

	tex->background = nil;

	return tex;
}

void tex_release(struct textures *tex) {
	[tex->background release];
	[tex->gui release];
}

static void expandalpha(unsigned char **data, int *channels, size_t width,
		size_t height) {
	/* TODO: Implementation */
}
