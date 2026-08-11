#include <err.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_video.h>
#include <SDL3/SDL_vulkan.h>

#include "vk_pfn.h"

#include <gui/screen.h>
#include <main.h>
#include <scaledreso.h>

#define WIDTH 640
#define HEIGHT 480

static VkInstance getinstance(void);
static VkDevice getdevice(VkInstance, VkSurfaceKHR);

void gl_main(void) {
	SDL_Window *window = SDL_CreateWindow("unbloCked", WIDTH, HEIGHT,
			SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY |
			SDL_WINDOW_VULKAN);
	if (window == NULL)
		errx(1, "%s", SDL_GetError());

	setscaledreso(WIDTH, HEIGHT);
	float winwid = (float)WIDTH;
	float winhgt = (float)HEIGHT;
	scaledreso(&winwid, &winhgt);

	gui_screen_init(&screen, winwid, winhgt, GUI_SCREEN_MAINMENU);

	vkpfn_load_global();

	VkInstance instance = getinstance();

	VkSurfaceKHR surface;
	if (!SDL_Vulkan_CreateSurface(window, instance, NULL, &surface))
		errx(1, "%s", SDL_GetError());

	VkDevice device = getdevice(instance, surface);

	ev_loop();

	gui_screen_destroy(&screen);

	vkDestroyDevice(device, NULL);
	SDL_Vulkan_DestroySurface(instance, surface, NULL);
	vkDestroyInstance(instance, NULL);
	SDL_DestroyWindow(window);
}

static VkInstance getinstance(void) {
	VkApplicationInfo app_info = {
		.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
		.pApplicationName = "unbloCked",
		.apiVersion = VK_MAKE_API_VERSION(0, 1, 0, 0)
	};

	if (vkEnumerateInstanceVersion != NULL)
		vkEnumerateInstanceVersion(&app_info.apiVersion);

	uint32_t vk_extcount;
	const char *const *vk_exts_sdl = SDL_Vulkan_GetInstanceExtensions(
			&vk_extcount);

	/* vulkan-loader gets very angry without portability ext */
	const char **vk_exts = malloc(sizeof(char *) * vk_extcount + 1);
	if (vk_exts == NULL)
		err(1, "malloc");

	memcpy(vk_exts, vk_exts_sdl, sizeof(char *) * vk_extcount);
	vk_exts[vk_extcount++] = "VK_KHR_portability_enumeration";

	VkInstanceCreateInfo inst_info = {
		.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
		.flags = VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
		.pApplicationInfo = &app_info,
		.enabledExtensionCount = vk_extcount,
		.ppEnabledExtensionNames = vk_exts
	};

	VkInstance instance;
	VkResult result = vkCreateInstance(&inst_info, NULL, &instance);
	if (result != VK_SUCCESS)
		errx(1, "vkCreateInstance: %s", string_VkResult(result));

	free(vk_exts);

	fprintf(stderr, "Vulkan %u.%u.%u",
			VK_API_VERSION_MAJOR(app_info.apiVersion),
			VK_API_VERSION_MINOR(app_info.apiVersion),
			VK_API_VERSION_PATCH(app_info.apiVersion)
	       );
	unsigned variant = VK_API_VERSION_VARIANT(app_info.apiVersion);
	if (__builtin_expect(variant != 0, 0))
		fprintf(stderr, " (variant %u)\n", variant);
	else
		putc('\n', stderr);

	vkpfn_load_instance(instance);

	return instance;
}

static VkDevice getdevice(VkInstance instance, VkSurfaceKHR surface) {
	VkResult result;

	/* count number of physical devices on system */
	uint32_t count;
	result = vkEnumeratePhysicalDevices(instance, &count, NULL);
	if (result != VK_SUCCESS || count == 0)
		errx(1, "vkEnumeratePhysicalDevices: %s",
				string_VkResult(result));

	VkPhysicalDevice *devices = malloc(sizeof(VkPhysicalDevice) * count);
	if (devices == NULL)
		err(1, "malloc");

	/* store the physical devices in an array */
	result = vkEnumeratePhysicalDevices(instance, &count, devices);
	if (result != VK_SUCCESS || count == 0)
		errx(1, "vkEnumeratePhysicalDevices: %s",
				string_VkResult(result));

	uint32_t device_ind = 0;
	uint32_t queue_faml = 0;

	/* start off with a property array of size 0 */
	VkQueueFamilyProperties *family_props = NULL;
	uint32_t family_prop_array_size = 0;
	for (uint32_t i = 0; i < count; ++i) {
		VkPhysicalDeviceProperties props;
		vkGetPhysicalDeviceProperties(devices[i], &props);
		uint32_t version = props.apiVersion;

		uint32_t family_prop_count;
		vkGetPhysicalDeviceQueueFamilyProperties(devices[i],
				&family_prop_count, NULL);

		/* check if the current array is big enough */
		if (family_prop_array_size < family_prop_count) {
			/* it's not, so make it bigger */
			family_prop_array_size = family_prop_count;
			family_props = realloc(family_props, sizeof(
						*family_props) *
					family_prop_array_size);
			if (family_props == NULL)
				err(1, "realloc");
		} else
			/* give Vulkan the actual array size just in case */
			family_prop_count = family_prop_array_size;

		vkGetPhysicalDeviceQueueFamilyProperties(devices[i],
				&family_prop_count, family_props);

		const VkQueueFlags needed = VK_QUEUE_GRAPHICS_BIT |
			VK_QUEUE_COMPUTE_BIT | VK_QUEUE_TRANSFER_BIT;
		uint32_t j = 0;
		for(; j < family_prop_count; ++j) {
			/* if device doesn't support needed features, skip */
			VkQueueFlags flags = family_props[j].queueFlags;
			if ((flags & needed) != needed)
				continue;

			/* check if we can actually draw to a window */
			VkBool32 supported = VK_FALSE;
			vkGetPhysicalDeviceSurfaceSupportKHR(devices[i], j,
					surface, &supported);
			if (supported == VK_FALSE)
				continue;

			/* store indices for device and family */
			device_ind = i;
			queue_faml = j;
			goto found_device;
		}
	}

	errx(1, "Failed to get logial device");

found_device:
	free(family_props);

	float q_priorities = 1.0f;
	VkDeviceQueueCreateInfo q_info = {
		.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
		.queueFamilyIndex = queue_faml,
		.queueCount = 1,
		.pQueuePriorities = &q_priorities
	};

	/* get extension count for malloc */
	uint32_t extn_count;
	vkEnumerateDeviceExtensionProperties(devices[device_ind], NULL,
			&extn_count, NULL);

	VkExtensionProperties *extn_props = malloc(extn_count * sizeof(
				VkExtensionProperties));
	if (extn_props == NULL)
		err(1, "malloc");

	/* store the extension array */
	vkEnumerateDeviceExtensionProperties(devices[device_ind], NULL,
			&extn_count, extn_props);

	/* Vulkan gives us shit we don't need, so we need a separate array */
	char **extn_names = malloc(extn_count * sizeof(char **));
	if (extn_names == NULL)
		err(1, "malloc");

	/* we only want the raw extension name, so store that */
	/* TODO: only store extensions we use */
	for (uint32_t i = 0; i < extn_count; ++i)
		extn_names[i] = extn_props[i].extensionName;

	VkDeviceCreateInfo dev_info = {
		.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
		.enabledExtensionCount = extn_count,
		.ppEnabledExtensionNames = (const char *const *)extn_names,
		.queueCreateInfoCount = 1,
		.pQueueCreateInfos = &q_info
	};

	VkDevice device;
	result = vkCreateDevice(devices[device_ind], &dev_info, NULL, &device);
	if (result != VK_SUCCESS)
		errx(1, "vkCreateDevice: %s", string_VkResult(result));

	free(extn_names);
	free(extn_props);
	free(devices);

	vkpfn_load_device(device);

	return device;
}
