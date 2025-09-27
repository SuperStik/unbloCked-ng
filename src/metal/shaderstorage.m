#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "objc_macros.h"
#include "shaderstorage.h"

struct shdrstore *shdr_generate(struct shdrstore *store, struct objc_object *d)
{
	id<MTLDevice> device = (__bridge id<MTLDevice>)d;

	id<MTLLibrary> lib = [device newDefaultLibrary];

	id<MTLFunction> vertButton = [lib newFunctionWithName:@"vertButton"];
	id<MTLFunction> fragButton = [lib newFunctionWithName:@"fragButton"];

	[lib release];

	MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
	desc.label = @"Button Render Pipeline";
	desc.vertexFunction = vertButton;
	[vertButton release];
	desc.fragmentFunction = fragButton;
	[fragButton release];
	desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

	MTLPipelineBufferDescriptorArray *bufs = desc.vertexBuffers;
	for (int i = 0; i < 3; ++i)
		bufs[i].mutability = MTLMutabilityImmutable;

	id<MTLRenderPipelineState> rpsButton = [device
		newRenderPipelineStateWithDescriptor:desc error:nil];

	[desc release];

	store->button = (struct objc_object *)rpsButton;

	return store;
}

void shdr_release(struct shdrstore *store) {
	id<MTLRenderPipelineState> button = (__bridge
			id<MTLRenderPipelineState>)store->button;
	[button release];
}

