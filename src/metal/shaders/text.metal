#include <metal_matrix>
#include <metal_texture>

using namespace metal;

struct matrices {
	float4x4 persp;
	float4x4 ortho[9];
};

struct vertdata {
	float2 position [[attribute(0)]];
	float2 texcoords [[attribute(1)]];
	uchar character [[attribute(2)]];
};

struct fragdata {
	float4 position [[position]];
	float2 texcoords;
	uchar character;
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
fragdata vertText(uint vertID [[vertex_id]], constant matrices *mats
		[[buffer(0)]], vertdata vert [[stage_in]]) {
	fragdata frag;

	frag.position = float4(vert.position, 0.0f, 1.0f);
	frag.texcoords = vert.texcoords;
	frag.character = vert.character;

	return frag;
}

fragment
half4 fragText(fragdata frag [[stage_in]], texture2d_array<half> tex
		[[texture(0)]]) {
	constexpr sampler samp;

	return tex.sample(samp, frag.texcoords, frag.character);
}
