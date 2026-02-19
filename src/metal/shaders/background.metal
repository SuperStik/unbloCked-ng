#include <metal_matrix>
#include <metal_texture>

using namespace metal;

struct matrices {
	float4x4 persp;
	float4x4 ortho[9];
};

struct fragdata {
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
fragdata vertBackground(constant matrices *mats, float2 position
		[[attribute(0)]] [[stage_in]]) {
	struct fragdata frag;

	float2 pos = position;
	frag.position = float4(pos, 1.0f, 1.0f);

	float4x4 mat = mats->ortho[ANC_TOPLEFT];
	float2 screen = {mat[0].x, -mat[1].y};
	pos *= 0.03125f / screen;
	frag.texcoords = pos;

	return frag;
}

[[early_fragment_tests]]
fragment
half4 fragBackground(struct fragdata frag[[stage_in]], texture2d<half> tex) {
	constexpr sampler samp(filter::nearest, address::repeat);
	half4 texcolor = tex.sample(samp, frag.texcoords);
	texcolor.rgb *= 0.25h;
	return texcolor;
}
