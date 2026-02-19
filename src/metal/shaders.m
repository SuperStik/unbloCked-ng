#include <stddef.h>

#include <dispatch/dispatch.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "shaders.h"
#include "shaders/background.h"
#include "shaders/button.h"
#include "shaders/text.h"

struct shaders *shdr_generate(struct shaders *store, id d) {
	id<MTLDevice> device = d;

	id<MTLLibrary> lib = [device newDefaultLibrary];

	dispatch_group_t group = dispatch_group_create();

	shdr_background_new(&(store->background), lib, group);

	shdr_button_new(&(store->button), lib, group);

	shdr_text_new(&(store->text), lib, group);

	[lib release];

	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_release(group);

	return store;
}

void shdr_release(struct shaders *store) {
	[store->background release];
	[store->button release];
	[store->text release];
}

