#include <metal_matrix>
using namespace metal;

struct guivert {
	float2 position;
	half2 texcoords;
};

struct outdata {
	float4 position [[position]];
	half2 texcoords;
};

struct matrices {
	float4x4 ortho;
	float4x4 persp;
};

vertex
outdata vertButton(uint vertexID [[vertex_id]], constant matrices *mats
		[[buffer(0)]], constant guivert *verts [[buffer(1)]]) {
	guivert vert = verts[vertexID];
	float4 pos = mats->ortho * float4(vert.position, 0.0f, 1.0f);
	outdata data = {pos, vert.texcoords};

	return data;
}

[[early_fragment_tests]]
fragment
half4 fragButton(struct outdata in[[stage_in]]) {
	return half4(in.texcoords, 0.0h, 1.0h);
}
