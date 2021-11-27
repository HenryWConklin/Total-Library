// Exponent of 2^0
const int FLOAT_FIXED_BITS = 0x3F800000;
// Mantissa
const int FLOAT_RAND_BITS = 0x007FFFFF;

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
int hash( int x ) {
    x += ( x << 10);
    x = x ^ ( x >>  6);
    x += ( x <<  3);
    x = x ^ ( x >> 11);
    x += ( x << 15);
    return x;
}



// Random value in range [0,1)
float random(int seed) {
	int rand = hash(seed);
	return intBitsToFloat((rand & FLOAT_RAND_BITS) | FLOAT_FIXED_BITS) - 1.;
}

// Random vector on unit circle
vec2 randomGradient(ivec2 p) {
	return normalize(vec2(
		random(p.x * 123 + p.y * 456), 
		random(789*p.x + 987*p.y)
	) * 2. - 1.);
}

float noise( in vec2 p )
{
    ivec2 i = ivec2(floor( p ));
     vec2 f =       fract( p );

	vec2 u = smoothstep(0., 1., f); // feel free to replace by a quintic smoothstep instead
//	return dot(randomGradient(i), f);
    return mix( mix( dot( randomGradient( i+ivec2(0,0) ), f-vec2(0.0,0.0) ), 
                     dot( randomGradient( i+ivec2(1,0) ), f-vec2(1.0,0.0) ), u.x),
                mix( dot( randomGradient( i+ivec2(0,1) ), f-vec2(0.0,1.0) ), 
                     dot( randomGradient( i+ivec2(1,1) ), f-vec2(1.0,1.0) ), u.x), u.y);
}
