shader_type spatial;

uniform sampler2D surface_noise;
uniform vec4 albedo1: hint_color = vec4(0);
uniform vec4 albedo2: hint_color = vec4(0);

uniform sampler2D font_texture;
uniform int font_texture_columns;
uniform vec2 font_glyph_size;
uniform vec2 font_glyph_padding;

uniform vec2 title_start_uv;
uniform float title_height_uv;

uniform vec4 page_albedo: hint_color = vec4(1);

const float PI = 3.14159265358979323846;

vec3 cover_albedo(vec2 uv) {
	float noise = texture(surface_noise, uv).r;
	float mix_val = smoothstep(0.4, 0.6, noise);
	return mix(albedo1.rgb, albedo2.rgb, mix_val);
}

vec2 rotate(vec2 v, float a) {
	float cosine = cos(a);
	float sine = sin(a);
	return vec2(
		v.x * cosine - sine * v.y,
		v.y * cosine + sine * v.x);
}

float title_alpha(vec2 uv) {
	vec2 tex_size = vec2(textureSize(font_texture, 0));
	vec2 font_glyph_size_uv = font_glyph_size / tex_size;
	vec2 font_padding_uv = font_glyph_padding / tex_size;
		
	vec2 char_uv = rotate((uv - title_start_uv) / title_height_uv, PI);
	if (any(lessThan(char_uv, vec2(0.0))) || char_uv.y > 1.0) {
		return 0.0;
	}

	char_uv *= font_glyph_size_uv.y;
	int char_index = int(char_uv.x/font_glyph_size_uv.x);
	if (char_index > 10) {
		return 0.0;
	}
	int target_char = char_index*4;
	char_uv.x = mod(char_uv.x, font_glyph_size_uv.x);

	vec2 char_pos = vec2(ivec2(target_char % font_texture_columns, target_char / font_texture_columns));
	vec2 char_offset = char_pos * (font_glyph_size_uv + (2.0 * font_padding_uv)) + font_padding_uv;

	float font_alpha = texture(font_texture, char_uv+char_offset).a;
	
	return font_alpha;
}

void fragment() {

	float page_mix = step(UV.x, .5);
	float title_alpha = title_alpha(UV);
	
	vec3 cover_albedo = mix(cover_albedo(UV), vec3(0), smoothstep(0.47, 0.5, title_alpha));
	
	ALBEDO = mix(page_albedo.rgb, cover_albedo, page_mix);
	ROUGHNESS = mix(1.0, 0.9, smoothstep(0.5,0.51, title_alpha));
}