#include <err.h>

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_metal.h>
#include <SDL3/SDL_video.h>

#include "main.h"
#include "objc_macros.h"

#define WIDTH 640
#define HEIGHT 480

static char done = 0;

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

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 101500
	if (device == nil)
		device = layer.preferredDevice;
#endif

	if (device == nil)
		device = MTLCreateSystemDefaultDevice();

	if (__builtin_expect(device == nil, 0))
		err(1, "Failed to get device!");

	layer.device = device;
	layer.pixelFormat = MTLPixelFormatBGRA8Unorm;

	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;
				break;
		}
	}

	[device release];
	SDL_Metal_DestroyView(view);
	SDL_DestroyWindow(window);
}

static void *MTL_render(void *c) {
	return NULL;
}
