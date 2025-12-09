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
	half3 color;
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
fragdata vertText(uint vertID [[vertex_id]], uint instanceID [[instance_id]],
		constant matrices *mats [[buffer(0)]], vertdata vert
		[[stage_in]]) {
	uint shift = instanceID & 1;
	half darken = (half)shift * 0.75h + 0.25h;
	float4 pos = float4(vert.position + float2((float)shift), 0.0f, 1.0f);

	fragdata frag;

	frag.position = mats->ortho[ANC_MIDDLE] * pos;
	frag.texcoords = vert.texcoords;
	frag.color = half3(1.0h) * darken;
	frag.character = vert.character;

	return frag;
}

[[early_fragment_tests]]
fragment
half4 fragText(fragdata frag [[stage_in]], texture2d_array<half> tex
		[[texture(0)]]) {
	constexpr sampler samp;

	half4 color = tex.sample(samp, frag.texcoords, frag.character);
	color.rgb *= frag.color;
	return color;
}
