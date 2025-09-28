#include <metal_matrix>

using namespace metal;

struct guivert {
	float2 position;
	float2 texcoords;
};

struct outdata {
	float4 position [[position]];
	float2 texcoords;
};

struct matrices {
	float4x4 persp;
	float4x4 ortho[9];
};

enum anchor {
	ANC_TOPLEFT,
	ANC_TOPMIDDLE,
	ANC_TOPRIGHT,
	ANC_MIDDLELEFT,
	ANC_MIDDLE,
	ANC_MIDDLERIGHT,
	ANC_BOTTOMLEFT,
	ANC_BOTTOMMIDDLE,
	ANC_BOTTOMRIGHT
};

vertex
outdata vertButton(uint vertexID [[vertex_id]], uint instanceID [[instance_id]],
		constant matrices *mats [[buffer(0)]], constant uint8_t *anchors
		[[buffer(1)]], constant guivert *verts [[buffer(2)]]) {
	guivert vert = verts[vertexID];

	uint8_t anch = anchors[instanceID];
	float4 pos = mats->ortho[anch] * float4(vert.position, 0.0f,
			1.0f);
	outdata data = {pos, vert.texcoords};

	return data;
}


