#include <metal_matrix>

using namespace metal;

struct matrices {
	float4x4 persp;
	float4x4 ortho[9];
};

struct outdata {
	float4 position [[position]];
	float2 texcoords;
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
outdata vertBackground(uint vertexID [[vertex_id]], constant matrices *mats
		[[buffer(0)]], constant float2 *verts [[buffer(1)]]) {
	struct outdata data;
	
	float2 pos = verts[vertexID];
	data.position = float4(pos, 0.0f, 1.0f);
	
	pos *= 0.5f / mats->ortho[ANC_BOTTOMLEFT][0].xy;
	data.texcoords = pos;

	return data;
}
