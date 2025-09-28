#include <metal_texture>

using namespace metal;

struct outdata {
	float4 position [[position]];
	float2 texcoords;
};

[[early_fragment_tests]]
fragment
half4 fragGeneric(struct outdata in[[stage_in]], texture2d<half> tex
		[[texture(0)]]) {
	constexpr sampler samp(filter::nearest, address::repeat);
	return tex.sample(samp, in.texcoords);
}
