#import <Metal/Metal.h>

#include "shaderstorage.h"

struct shdrstore *shdr_generate(struct shdrstore *store, struct objc_object *d)
{
	id<MTLDevice> device = (__bridge id<MTLDevice>)d;

	return store;
}

void shdr_release(struct shdrstore *store) {
	id<MTLRenderPipelineState> buttons = (__bridge
			id<MTLRenderPipelineState>)store->buttons;
	[buttons release];
}

