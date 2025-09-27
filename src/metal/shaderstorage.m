#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "objc_macros.h"
#include "shaderstorage.h"

struct shdrstore *shdr_generate(struct shdrstore *store, id d) {
	id<MTLDevice> device = d;

	id<MTLLibrary> lib = [device newDefaultLibrary];

	id<MTLFunction> vertButton = [lib newFunctionWithName:@"vertButton"];
	id<MTLFunction> fragButton = [lib newFunctionWithName:@"fragButton"];

	[lib release];

	MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
	desc.label = @"pipeline.gui.button";
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

	store->button = rpsButton;

	return store;
}

void shdr_release(struct shdrstore *store) {
	[store->button release];
}

