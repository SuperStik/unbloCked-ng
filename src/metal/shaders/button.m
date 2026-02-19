#import <Metal/Metal.h>

#include "../gui/drawbutton.h"
#include "button.h"
#include "helper.h"

void shdr_button_new(id *pipe, id l, dispatch_group_t group) {
	id<MTLLibrary> lib = l;

	id<MTLFunction> vertfunc = [lib newFunctionWithName:@"vertButton"];
	id<MTLFunction> fragfunc = [lib newFunctionWithName:@"fragButton"];

	MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
	shdr_helper_rpd_fill(desc, @"pipeline.gui.button", vertfunc, fragfunc);

	MTLPipelineBufferDescriptorArray *bufs = desc.vertexBuffers;
	bufs[0].mutability = MTLMutabilityImmutable;
	bufs[4].mutability = MTLMutabilityImmutable;
	bufs[16].mutability = MTLMutabilityImmutable;

	@autoreleasepool {
		MTLVertexDescriptor *vertexdesc = [MTLVertexDescriptor
			vertexDescriptor];
		
		MTLVertexAttributeDescriptorArray *attrs =
			vertexdesc.attributes;
		MTLVertexAttributeDescriptor *attr;

		attr = attrs[0];
		attr.format = MTLVertexFormatFloat2;
		attr.offset = offsetof(struct gui_buttonverts, pos);
		attr.bufferIndex = 16;

		attr = attrs[1];
		attr.format = MTLVertexFormatFloat2;
		attr.offset = offsetof(struct gui_buttonverts, uv);
		attr.bufferIndex = 16;

		attr = attrs[2];
		attr.format = MTLVertexFormatFloat2;
		attr.offset = offsetof(struct gui_button_info, pos);
		attr.bufferIndex = 4;

		attr = attrs[3];
		attr.format = MTLVertexFormatUChar;
		attr.offset = offsetof(struct gui_button_info, anchor);
		attr.bufferIndex = 4;

		attr = attrs[4];
		attr.format = MTLVertexFormatUChar;
		attr.offset = offsetof(struct gui_button_info, state);
		attr.bufferIndex = 4;

		MTLVertexBufferLayoutDescriptorArray *layouts =
			vertexdesc.layouts;
		MTLVertexBufferLayoutDescriptor *layout;

		layout = layouts[4];
		layout.stepFunction = MTLVertexStepFunctionPerInstance;
		layout.stride = sizeof(struct gui_button_info);
		layouts[16].stride = sizeof(struct gui_buttonverts);

		desc.vertexDescriptor = vertexdesc;
	}
	
	shdr_helper_pipe_make(pipe, desc, lib.device, group);

	[desc release];
}
