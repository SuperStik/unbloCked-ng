#include <err.h>
#include <pthread.h>

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_metal.h>
#include <SDL3/SDL_video.h>

#include "gui/anchor.h"
#include "gui/drawmainmenu.h"
#include "gui/mainmenu.h"
#include "gui/screen.h"
#include <main.h>
#include <math/vector.h>
#include <projection.h>
#include "shaders.h"
#include "textures.h"

#define WIDTH 640
#define HEIGHT 480

extern struct gui_screen *currentscreen;

static pthread_mutex_t occllock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t depthlock = PTHREAD_MUTEX_INITIALIZER;
static id<MTLBuffer> matbuf;
static id<MTLTexture> depthtex = nil;
static float resolutionscale = 1.0f;
static char done = 0;
static char occluded = 0;

static void *MTL_render(void *c);

static void scaledreso(float *w, float *h);

static bool onwindowresize(void *userdata, SDL_Event *);

static void rebuilddepth(id<MTLDevice>, uint32_t w, uint32_t h);

static void updatemats(float *matrices, float width, float height);

static id<MTLDevice> getdevice(CAMetalLayer *);

void gl_main(void) {
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

	id<MTLDevice> device = getdevice(layer);

	if (__builtin_expect(device == nil, 0))
		errx(1, "Failed to get device!");

	layer.device = device;
	layer.pixelFormat = MTLPixelFormatBGR10A2Unorm;

	/* just to make sure Cocoa is in multithreaded mode */
	if (__builtin_expect(![NSThread isMultiThreaded], false)) {
		NSThread *dummy = [NSThread new];
		[dummy start];
		[dummy cancel];
		[dummy release];
	}

	matbuf = [device
		newBufferWithLength:(sizeof(float) * 16 * 10)
			    options:MTLResourceCPUCacheModeWriteCombined];
	float *matrices = [matbuf contents];

	float winwid = (float)WIDTH;
	float winhgt = (float)HEIGHT;
	scaledreso(&winwid, &winhgt);
	updatemats(matrices, winwid, winhgt);

	struct gui_mainmenu mainmenu;
	gui_mainmenu_init(&mainmenu, winwid, winhgt);
	currentscreen = &mainmenu.screen;

	const NSRange matrange = NSMakeRange(0, sizeof(float) * 16 * 10);
	if (matbuf.storageMode == MTLStorageModeManaged)
		[matbuf didModifyRange:matrange];

	int wid, hgt;
	SDL_GetWindowSizeInPixels(window, &wid, &hgt);
	rebuilddepth(device, wid, hgt);

	SDL_AddEventWatch(onwindowresize, matrices);

	pthread_t rthread;
	pthread_create(&rthread, NULL, MTL_render, layer);

	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;
				break;
			case SDL_EVENT_MOUSE_BUTTON_DOWN:
				if (ev.button.button == 1) {
					float scale = resolutionscale;
					float x = ev.button.x / scale;
					float y = ev.button.y / scale;
					gui_screen_onclick(currentscreen, x, y);
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
				;
				float w = (float)ev.window.data1;
				float h = (float)ev.window.data2;
				scaledreso(&w, &h);

				gui_mainmenu_resize(&mainmenu, w, h);

				break;
		}
	}

	if (occluded)
		pthread_mutex_unlock(&occllock);

	pthread_join(rthread, NULL);

	[matbuf release];
	[depthtex release];
	[device release];

	gui_mainmenu_destroy(&mainmenu);

	SDL_Metal_DestroyView(view);
	SDL_DestroyWindow(window);
}

static void *MTL_render(void *l) {
	CAMetalLayer *layer = (__bridge CAMetalLayer *)l;
	id<MTLDevice> device = layer.device;

	pthread_setname_np("unbloCked.render-thread");

	MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor
		renderPassDescriptor];
	MTLRenderPassColorAttachmentDescriptor *color = rpd.colorAttachments[0];
	color.loadAction = MTLLoadActionDontCare;
	color.storeAction = MTLStoreActionDontCare;
	MTLRenderPassDepthAttachmentDescriptor *depth = rpd.depthAttachment;
	depth.loadAction = MTLLoadActionClear;
	depth.storeAction = MTLStoreActionDontCare;
	/* we don't need this for drawing UI */
	/*color.clearColor = MTLClearColorMake(0.5, 0.8, 1.0, 1.0);*/

	id<MTLCommandQueue> cmdq = [device newCommandQueue];
	pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);

	struct shaders shdr;
	shdr_generate(&shdr, device);

	warnx("Loading textures...");
	struct texture tex;
	tex_load(&tex, cmdq);
	warnx("Done!");

	const gvec(_Float16,2) bgverts[] = {
		{1.0f16, -1.0f16},
		{-1.0f16, -1.0f16},
		{1.0f16, 1.0f16},
		{-1.0f16, 1.0f16}
	};

	struct gui_drawmainmenu drawmainmenu;
	drawmainmenu.pipeline.button = shdr.button;
	drawmainmenu.pipeline.text = shdr.text;
	drawmainmenu.texture.font = tex.font.font;
	drawmainmenu.texture.gui = tex.gui.gui;
	gui_drawmainmenu_init(&drawmainmenu, currentscreen, device);

	MTLDepthStencilDescriptor *depthdesc = [MTLDepthStencilDescriptor new];

	depthdesc.depthCompareFunction = MTLCompareFunctionLessEqual;
	depthdesc.label = @"depth.state.lex";
	id<MTLDepthStencilState> d_blended = [device
		newDepthStencilStateWithDescriptor:depthdesc];

	depthdesc.depthWriteEnabled = true;
	depthdesc.label = @"depth.state.lew";
	id<MTLDepthStencilState> d_opaque = [device
		newDepthStencilStateWithDescriptor:depthdesc];

	[depthdesc release];

	pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);

	while (__builtin_expect(!done, 1)) {
		/* freeze render thread when not visible */
		if (occluded) {
			pthread_mutex_lock(&occllock);
			pthread_mutex_unlock(&occllock);
		}

		@autoreleasepool {
			id<CAMetalDrawable> drawable = [layer nextDrawable];
			color.texture = drawable.texture;

			if (depth.texture != depthtex) {
				pthread_mutex_lock(&depthlock);
				depth.texture = depthtex;
				pthread_mutex_unlock(&depthlock);
			}

			id<MTLCommandBuffer> cmdb = [cmdq commandBuffer];

			id<MTLRenderCommandEncoder> enc = [cmdb
				renderCommandEncoderWithDescriptor:rpd];

			[enc setCullMode:MTLCullModeBack];

			[enc setVertexBuffer:matbuf offset:0 atIndex:0];

			/* opaque */
			[enc setDepthStencilState:d_opaque];

			gui_drawmainmenu_draw_opaque(&drawmainmenu, enc);

			[enc setRenderPipelineState:shdr.background];

			[enc setVertexBytes:bgverts length:sizeof(bgverts)
				    atIndex:16];

			[enc setFragmentTexture:tex.gui.background atIndex:0];

			[enc drawPrimitives:MTLPrimitiveTypeTriangleStrip
				vertexStart:0
				vertexCount:4];

			/* blended */
			[enc setDepthStencilState:d_blended];
			gui_drawmainmenu_draw_blended(&drawmainmenu, enc);

			[enc endEncoding];

			[cmdb presentDrawable:drawable];
			[cmdb commit];
		}
	}

	[d_opaque release];
	[d_blended release];

	gui_drawmainmenu_release(&drawmainmenu);

	shdr_release(&shdr);
	tex_unload(&tex);

	[cmdq release];

	return NULL;
}

static void scaledreso(float *w, float *h) {
	float curwid = *w;
	float curhgt = *h;

	float ratiowid = curwid / ((float)WIDTH * 0.5f);
	float ratiohgt = curhgt / ((float)HEIGHT * 0.5f);

	float ratio = fminf(ratiowid, ratiohgt);
	ratio = fmaxf(ratio, 1.0f);

	*w = curwid / ratio;
	*h = curhgt / ratio;

	resolutionscale = ratio;
}

static bool onwindowresize(void *userdata, SDL_Event *event) {
	float *matrices = userdata;
	switch(event->type) {
		case SDL_EVENT_WINDOW_RESIZED:
			;
			float w = (float)event->window.data1;
			float h = (float)event->window.data2;

			scaledreso(&w, &h);

			updatemats(matrices, w, h);

			if (matbuf.storageMode == MTLStorageModeManaged) {
				const NSRange matrange = NSMakeRange(0,
						sizeof(float) * (16 * 10));
				[matbuf didModifyRange:matrange];
			}

			break;
		case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
			rebuilddepth(matbuf.device, event->window.data1,
					event->window.data2);
			break;
	}

	return true;
}

static void rebuilddepth(id<MTLDevice> device, uint32_t w, uint32_t h) {
	pthread_mutex_lock(&depthlock);
	[depthtex release];

	@autoreleasepool {
		const MTLPixelFormat fmt = MTLPixelFormatDepth32Float;
		MTLTextureDescriptor *desc = [MTLTextureDescriptor
			texture2DDescriptorWithPixelFormat:fmt
						     width:w
						    height:h
						 mipmapped:false];
		desc.storageMode = MTLStorageModePrivate;
		desc.usage = MTLTextureUsageRenderTarget;

		depthtex = [device newTextureWithDescriptor:desc];
		depthtex.label = @"depth.texture";
	}

	pthread_mutex_unlock(&depthlock);
}

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

static id<MTLDevice> getdevice(CAMetalLayer *layer) {
	id<MTLDevice> device = nil;

	@autoreleasepool {
		NSProcessInfo *pinfo = NSProcessInfo.processInfo;
		bool lowpower = pinfo.lowPowerModeEnabled;

		NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
		NSEnumerator<id<MTLDevice>> *devenum = [devices
			objectEnumerator];
		id<MTLDevice> curdevice = nil;
		while(curdevice = [devenum nextObject]) {
			if (curdevice.lowPower == lowpower) {
				device = curdevice;
				[device retain];
				break;
			}
		}

		[devices release];
	}

	if (device == nil) {
		device = layer.preferredDevice;
		[device retain];
	}

	if (device == nil)
		device = MTLCreateSystemDefaultDevice();

	return device;
}
