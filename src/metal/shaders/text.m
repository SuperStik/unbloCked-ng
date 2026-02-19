#import <Metal/Metal.h>

#include "../gui/drawtext.h"

#include "helper.h"
#include "text.h"

void shdr_text_new(id *pipe, id l, dispatch_group_t group) {
	id<MTLLibrary> lib = l;
	
	id<MTLFunction> vertfunc = [lib newFunctionWithName:@"vertText"];
	id<MTLFunction> fragfunc = [lib newFunctionWithName:@"fragText"];

	MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
	shdr_helper_rpd_fill(desc, @"pipeline.gui.text", vertfunc, fragfunc);

	MTLRenderPipelineColorAttachmentDescriptor *color;
	color = desc.colorAttachments[0];
	color.blendingEnabled = true;
	color.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	color.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;

	MTLPipelineBufferDescriptorArray *bufs = desc.vertexBuffers;
	bufs[0].mutability = MTLMutabilityImmutable;
	bufs[16].mutability = MTLMutabilityImmutable;
	bufs[17].mutability = MTLMutabilityImmutable;

	@autoreleasepool {
		MTLVertexDescriptor *vertexdesc = [MTLVertexDescriptor
			vertexDescriptor];

		MTLVertexAttributeDescriptorArray *attrs =
			vertexdesc.attributes;
		MTLVertexAttributeDescriptor *attr;

		attr = attrs[0];
		attr.format = MTLVertexFormatFloat2;
		attr.offset = offsetof(struct gui_textvert, pos);
		attr.bufferIndex = 16;

		attr = attrs[1];
		attr.format = MTLVertexFormatHalf2;
		attr.offset = offsetof(struct gui_textvert, uv);
		attr.bufferIndex = 16;

		attr = attrs[2];
		attr.format = MTLVertexFormatUChar;
		attr.offset = offsetof(struct gui_textvert, character);
		attr.bufferIndex = 16;

		vertexdesc.layouts[16].stride = sizeof(struct gui_textvert);

		desc.vertexDescriptor = vertexdesc;
	}

	shdr_helper_pipe_make(pipe, desc, lib.device, group);

	[desc release];
}
