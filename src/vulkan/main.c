#include <err.h>
#include <stdint.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_video.h>
#include <SDL3/SDL_vulkan.h>
#include <vulkan/vulkan.h>

#include <main.h>

#define WIDTH 640
#define HEIGHT 480

static char done = 0;

void gl_main(void) {
	SDL_Window *window = SDL_CreateWindow("unbloCked", WIDTH, HEIGHT,
			SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY |
			SDL_WINDOW_VULKAN);
	if (window == NULL)
		errx(1, "%s", SDL_GetError());

	uint32_t vk_extcount;
	const char *const *vk_exts = SDL_Vulkan_GetInstanceExtensions(
			&vk_extcount);

	VkInstanceCreateInfo info = {
		.enabledExtensionCount = vk_extcount,
		.ppEnabledExtensionNames = vk_exts
	};

	VkInstance instance;
	VkResult result = vkCreateInstance(&info, NULL, &instance);

	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;
				break;
		}
	}

	vkDestroyInstance(instance, NULL);
	SDL_DestroyWindow(window);
}
