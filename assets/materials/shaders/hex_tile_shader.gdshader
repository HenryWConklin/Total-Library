shader_type spatial;

// Unit vector at 60 degrees
const vec2 SIXTY_DEGREES = vec2(0.5, 0.866025404);

varying vec2 globalUV;

uniform float tileSize = 1.0;
uniform float groutFraction: hint_range(0,1) = 0.9;
uniform vec4 tileAlbedo: hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float tileRoughness: hint_range(0,1) = 0.05;
uniform vec4 groutAlbedo: hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float groutRoughness: hint_range(0,1) = 1;
uniform float curveMagnitude = 1;
uniform float curveStart = 0.8;

void vertex() {
	globalUV = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xz;
}



void tiledHexDistance(in vec2 uv, out float hexDist, out vec2 distGrad) {
	vec2 cellSize = SIXTY_DEGREES * 2.0;

	// Every other row has an offset
	vec2 cellA = mod(uv, cellSize) - SIXTY_DEGREES;
	vec2 cellB = mod(uv - SIXTY_DEGREES, cellSize) - SIXTY_DEGREES;

	vec2 cell = dot(cellA, cellA) < dot(cellB, cellB) ? cellA : cellB;

	vec2 xyMirror = abs(cell);
	float diagonalDistance = dot(xyMirror, SIXTY_DEGREES);
	float horizontalDistance = xyMirror.x;
	if (horizontalDistance > diagonalDistance) {
		hexDist = horizontalDistance;
		distGrad = sign(cell) * vec2(1., 0.);
	} else {
		hexDist = diagonalDistance;
		distGrad = sign(cell) * SIXTY_DEGREES;
	}
	hexDist *= 2.;
}

void fragment() {
	vec2 coord = globalUV * tileSize;
	float hexDist;
	vec2 hexDistGrad;
	tiledHexDistance(coord, hexDist, hexDistGrad);
	bool isTile = hexDist < groutFraction;

	float curveInterp = (hexDist - curveStart) / (1. - curveStart);
	vec2 curveGrad = hexDist > curveStart
		? hexDistGrad * (6. * curveInterp * (1. - curveInterp)) * curveMagnitude
		: vec2(0.);
	NORMAL = (INV_CAMERA_MATRIX * vec4(normalize(vec3(curveGrad.x, 1., curveGrad.y)), 0.0)).xyz;

	ALBEDO = (isTile ? tileAlbedo : groutAlbedo).rgb;
	ROUGHNESS = (isTile ? tileRoughness : groutRoughness);
}
