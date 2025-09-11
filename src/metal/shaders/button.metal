#include <metal_matrix>
using namespace metal;

struct guivert {
	float2 position;
	half2 texcoords;
};

struct outdata {
	float4 position [[position]];
	half2 texcoords;
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

[[early_fragment_tests]]
fragment
half4 fragButton(struct outdata in[[stage_in]]) {
	return half4(in.texcoords, 0.0h, 1.0h);
}
