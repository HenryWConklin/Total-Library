shader_type spatial;

const float PI = 3.14159265358979323846;

uniform float width;
uniform float rotation;
uniform vec2 page_end;
uniform vec2 curve_control;

uniform vec4 page_base_albedo: hint_color;
uniform sampler2D front_page;
uniform sampler2D back_page;
uniform vec2 page1_uv_offset;
uniform vec2 page2_uv_offset;
uniform vec2 page_uv_scale;
uniform float page_uv_correction;


void vertex() {
	vec3 local_vertex = VERTEX;
	local_vertex.x += width / 2.;
	float t = local_vertex.x / width;
	local_vertex.xz = ((2. * (1. - t) * t) * curve_control) + ((t * t) * page_end);
	vec2 xz_tangent = (2. * page_end - 4. * curve_control) * t + 2. * curve_control;
	NORMAL = normalize(vec3(-xz_tangent.y, 0., xz_tangent.x));
	NORMAL = VERTEX.z > 0. ? NORMAL : -NORMAL;
	VERTEX = local_vertex + vec3(width / 2., 0, 0);
}

vec2 rotate(vec2 v, float a) {
	float cosine = cos(a);
	float sine = sin(a);
	return vec2(
			v.x * cosine - sine * v.y,
			v.y * cosine + sine * v.x);
}

vec3 page_albedo(vec2 uv) {
	vec2 page1_uv = (uv - page1_uv_offset) / page_uv_scale;
	vec2 page2_uv = (uv - page2_uv_offset) / page_uv_scale;

	if (all(greaterThan(page1_uv, vec2(0))) && all(lessThan(page1_uv, vec2(1)))) {
		page1_uv.x = pow(page1_uv.x, page_uv_correction);
		vec4 page1 = texture(back_page, page1_uv);
		vec3 page1_albedo = (page1.rgb * page1.a) + (1. - page1.a) * page_base_albedo.rgb;
		return page1_albedo;
	}
	else if (all(greaterThan(page2_uv, vec2(0))) && all(lessThan(page2_uv, vec2(1)))) {
		page2_uv.x = pow(page2_uv.x, 1./page_uv_correction);
		vec4 page2 = texture(front_page, page2_uv);
		vec3 page2_albedo = (page2.rgb * page2.a) + (1. - page2.a) * page_base_albedo.rgb;
		return page2_albedo;
	} else {
		return page_base_albedo.rgb;
	}
}

void fragment() {
	ALBEDO = page_albedo(UV);
//	ALPHA=.5;
}