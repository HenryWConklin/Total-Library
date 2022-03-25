shader_type spatial;

uniform sampler2D noise;
uniform float noise_scale_exp = 0;
uniform vec4 albedo: hint_color = vec4(1);
uniform float roughness = 1.0;

varying float noise_scale;

void vertex() {
	noise_scale = exp(noise_scale_exp);
}

void fragment() {
	vec2 scaled_uv = UV * noise_scale;
	NORMALMAP = texture(noise, scaled_uv).xyz;
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
}