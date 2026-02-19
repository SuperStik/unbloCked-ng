#import <Metal/Metal.h>

#include "helper.h"

void shdr_helper_rpd_fill(void *restrict rpd, void *restrict n, id vertfunc, id
		fragfunc) {
	MTLRenderPipelineDescriptor *desc = rpd;
	desc.label = n;
	desc.vertexFunction = vertfunc;
	[vertfunc release];
	desc.fragmentFunction = fragfunc;
	[fragfunc release];
	desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGR10A2Unorm;
	desc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
}

void shdr_helper_pipe_make(id *restrict pipe, void *restrict rpd, id d,
		dispatch_group_t group) {
	MTLRenderPipelineDescriptor *desc = rpd;
	id<MTLDevice> device = d;

	MTLNewRenderPipelineStateCompletionHandler handler = ^(
			id<MTLRenderPipelineState> state, NSError *e) {
		*pipe = state;
		[state retain];
		dispatch_group_leave(group);
	};

	dispatch_group_enter(group);
	[device newRenderPipelineStateWithDescriptor:desc
				   completionHandler:handler];

}
