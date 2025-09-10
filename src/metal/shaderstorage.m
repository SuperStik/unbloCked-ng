#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "objc_macros.h"
#include "shaderstorage.h"

struct shdrstore *shdr_generate(struct shdrstore *store, struct objc_object *d)
{
	id<MTLDevice> device = (__bridge id<MTLDevice>)d;
	[device retain];

	ARP_PUSH();

	NSBundle *bundle = [NSBundle mainBundle];
	NSURL *liburl = [bundle URLForResource:@"resources/shaders/default"
				 withExtension:@".metallib"];

	id<MTLLibrary> lib = [device newLibraryWithURL:liburl error:nil];

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

	id<MTLRenderPipelineState> rpsButton;
	rpsButton = [device newRenderPipelineStateWithDescriptor:desc
							   error:nil];

	[device release];

	store->button = (struct objc_object *)rpsButton;

	[desc release];

	ARP_POP();

	return store;
}

void shdr_release(struct shdrstore *store) {
	id<MTLRenderPipelineState> button = (__bridge
			id<MTLRenderPipelineState>)store->button;
	[button release];
}

