#include <metal_geometric>
#include <metal_math>
#include <metal_matrix>
#include <metal_texture>

using namespace metal;

struct vertdata {
	float3 position [[attribute(0)]];
	float2 texcoords [[attribute(1)]];
	half3 normal [[attribute(2)]];
	uint layer [[attribute(3)]];
};

struct fragdata {
	float4 position [[position]];
	float2 texcoords;
	half3 diffuse;
	uint layer;
};

struct matrices {
	float4x4 persp;
	float4x4 ortho[9];
};

// normalize(-0.3h, -1.0h, -0.5h)
constant half3 lightdir = {-0.2591h, -0.864h, -0.432h};
constant half3 diffuse = {1.0h, 1.0h, 1.0h};

vertex
fragdata vertTerrain(vertdata vert [[stage_in]], constant matrices *mtxs
		[[buffer(0)]]) {
	struct fragdata frag;
	frag.position = mtxs->persp * float4(vert.position, 1.0f);
	frag.texcoords = vert.texcoords;

	const half d = max(dot(vert.normal, -lightdir), 0.0h);
	frag.diffuse = diffuse * d;

	frag.layer = vert.layer;
	return frag;
}

constant half3 ambient = {0.3h, 0.3h, 0.3h};

[[early_fragment_tests]]
fragment
half4 fragTerrain(struct fragdata frag[[stage_in]], texture2d_array<half> tex) {
	constexpr sampler samp(filter::nearest, mip_filter::linear,
			address::repeat, max_anisotropy(10));
	const half4 color = tex.sample(samp, frag.texcoords, frag.layer);

	const half3 c_ambient = color.rgb * ambient;
	const half3 c_diffuse = color.rgb * frag.diffuse;

	return half4(c_ambient + c_diffuse, color.a);
}
