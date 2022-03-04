shader_type spatial;

uniform sampler2D surface_noise;
uniform vec4 albedo1: hint_color = vec4(0);
uniform vec4 albedo2: hint_color = vec4(0);

uniform sampler2D font_texture;
uniform uint font_texture_columns;
uniform vec2 font_glyph_size;
uniform vec2 font_glyph_padding;

uniform vec2 title_start_uv;
uniform float title_height_uv;
uniform uint title_bits_per_char;
uniform uint title_num_chars;

uniform vec4 page_base_albedo: hint_color = vec4(1);
uniform sampler2D page1_text_texture;
uniform sampler2D page2_text_texture;
uniform vec2 page1_uv_offset;
uniform vec2 page2_uv_offset;
uniform float page_uv_scale;


uniform uint title1;
uniform uint title2;
uniform uint title3;
uniform uint title4;

const float PI = 3.14159265358979323846;
const uint MANTISSA_BITS = uint(23);

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

float title_alpha(vec2 uv, uvec4 title_bits) {
	vec2 tex_size = vec2(textureSize(font_texture, 0));
	vec2 font_glyph_size_uv = font_glyph_size / tex_size;
	vec2 font_padding_uv = font_glyph_padding / tex_size;

	vec2 char_uv = rotate((uv - title_start_uv) / title_height_uv, PI);
	if (any(lessThan(char_uv, vec2(0.0))) || char_uv.y > 1.0) {
		return 0.0;
	}

	char_uv *= font_glyph_size_uv.y;
	uint char_index = uint(char_uv.x/font_glyph_size_uv.x);
	if (char_index >= title_num_chars) {
		return 0.0;
	}
	uint bit_offset = char_index * title_bits_per_char;
	uint shift = bit_offset % MANTISSA_BITS;

	uint target_char;
	switch(int(bit_offset/MANTISSA_BITS)) {
		case 0:
			target_char = (title_bits.r >> shift) | (title_bits.g << (MANTISSA_BITS - shift));
			break;
		case 1:
			target_char = (title_bits.g >> shift) | (title_bits.b << (MANTISSA_BITS - shift));
			break;
		case 2:
			target_char = (title_bits.b >> shift) | (title_bits.a << (MANTISSA_BITS - shift));
			break;
		case 3:
			target_char = (title_bits.a >> shift);
			break;
		default:
			target_char = uint(0);
			break;
	}

	target_char &= ((uint(1) << title_bits_per_char) - uint(1));

	char_uv.x = mod(char_uv.x, font_glyph_size_uv.x);

	vec2 char_pos = vec2(uvec2(target_char % font_texture_columns, target_char / font_texture_columns));
	vec2 char_offset = char_pos * (font_glyph_size_uv + (2.0 * font_padding_uv)) + font_padding_uv;

	float font_alpha = texture(font_texture, char_uv+char_offset).a;

	return font_alpha;
}

vec3 page_albedo(vec2 uv) {
	const float page_aspect_ratio = 1.5;
	vec2 page_scale = vec2(page_uv_scale, page_uv_scale*page_aspect_ratio);
	vec2 page1_uv = rotate(uv - page1_uv_offset, PI/2.) / page_scale;
	vec2 page2_uv = rotate(uv - page2_uv_offset, PI/2.) / page_scale;
	if (all(greaterThan(page1_uv, vec2(0))) && all(lessThan(page1_uv, vec2(1)))) {
		vec4 page1 = texture(page1_text_texture, page1_uv);
		vec3 page1_albedo = (page1.rgb * page1.a) + (1. - page1.a) * page_base_albedo.rgb;
		return page1_albedo;
	}
	else if (all(greaterThan(page2_uv, vec2(0))) && all(lessThan(page2_uv, vec2(1)))) {
		vec4 page2 = texture(page2_text_texture, page2_uv);
		vec3 page2_albedo = (page2.rgb * page2.a) + (1. - page2.a) * page_base_albedo.rgb;
		return page2_albedo;
	} else {
		return page_base_albedo.rgb;
	}
}

void fragment() {
	float page_mix = step(UV.x, .497);
	float title_alpha = title_alpha(UV, uvec4(title1, title2, title3, title4));

	vec3 cover_albedo = mix(cover_albedo(UV), vec3(0), smoothstep(0.47, 0.5, title_alpha));
	vec3 page_albedo = page_albedo(UV);

	ALBEDO = mix(page_albedo.rgb, cover_albedo, page_mix);
	ROUGHNESS = mix(1.0, 0.9, smoothstep(0.5,0.51, title_alpha));
}
