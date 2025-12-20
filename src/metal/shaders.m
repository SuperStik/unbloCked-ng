#include <stddef.h>

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "../math/vector.h"
#include "gui/drawbutton.h"
#include "gui/drawtext.h"
#include "objc_macros.h"
#include "shaders.h"

struct shaders *shdr_generate(struct shaders *store, id d) {
	id<MTLDevice> device = d;
	MTLPipelineBufferDescriptorArray *bufs;
	MTLVertexAttributeDescriptorArray *attrs;
	MTLVertexAttributeDescriptor *attr;
	MTLVertexBufferLayoutDescriptorArray *layouts;
	MTLVertexBufferLayoutDescriptor *layout;

	id<MTLLibrary> lib = [device newDefaultLibrary];

	id<MTLFunction> vertBackground = [lib
		newFunctionWithName:@"vertBackground"];
	id<MTLFunction> vertButton = [lib newFunctionWithName:@"vertButton"];
	id<MTLFunction> vertText = [lib newFunctionWithName:@"vertText"];

	id<MTLFunction> fragBackground = [lib
		newFunctionWithName:@"fragBackground"];
	id<MTLFunction> fragGeneric = [lib newFunctionWithName:@"fragGeneric"];
	id<MTLFunction> fragText = [lib newFunctionWithName:@"fragText"];

	[lib release];

	ARP_PUSH();

	/* Background Pipeline */
	MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
	MTLVertexDescriptor *vertexdesc = [MTLVertexDescriptor
		vertexDescriptor];
	desc.label = @"pipeline.gui.background";
	desc.vertexFunction = vertBackground;
	[vertBackground release];
	desc.fragmentFunction = fragBackground;
	[fragBackground release];
	desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

	bufs = desc.vertexBuffers;
	bufs[0].mutability = MTLMutabilityImmutable;
	bufs[16].mutability = MTLMutabilityImmutable;

	attr = vertexdesc.attributes[0];
	attr.format = MTLVertexFormatChar2Normalized;
	attr.offset = 0;
	attr.bufferIndex = 16;

	vertexdesc.layouts[16].stride = sizeof(gvec(uint8_t,2));

	desc.vertexDescriptor = vertexdesc;

	store->background = [device newRenderPipelineStateWithDescriptor:desc
								   error:nil];

	/* Button Pipeline */
	[desc reset];
	[vertexdesc reset];
	desc.label = @"pipeline.gui.button";
	desc.vertexFunction = vertButton;
	[vertButton release];
	desc.fragmentFunction = fragGeneric;
	[fragGeneric release];
	desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

	bufs = desc.vertexBuffers;
	bufs[0].mutability = MTLMutabilityImmutable;
	bufs[4].mutability = MTLMutabilityImmutable;
	bufs[16].mutability = MTLMutabilityImmutable;
	attrs = vertexdesc.attributes;

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

	layouts = vertexdesc.layouts;
	layout = layouts[4];
	layout.stepFunction = MTLVertexStepFunctionPerInstance;
	layout.stride = sizeof(struct gui_button_info);
	layouts[16].stride = sizeof(struct gui_buttonverts);

	desc.vertexDescriptor = vertexdesc;

	store->button = [device newRenderPipelineStateWithDescriptor:desc
							       error:nil];

	/* Text Pipeline */
	[desc reset];
	[vertexdesc reset];
	desc.label = @"pipeline.gui.text";
	desc.vertexFunction = vertText;
	[vertText release];
	desc.fragmentFunction = fragText;
	[fragText release];
	MTLRenderPipelineColorAttachmentDescriptor *colortext;
	colortext = desc.colorAttachments[0];
	colortext.pixelFormat = MTLPixelFormatBGRA8Unorm;
	colortext.blendingEnabled = true;
	colortext.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	colortext.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;

	bufs = desc.vertexBuffers;
	bufs[0].mutability = MTLMutabilityImmutable;
	bufs[16].mutability = MTLMutabilityImmutable;
	bufs[17].mutability = MTLMutabilityImmutable;

	attrs = vertexdesc.attributes;

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

	store->text = [device newRenderPipelineStateWithDescriptor:desc
							     error:nil];

	[desc release];

	ARP_POP();

	return store;
}

void shdr_release(struct shaders *store) {
	[store->background release];
	[store->button release];
	[store->text release];
}

