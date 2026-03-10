#include <err.h>
#include <stdint.h>
#include <stdlib.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_video.h>
#include <SDL3/SDL_vulkan.h>
#include <vulkan/vulkan.h>

#include <main.h>

#define WIDTH 640
#define HEIGHT 480

static char done = 0;

static VkInstance getinstance(void);
static VkDevice getdevice(VkInstance, VkSurfaceKHR);

void gl_main(void) {
	SDL_Window *window = SDL_CreateWindow("unbloCked", WIDTH, HEIGHT,
			SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY |
			SDL_WINDOW_VULKAN);
	if (window == NULL)
		errx(1, "%s", SDL_GetError());

	VkInstance instance = getinstance();

	VkSurfaceKHR surface;
	if (!SDL_Vulkan_CreateSurface(window, instance, NULL, &surface))
		errx(1, "%s", SDL_GetError());

	VkDevice device = getdevice(instance, surface);

	SDL_Event ev;
	while (!done && SDL_WaitEvent(&ev)) {
		switch (ev.type) {
			case SDL_EVENT_QUIT:
				done = 1;
				break;
		}
	}

	vkDestroyDevice(device, NULL);
	SDL_Vulkan_DestroySurface(instance, surface, NULL);
	vkDestroyInstance(instance, NULL);
	SDL_DestroyWindow(window);
}

static VkInstance getinstance(void) {
	uint32_t vk_extcount;
	const char *const *vk_exts = SDL_Vulkan_GetInstanceExtensions(
			&vk_extcount);


	VkApplicationInfo app_info = {
		.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
		.pApplicationName = "unbloCked"
	};

	VkInstanceCreateInfo inst_info = {
		.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
		.pApplicationInfo = &app_info,
		.enabledExtensionCount = vk_extcount,
		.ppEnabledExtensionNames = vk_exts
	};

	if (vkGetInstanceProcAddr(NULL, "vkEnumerateInstanceVersion") != NULL)
		vkEnumerateInstanceVersion(&app_info.apiVersion);

	VkInstance instance;
	VkResult result = vkCreateInstance(&inst_info, NULL, &instance);
	if (result != VK_SUCCESS)
		errx(1, "Failed to create Vulkan instance");

	return instance;
}

static VkDevice getdevice(VkInstance instance, VkSurfaceKHR surface) {
	VkResult res;

	uint32_t count;
	res = vkEnumeratePhysicalDevices(instance, &count, NULL);
	if (res != VK_SUCCESS || count == 0)
		errx(1, "Failed to get physical device");

	VkPhysicalDevice *devices = malloc(sizeof(VkPhysicalDevice) * count);
	if (devices == NULL)
		err(1, "malloc");

	res = vkEnumeratePhysicalDevices(instance, &count, devices);

	uint32_t device_ind = 0;
	uint32_t queue_faml = 0;

	VkQueueFamilyProperties *family_props = NULL;
	uint32_t family_prop_count_max = 0;
	for (uint32_t i = 0; i < count; ++i) {
		VkPhysicalDeviceProperties props;
		vkGetPhysicalDeviceProperties(devices[i], &props);
		uint32_t version = props.apiVersion;

		uint32_t family_prop_count;
		vkGetPhysicalDeviceQueueFamilyProperties(devices[i],
				&family_prop_count, NULL);

		if (family_prop_count_max < family_prop_count) {
			family_prop_count_max = family_prop_count;
			family_props = realloc(family_props, sizeof(
						*family_props) *
					family_prop_count_max);
			if (family_props == NULL)
				err(1, "realloc");
		} else
			family_prop_count = family_prop_count_max;

		vkGetPhysicalDeviceQueueFamilyProperties(devices[i],
				&family_prop_count, family_props);

		const VkQueueFlags needed = VK_QUEUE_GRAPHICS_BIT |
			VK_QUEUE_COMPUTE_BIT | VK_QUEUE_TRANSFER_BIT;
		uint32_t j = 0;
		for(; j < family_prop_count; ++j) {
			VkQueueFlags flags = family_props[j].queueFlags;
			if ((flags & needed) != needed)
				continue;

			VkBool32 supported = VK_FALSE;
			vkGetPhysicalDeviceSurfaceSupportKHR(devices[i], j,
					surface, &supported);
			if (supported == VK_FALSE)
				continue;

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

	uint32_t extn_count;
	vkEnumerateDeviceExtensionProperties(devices[device_ind], NULL,
			&extn_count, NULL);

	VkExtensionProperties *extn_props = malloc(extn_count * sizeof(
				VkExtensionProperties));
	if (extn_props == NULL)
		err(1, "malloc");

	vkEnumerateDeviceExtensionProperties(devices[device_ind], NULL,
			&extn_count, extn_props);

	char **extn_names = malloc(extn_count * sizeof(char **));
	if (extn_names == NULL)
		err(1, "malloc");

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
	res = vkCreateDevice(devices[device_ind], &dev_info, NULL, &device);
	if (res != VK_SUCCESS)
		errx(1, "Failed to get logial device");

	free(extn_names);
	free(extn_props);
	free(devices);

	return device;
}
