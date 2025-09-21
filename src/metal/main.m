#include <err.h>
#include <pthread.h>

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_metal.h>
#include <SDL3/SDL_video.h>

#include "../gutl.h"
#include "../image/png.h"
#include "../math/vector.h"
#include "gui/drawbutton.h"
#include "main.h"
#include "objc_macros.h"
#include "shaderstorage.h"

#define WIDTH 640
#define HEIGHT 480

enum anchor {
	ANC_TOPLEFT,
	ANC_TOPMIDDLE,
	ANC_TOPRIGHT,
	ANC_MIDDLELEFT,
	ANC_MIDDLE,
	ANC_MIDDLERIGHT,
	ANC_BOTTOMLEFT,
	ANC_BOTTOMMIDDLE,
	ANC_BOTTOMRIGHT
};

static pthread_mutex_t occllock = PTHREAD_MUTEX_INITIALIZER;
static id<MTLBuffer> matbuf;
static char done = 0;

static void *MTL_render(void *c);

static void updatemats(float *matrices, float width, float height);

void MTL_main(void) {
	SDL_Window *window = SDL_CreateWindow("unbloCked", WIDTH, HEIGHT,
			SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY |
			SDL_WINDOW_METAL);
	if (window == NULL)
		errx(1, "%s", SDL_GetError());

	if (!SDL_SetWindowMinimumSize(window, WIDTH, HEIGHT))
		warnx("%s", SDL_GetError());

	SDL_MetalView view = SDL_Metal_CreateView(window);
	void *l = SDL_Metal_GetLayer(view);
	CAMetalLayer *layer = (__bridge CAMetalLayer *)l;

	id<MTLDevice> device = nil;

	ARP_PUSH();
	NSProcessInfo *pinfo = NSProcessInfo.processInfo;
	bool lowpower = pinfo.lowPowerModeEnabled;

	NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
	NSEnumerator<id<MTLDevice>> *devenum = [devices objectEnumerator];
	id<MTLDevice> curdevice = nil;
	while(curdevice = [devenum nextObject]) {
		if (curdevice.lowPower == lowpower) {
			device = curdevice;
			[device retain];
			break;
		}
	}

	[devices release];
	ARP_POP();

	if (device == nil) {
		device = layer.preferredDevice;
		[device retain];
	}

	if (device == nil)
		device = MTLCreateSystemDefaultDevice();

	if (__builtin_expect(device == nil, 0))
		err(1, "Failed to get device!");

	layer.device = device;
	layer.pixelFormat = MTLPixelFormatBGRA8Unorm;

	/* just to make sure Cocoa is in multithreaded mode */
	if (__builtin_expect(![NSThread isMultiThreaded], false)) {
		NSThread *dummy = [NSThread new];
		[dummy start];
		[dummy cancel];
		[dummy release];
	}

	bool unified = [device hasUnifiedMemory];

	const MTLResourceOptions matbufops =
		MTLResourceCPUCacheModeWriteCombined;
	matbuf = [device newBufferWithLength:(sizeof(float) * (16 * 10))
				     options:matbufops];
	float *matrices = (float *)[matbuf contents];

	updatemats(matrices, (float)WIDTH, (float)HEIGHT);
	const NSRange matrange = NSMakeRange(0, sizeof(float) * (16 * 10));
	if (!unified)
		[matbuf didModifyRange:matrange];

	pthread_t rthread;
	pthread_create(&rthread, NULL, MTL_render, layer);

	char occluded = 0;
	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;
				break;
			case SDL_EVENT_MOUSE_BUTTON_DOWN:
				if (ev.button.button == 1) {
					warnx("click: (%g,%g)", ev.button.x,
							ev.button.y);
				}
				break;
			case SDL_EVENT_WINDOW_EXPOSED:
				if (occluded) {
					occluded = 0;
					pthread_mutex_unlock(&occllock);
				}

				break;
			case SDL_EVENT_WINDOW_OCCLUDED:
				if (!occluded) {
					occluded = 1;
					pthread_mutex_lock(&occllock);
				}

				break;
			case SDL_EVENT_WINDOW_RESIZED:
				updatemats(matrices, (float)ev.window.data1,
						(float)ev.window.data2);

				if (!unified)
					[matbuf didModifyRange:matrange];
				break;
		}
	}

	if (occluded)
		pthread_mutex_unlock(&occllock);

	pthread_join(rthread, NULL);

	[matbuf release];
	[device release];

	SDL_Metal_DestroyView(view);
	SDL_DestroyWindow(window);
}

static void *MTL_render(void *l) {
	CAMetalLayer *layer = (__bridge CAMetalLayer *)l;
	id<MTLDevice> device = layer.device;

	MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor
		renderPassDescriptor];
	MTLRenderPassColorAttachmentDescriptor *color = rpd.colorAttachments[0];
	color.loadAction = MTLLoadActionClear;
	color.storeAction = MTLStoreActionDontCare;
	color.clearColor = MTLClearColorMake(0.5, 0.8, 1.0, 1.0);

	struct shdrstore store;
	shdr_generate(&store, (struct objc_object *)device);

	id<MTLCommandQueue> cmdq = [device newCommandQueue];
	pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);

	id<MTLBuffer> buttonverts;
	id<MTLBuffer> buttoninds;
	gui_drawbutton_initbufs((struct objc_object *)device, (struct
				objc_object **)&buttonverts, (struct
					objc_object **)&buttoninds, -100.0f,
				0.0f, 200.0f, 16.0f);

	id<MTLTexture> texgui;

	ARP_PUSH();

	size_t width, height;
	int channels;
	unsigned char *texguidata = img_readpngpath("textures/gui/gui.png",
			&width, &height, &channels);

	MTLTextureDescriptor *desc = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
					     width:width
					    height:height
					 mipmapped:false];
	texgui = [device newTextureWithDescriptor:desc];

	MTLRegion replace = MTLRegionMake2D(0, 0, width, height);
	[texgui replaceRegion:replace
		  mipmapLevel:0
		    withBytes:texguidata
		  bytesPerRow:(width * channels)];

	free(texguidata);

	ARP_POP();

	while (__builtin_expect(!done, 1)) {
		/* freeze render thread when not visible */
		pthread_mutex_lock(&occllock);
		pthread_mutex_unlock(&occllock);

		ARP_PUSH();

		id<CAMetalDrawable> drawable = [layer nextDrawable];
		color.texture = drawable.texture;

		id<MTLCommandBuffer> cmdb = [cmdq commandBuffer];

		id<MTLRenderCommandEncoder> enc = [cmdb
			renderCommandEncoderWithDescriptor:rpd];

		id<MTLRenderPipelineState> button = (__bridge
				id<MTLRenderPipelineState>)store.button;
		[enc setRenderPipelineState:button];

		[enc setCullMode:MTLCullModeBack];

		[enc setVertexBuffer:matbuf offset:0 atIndex:0];
		uint8_t anchor = ANC_MIDDLE;
		[enc setVertexBytes:&anchor length:sizeof(anchor) atIndex:1];
		[enc setVertexBuffer:buttonverts offset:0 atIndex:2];

		[enc setFragmentTexture:texgui atIndex:0];

		[enc drawIndexedPrimitives:MTLPrimitiveTypeTriangle
				indexCount:12
				 indexType:MTLIndexTypeUInt16
			       indexBuffer:buttoninds
			 indexBufferOffset:0];

		[enc endEncoding];

		[cmdb presentDrawable:drawable];
		[cmdb commit];

		ARP_POP();
	}

	[texgui release];
	[buttonverts release];
	[buttoninds release];

	shdr_release(&store);

	[cmdq release];

	return NULL;
}

__attribute__((visibility("internal")))
static void updatemats(float *matrices, float width, float height) {
	float wd2 = width * 0.5f;
	float hd2 = height * 0.5f;

	GUTL_orthof(&matrices[(ANC_TOPLEFT * 16) + 16], 0.0f, width, -height,
			0.0f, 0.0f, 256.0f);
	GUTL_orthof(&matrices[(ANC_TOPMIDDLE * 16) + 16], -wd2, wd2, -height,
			0.0f, 0.0f, 256.0f);
	GUTL_orthof(&matrices[(ANC_TOPRIGHT * 16) + 16], -width, 0.0f, -height,
			0.0f, 0.0f, 256.0f);

	GUTL_orthof(&matrices[(ANC_MIDDLELEFT * 16) + 16], 0.0f, width, -hd2,
			hd2, 0.0f, 256.0f);
	GUTL_orthof(&matrices[(ANC_MIDDLE * 16) + 16], -wd2, wd2, -hd2, hd2,
			0.0f, 256.0f);
	GUTL_orthof(&matrices[(ANC_MIDDLERIGHT * 16) + 16], -width, 0.0f, -hd2,
			hd2, 0.0f, 256.0f);

	GUTL_orthof(&matrices[(ANC_BOTTOMLEFT * 16) + 16], 0.0f, width, 0.0f,
			height, 0.0f, 256.0f);
	GUTL_orthof(&matrices[(ANC_BOTTOMMIDDLE * 16) + 16], -wd2, wd2, 0.0f,
			height, 0.0f, 256.0f);
	GUTL_orthof(&matrices[(ANC_BOTTOMRIGHT * 16) + 16], -width, 0.0f, 0.0f,
			height, 0.0f, 256.0f); 
}
