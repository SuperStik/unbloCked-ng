#include <metal_texture>

using namespace metal;

struct vertdata {
	float3 position [[attribute(0)]];
	float2 texcoords [[attribute(1)]];
};

struct fragdata {
	float4 position [[position]];
	float2 texcoords;
};

vertex
fragdata vertGeneric(struct vertdata vert [[stage_in]]) {
	 fragdata frag = {float4(vert.position, 1.0f), vert.texcoords};
	 return frag;
}

[[early_fragment_tests]]
fragment
half4 fragGeneric(struct fragdata frag [[stage_in]], texture2d<half> tex
		[[texture(0)]]) {
	constexpr sampler samp(filter::nearest, mip_filter::nearest,
			address::repeat);
	return tex.sample(samp, frag.texcoords);
}
