shader_type spatial;

uniform sampler2D surface_noise;
uniform vec4 albedo1: hint_color = vec4(0);
uniform vec4 albedo2: hint_color = vec4(0);

void fragment() {
	float noise = texture(surface_noise, UV).r;
	float mixVal = smoothstep(0.4, 0.6, noise);
	ALBEDO = mix(albedo1.rgb, albedo2.rgb, mixVal);
}