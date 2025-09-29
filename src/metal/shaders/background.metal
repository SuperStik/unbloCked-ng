#include <metal_matrix>
#include <metal_texture>

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
	data.position = float4(pos, 1.0f, 1.0f);

	float4x4 mat = mats->ortho[ANC_TOPLEFT];
	float2 screen = {mat[0].x, -mat[1].y};
	pos *= 0.03125f / screen;
	data.texcoords = pos;

	return data;
}

[[early_fragment_tests]]
fragment
half4 fragBackground(struct outdata in[[stage_in]], texture2d<half> tex
		[[texture(0)]]) {
	constexpr sampler samp(filter::nearest, address::repeat);
	half4 texcolor = tex.sample(samp, in.texcoords);
	texcolor.rgb *= 0.25h;
	return texcolor;
}
