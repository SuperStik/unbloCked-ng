#import <Metal/Metal.h>

#include <math/vector.h>

#include "background.h"
#include "helper.h"

void shdr_background_new(id *pipe, id l, dispatch_group_t group) {
	id<MTLLibrary> lib = l;

	id<MTLFunction> vertfunc = [lib newFunctionWithName:@"vertBackground"];
	id<MTLFunction> fragfunc = [lib newFunctionWithName:@"fragBackground"];
	MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor
		new];
	shdr_helper_rpd_fill(desc, @"pipeline.gui.background", vertfunc,
			fragfunc);

	MTLPipelineBufferDescriptorArray *bufs = desc.vertexBuffers;
	bufs[0].mutability = MTLMutabilityImmutable;
	bufs[16].mutability = MTLMutabilityImmutable;

	@autoreleasepool {
		MTLVertexDescriptor *vertexdesc = [MTLVertexDescriptor
			vertexDescriptor];

		MTLVertexAttributeDescriptor *attr = vertexdesc.attributes[0];
		attr.format = MTLVertexFormatHalf2;
		attr.offset = 0;
		attr.bufferIndex = 16;

		vertexdesc.layouts[16].stride = sizeof(gvec(_Float16,2));

		desc.vertexDescriptor = vertexdesc;
	}

	shdr_helper_pipe_make(pipe, desc, lib.device, group);

	[desc release];
}

