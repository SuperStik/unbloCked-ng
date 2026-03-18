#include <metal_integer>
#include <metal_matrix>
#include <metal_relational>
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
	uchar color [[attribute(3)]];
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

#define ONE_THIRD (1.0h/3.0h)
#define TWO_THIRDS (2.0h/3.0h)

constant half3 colors[16] = {
	half3(0.0h),
	{0.0h, 0.0h, TWO_THIRDS},
	{0.0h, TWO_THIRDS, 0.0h},
	{0.0h, TWO_THIRDS, TWO_THIRDS},
	{TWO_THIRDS, 0.0h, 0.0h},
	{TWO_THIRDS, 0.0h, TWO_THIRDS},
	{1.0h, TWO_THIRDS, 0.0h},
	half3(TWO_THIRDS),
	half3(ONE_THIRD),
	{ONE_THIRD, ONE_THIRD, 1.0h},
	{ONE_THIRD, 1.0h, ONE_THIRD},
	{ONE_THIRD, 1.0h, 1.0h},
	{1.0h, ONE_THIRD, ONE_THIRD},
	{1.0h, ONE_THIRD, 1.0h},
	{1.0h, 1.0h, ONE_THIRD},
	half3(1.0h)
};

vertex
fragdata vertText(uint instanceID [[instance_id]], constant matrices *mats,
		constant float4x4 *trans, vertdata vert[[stage_in]]) {
	uint shift = instanceID & 1;
	half darken = select(0.25h, 1.0h, instanceID & 1);
	float4 pos = float4(vert.position + float2((float)shift), 0.0f, 1.0f);

	fragdata frag;

	frag.position = mats->ortho[ANC_MIDDLE] * *trans * pos;
	frag.texcoords = vert.texcoords;
	frag.color = colors[min((uchar)vert.color, (uchar)0xF)] * darken;
	frag.character = vert.character;

	return frag;
}

[[early_fragment_tests]]
fragment
half4 fragText(fragdata frag [[stage_in]], texture2d_array<half> tex) {
	constexpr sampler samp(mip_filter::nearest);

	half4 color = tex.sample(samp, frag.texcoords, frag.character);
	color.rgb *= frag.color;
	return color;
}
