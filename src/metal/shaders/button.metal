struct guivert {
	float2 position;
	half2 texcoords;
};

struct outdata {
	float4 position [[position]];
	half2 texcoords;
};

vertex
outdata vertButton(uint vertexID [[vertex_id]], constant guivert *verts
		[[buffer(1)]]) {
	guivert vert = verts[vertexID];
	outdata data = {float4(vert.position, 0.0f, 1.0f), vert.texcoords};

	return data;
}

[[early_fragment_tests]]
fragment
half4 fragButton(struct outdata in[[stage_in]]) {
	return half4(in.texcoords, 0.0h, 1.0h);
}
