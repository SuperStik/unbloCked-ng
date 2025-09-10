#include <err.h>
#include <pthread.h>

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_metal.h>
#include <SDL3/SDL_video.h>

#include "../math/vector.h"
#include "main.h"
#include "objc_macros.h"
#include "shaderstorage.h"

#define WIDTH 640
#define HEIGHT 480

struct buttonvert {
	gvec(float,2) pos;
	gvec(_Float16,2) texcoords;
};

static pthread_mutex_t occllock = PTHREAD_MUTEX_INITIALIZER;
static char done = 0;

static void *MTL_render(void *c);

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
			break;
		}
	}

	[devices release];
	ARP_POP();

	if (device == nil)
		device = layer.preferredDevice;

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

	pthread_t rthread;
	pthread_create(&rthread, NULL, MTL_render, layer);

	char occluded = 0;
	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;
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
		}
	}

	if (occluded)
		pthread_mutex_unlock(&occllock);

	pthread_join(rthread, NULL);

	[device release];
	SDL_Metal_DestroyView(view);
	SDL_DestroyWindow(window);
}

static void *MTL_render(void *l) {
	CAMetalLayer *layer = (__bridge CAMetalLayer *)l;
	id<MTLDevice> device = layer.device;

	ARP_PUSH();

	MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor
		renderPassDescriptor];
	MTLRenderPassColorAttachmentDescriptor *color = rpd.colorAttachments[0];
	color.loadAction = MTLLoadActionClear;
	color.storeAction = MTLStoreActionDontCare;
	color.clearColor = MTLClearColorMake(0.5, 0.8, 1.0, 1.0);

	const struct buttonvert verts[4] = {
		{{-0.75f, -0.5f}, {0.0f, 1.0f}},
		{{-0.75f, 0.5f}, {0.0f, 0.0f}},
		{{0.75f, -0.5f}, {1.0f, 1.0f}},
		{{0.75f, 0.5f}, {1.0f, 0.0f}}
	};

	id<MTLBuffer> rect = [device
		newBufferWithBytes:verts
			    length:sizeof(verts)
			   options:MTLResourceCPUCacheModeWriteCombined];

	struct shdrstore store;
	shdr_generate(&store, (struct objc_object *)device);

	id<MTLCommandQueue> cmdq = [device newCommandQueue];
	pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);

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
		[enc setVertexBuffer:rect offset:0 atIndex:1];
		[enc setCullMode:MTLCullModeBack];
		[enc drawPrimitives:MTLPrimitiveTypeTriangleStrip
			vertexStart:0
			vertexCount:4];
		[enc endEncoding];

		[cmdb presentDrawable:drawable];
		[cmdb commit];

		ARP_POP();
	}

	[rect release];
	shdr_release(&store);

	[cmdq release];
	ARP_POP();

	return NULL;
}
