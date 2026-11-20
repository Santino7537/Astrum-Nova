shader_type spatial;
render_mode unshaded;

uniform float surface_seed = 0.0;
uniform vec4 body_tint : source_color = vec4(1.0);

varying vec3 local_direction;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);

	float n000 = hash31(cell);
	float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));

	float x00 = mix(n000, n100, local.x);
	float x10 = mix(n010, n110, local.x);
	float x01 = mix(n001, n101, local.x);
	float x11 = mix(n011, n111, local.x);
	return mix(mix(x00, x10, local.y), mix(x01, x11, local.y), local.z);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float amplitude_sum = 0.0;
	for (int octave = 0; octave < 5; octave++) {
		value += value_noise(p) * amplitude;
		amplitude_sum += amplitude;
		p = p * 2.03 + vec3(17.1, 9.2, 13.7);
		amplitude *= 0.5;
	}
	return value / amplitude_sum;
}

void vertex() {
	local_direction = normalize(VERTEX);
}

void fragment() {
	vec3 direction = normalize(local_direction);
	vec3 seed_offset = vec3(surface_seed * 13.0, surface_seed * 29.0, surface_seed * 47.0);
	float plasma = fbm(direction * 8.0 + seed_offset);
	float granulation = fbm(direction * 38.0 + seed_offset + vec3(0.0, TIME * 0.08, 0.0));
	float hot_cells = smoothstep(0.38, 0.76, granulation + (plasma - 0.5) * 0.35);
	float relief = clamp(0.52 + plasma * 0.3 + hot_cells * 0.52, 0.3, 1.35);
	vec3 surface = body_tint.rgb * relief;

	ALBEDO = surface;
	EMISSION = surface * 3.0;
}
