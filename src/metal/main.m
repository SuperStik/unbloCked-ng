#include <err.h>
#include <pthread.h>

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_metal.h>
#include <SDL3/SDL_video.h>

#include "../gutl.h"
#include "../math/vector.h"
#include "gui/anchor.h"
#include "gui/drawbutton.h"
#include "main.h"
#include "objc_macros.h"
#include "shaders.h"
#include "textures.h"

#define WIDTH 640
#define HEIGHT 480

struct resizedata {
	float *matrices;
	bool unified;
};

static pthread_mutex_t occllock = PTHREAD_MUTEX_INITIALIZER;
static id<MTLBuffer> matbuf;
static char done = 0;

static void *MTL_render(void *c);

static bool onwindowresize(void *userdata, SDL_Event *);

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

	struct resizedata resizedata = {matrices, unified};
	SDL_AddEventWatch(onwindowresize, &resizedata);

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
	color.loadAction = MTLLoadActionDontCare;
	color.storeAction = MTLStoreActionDontCare;
	/* we don't need this for drawing UI */
	/*color.clearColor = MTLClearColorMake(0.5, 0.8, 1.0, 1.0);*/

	id<MTLCommandQueue> cmdq = [device newCommandQueue];
	pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);

	id<MTLBuffer> buttonverts = gui_drawbutton_getverts(device, -100.0f,
			0.0f, 200.0f, 16.0f);
	id<MTLBuffer> buttoninds = gui_drawbutton_getinds(device);

	struct shaders shdr;
	shdr_generate(&shdr, device);

	struct textures tex;
	tex_generate(&tex, device, cmdq);

	gvec(float,2) bgverts[] = {
		{1.0f, -1.0f},
		{-1.0f, -1.0f},
		{1.0f, 1.0f},
		{-1.0f, 1.0f}
	};
	
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

		[enc setCullMode:MTLCullModeBack];
		[enc setVertexBuffer:matbuf offset:0 atIndex:0];

		/* background */
		[enc setRenderPipelineState:shdr.background];

		[enc setVertexBytes:bgverts length:sizeof(bgverts) atIndex:1];

		[enc setFragmentTexture:tex.background atIndex:0];

		[enc drawPrimitives:MTLPrimitiveTypeTriangleStrip
			vertexStart:0
			vertexCount:4];

		/* buttons */
		[enc setRenderPipelineState:shdr.button];

		[enc setFragmentTexture:tex.gui atIndex:0];

		gui_drawbutton_draw(buttonverts, buttoninds, enc);

		[enc endEncoding];

		[cmdb presentDrawable:drawable];
		[cmdb commit];

		ARP_POP();
	}

	[buttonverts release];
	[buttoninds release];

	shdr_release(&shdr);
	tex_release(&tex);

	[cmdq release];

	return NULL;
}

static bool onwindowresize(void *userdata, SDL_Event *event) {
	struct resizedata *resizedata = userdata;
	switch(event->type) {
		case SDL_EVENT_WINDOW_RESIZED:
			updatemats(resizedata->matrices,
					(float)event->window.data1,
					(float)event->window.data2);

			if (!resizedata->unified) {
				const NSRange matrange = NSMakeRange(0,
						sizeof(float) * (16 * 10));
				[matbuf didModifyRange:matrange];
			}

			break;
		case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
			/* TODO: depth buffer */
			break;
	}

	return true;
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
