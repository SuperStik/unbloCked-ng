#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "objc_macros.h"
#include "shaders.h"

struct shaders *shdr_generate(struct shaders *store, id d) {
	id<MTLDevice> device = d;
	MTLPipelineBufferDescriptorArray *bufs;

	id<MTLLibrary> lib = [device newDefaultLibrary];

	id<MTLFunction> vertButton = [lib newFunctionWithName:@"vertButton"];
	id<MTLFunction> vertBackground = [lib
		newFunctionWithName:@"vertBackground"];
	id<MTLFunction> fragGeneric = [lib newFunctionWithName:@"fragGeneric"];

	[lib release];

	/* Button Pipeline */
	MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
	desc.label = @"pipeline.gui.button";
	desc.vertexFunction = vertButton;
	[vertButton release];
	desc.fragmentFunction = fragGeneric;
	desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

	bufs = desc.vertexBuffers;
	for (int i = 0; i < 3; ++i)
		bufs[i].mutability = MTLMutabilityImmutable;

	store->button = [device newRenderPipelineStateWithDescriptor:desc
							       error:nil];

	/* Background Pipeline */
	[desc reset];
	desc.label = @"pipeline.gui.background";
	desc.vertexFunction = vertBackground;
	[vertBackground release];
	desc.fragmentFunction = fragGeneric;
	[fragGeneric release];
	desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

	bufs = desc.vertexBuffers;
	for (int i = 0; i < 2; ++i)
		bufs[i].mutability = MTLMutabilityImmutable;

	store->background = [device newRenderPipelineStateWithDescriptor:desc
								   error:nil];

	[desc release];

	return store;
}

void shdr_release(struct shaders *store) {
	[store->button release];
	[store->background release];
}

