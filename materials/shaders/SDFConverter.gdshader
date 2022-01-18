shader_type canvas_item;
render_mode blend_disabled;

uniform int sdf_range = 16;
uniform vec4 transparent_color: hint_color = vec4(0,0,0,1);


void fragment() {
	ivec2 src_pos = ivec2(UV / TEXTURE_PIXEL_SIZE);
	vec4 src_color = texelFetch(TEXTURE, src_pos, 0);
	bool src_outside = (src_color.rgb == transparent_color.rgb);
	vec4 dest_color;
	// Big number, INF would work better
	int min_dist = 2147483647;
	for (int i = -sdf_range; i <= sdf_range; i++) {
		for (int j = -sdf_range; j <= sdf_range; j++) {
			vec4 color = texelFetch(TEXTURE, src_pos + ivec2(i, j), 0);
			bool outside = (color.rgb == transparent_color.rgb);
			if (outside != src_outside) {
				min_dist = min(min_dist, i*i + j*j);
			}
		}
	}
	vec4 out_color;
	float alpha = sqrt(float(min_dist));
	if (src_outside) {
		alpha = -alpha;
	} 
	alpha /= float(sdf_range);
	alpha = clamp((alpha + 1.) / 2., 0., 1.);
	COLOR = vec4(1., 1., 1., alpha);
}