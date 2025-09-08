#include <metal_geometric>
#include <metal_math>
#include <metal_matrix>
#include <metal_pack>
#include <metal_texture>

using namespace metal;

struct vertexdata {
	packed_float3 position;
	half2 texcoords;
	packed_uchar3 normal;
	uchar layer;
};

struct outdata {
	float4 position [[position]];
	half3 diffuse;
	half2 texcoords;
	uchar layer;
};

struct transform {
	float4x4 projection;
	float4x4 view;
};

// normalize(-0.3h, -1.0h, -0.5h)
constant half3 lightdir = {-0.2591h, -0.864h, -0.432h};
constant half3 diffuse = {1.0h, 1.0h, 1.0h};

vertex
outdata vertTerrain(uint vertexID [[vertex_id]], constant vertexdata *verts
		[[buffer(0)]], constant transform *trans [[buffer(1)]]) {
	struct outdata out;
	struct vertexdata vert = verts[vertexID];
	struct transform tr = trans[0];
	out.position = tr.projection * tr.view * float4(vert.position, 1.0f);
	out.texcoords = vert.texcoords;

	/* apparently macOS hates scalar 8 bit unsigned normalized ints */
	uchar4 normalext = uchar4(vert.normal, 0);
	uint normalint = as_type<uint>(normalext);

	half3 normal = unpack_unorm4x8_to_half(normalint).xyz;
	const half d = max(dot(normal, -lightdir), 0.0h);
	out.diffuse = diffuse * d;

	out.layer = vert.layer;
	return out;
}

constant half3 ambient = {0.3h, 0.3h, 0.3h};

[[early_fragment_tests]]
fragment
half4 fragTerrain(struct outdata in[[stage_in]], texture2d_array<half> tex
		[[texture(0)]]) {
	constexpr sampler samp(filter::nearest, mip_filter::linear,
			address::repeat, max_anisotropy(10));
	const half4 color = tex.sample(samp, float2(in.texcoords), in.layer);
	const half3 c_ambient = color.rgb * ambient;
	const half3 c_diffuse = color.rgb * in.diffuse;
	return half4(c_ambient + c_diffuse, color.a);
}
