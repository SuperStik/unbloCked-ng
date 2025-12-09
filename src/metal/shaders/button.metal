#include <metal_matrix>

using namespace metal;

struct vertdata {
	float2 position [[attribute(0)]];
	float2 texcoords [[attribute(1)]];
	float2 offset [[attribute(2)]];
	uint8_t anchor [[attribute(3)]];
	uint8_t state [[attribute(4)]];
};

struct fragdata {
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
fragdata vertButton(constant matrices *mats [[buffer(0)]], vertdata vert
		[[stage_in]]) {
	float4 pos = mats->ortho[vert.anchor] * float4(vert.position +
			vert.offset, 0.0f, 1.0f);

	const float2 curstate = {0.0f, (float)vert.state * 0.078125};
	fragdata data = {pos, vert.texcoords + curstate};

	return data;
}


