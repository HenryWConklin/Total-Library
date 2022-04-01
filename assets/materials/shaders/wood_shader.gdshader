/*
	Modified from:
	https://godotshaders.com/shader/procedural-grain-wood-shader/
	木目シェーダー by あるる（きのもと 結衣）
	Grain Shader by Yui Kinomoto @arlez80

	MIT License
*/
shader_type spatial;

uniform vec4 light_color : hint_color = vec4( 0.952, 0.858, 0.749, 1.0 );
uniform vec4 dark_color : hint_color = vec4( 0.749, 0.619, 0.490, 1.0 );

uniform float roughness = 1;
uniform float subsurface_scattering = 0;

// Spacing between rings
uniform float ring_scale = 4.4;
uniform float wave_scale = 8.454;
uniform float random_scale = 4.6;
// Fuzzy noise around ring boundaries
uniform float noise_scale = 0.03;
// Grain orientation as euler angles in radians
uniform vec3 grain_direction;

varying vec2 grain_uv;


vec2 random( vec2 pos )
{
	return fract(
		sin(
			vec2(
				dot(pos, vec2(12.9898,78.233))
			,	dot(pos, vec2(-148.998,-65.233))
			)
		) * 43758.5453
	);
}

float value_noise( vec2 pos )
{
	vec2 p = floor( pos );
	vec2 f = fract( pos );

	float v00 = random( p + vec2( 0.0, 0.0 ) ).x;
	float v10 = random( p + vec2( 1.0, 0.0 ) ).x;
	float v01 = random( p + vec2( 0.0, 1.0 ) ).x;
	float v11 = random( p + vec2( 1.0, 1.0 ) ).x;

	vec2 u = f * f * ( 3.0 - 2.0 * f );

	return mix( mix( v00, v10, u.x ), mix( v01, v11, u.x ), u.y );
}

void vertex() {
	vec3 c = cos(grain_direction);
	vec3 s = sin(grain_direction);
	// Transposed euler angles matrix, same as inverse. Rotates the grain direction vector to (1,0,0)
	// so we can project vertex position to a UV
	mat3 grain_euler = mat3(
		vec3(c.x, -c.z * s.y, s.y * s.z),
		vec3(c.x * s.y, c.x * c.y * c.z - s.x * s.z, -c.z * s.x - c.x * c.y * s.z),
		vec3(s.x * s.y, c.x * s.z + c.y * c.z * s.x, c.x * c.z - c.y * s.x * s.z)
	);
	// Orthographic project of vertex position along the grain_direction vector
	grain_uv = (grain_euler * VERTEX).yz;
}

void fragment( )
{
	vec2 shift_uv = grain_uv;
	shift_uv.x += value_noise( grain_uv * random_scale );
	//shift_uv += random(grain_uv) * noise_scale;
	float x = shift_uv.x + sin( shift_uv.y * wave_scale );
	float f = mod( x * ring_scale + random( grain_uv ).x * noise_scale, 1.0 );
	//float f = fract(x * ring_scale);

	ALBEDO = mix( light_color, dark_color, f ).rgb;
	ROUGHNESS = roughness;
	SSS_STRENGTH = subsurface_scattering;
}
