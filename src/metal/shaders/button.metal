#include <metal_matrix>

using namespace metal;

struct guivert {
	float2 position;
	float2 texcoords;
};

struct guiinfo {
	float2 offset;
	uint8_t anchor;
	uint8_t state;
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
		constant matrices *mats [[buffer(0)]], constant guiinfo *items
		[[buffer(1)]], constant guivert *verts [[buffer(2)]]) {
	guivert vert = verts[vertexID];

	guiinfo info = items[instanceID];
	float4 pos = mats->ortho[info.anchor] * float4(vert.position +
			info.offset, 0.0f, 1.0f);
	const float2 curstate = {0.0f, (float)info.state * 0.078125};
	outdata data = {pos, vert.texcoords + curstate};

	return data;
}


