shader_type spatial;

uniform int surface_style = 0;
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
	for (int octave = 0; octave < 4; octave++) {
		value += value_noise(p) * amplitude;
		amplitude_sum += amplitude;
		p = p * 2.03 + vec3(17.1, 9.2, 13.7);
		amplitude *= 0.5;
	}
	return value / amplitude_sum;
}

float crater_distance(vec3 p) {
	vec3 cell = floor(p);
	vec3 local = fract(p);
	float closest = 2.0;

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = vec3(float(x), float(y), float(z));
				vec3 grid = cell + neighbor;
				vec3 feature = neighbor + vec3(
					hash31(grid),
					hash31(grid + vec3(19.1, 7.7, 3.4)),
					hash31(grid + vec3(4.5, 31.7, 12.3))
				);
				closest = min(closest, length(feature - local));
			}
		}
	}

	return closest;
}

void vertex() {
	local_direction = normalize(VERTEX);
}

void fragment() {
	vec3 direction = normalize(local_direction);
	vec3 seed_offset = vec3(surface_seed * 13.0, surface_seed * 29.0, surface_seed * 47.0);
	float broad_noise = fbm(direction * 7.0 + seed_offset);
	float detail_noise = fbm(direction * 35.0 + seed_offset);
	float relief = 0.7;

	if (surface_style == 0) {
		float distance_to_crater = crater_distance(direction * 15.0 + seed_offset);
		float crater_floor = 1.0 - smoothstep(0.14, 0.39, distance_to_crater);
		float crater_rim = 1.0 - smoothstep(0.015, 0.065, abs(distance_to_crater - 0.44));
		relief = clamp(0.62 + broad_noise * 0.18 + detail_noise * 0.12 - crater_floor * 0.34 + crater_rim * 0.26, 0.22, 1.15);
	} else if (surface_style == 1) {
		float rust = fbm(direction * 6.0 + seed_offset);
		relief = clamp(0.48 + rust * 0.48 + detail_noise * 0.18, 0.28, 1.12);
	} else if (surface_style == 2) {
		float latitude = asin(clamp(direction.y, -1.0, 1.0));
		float turbulence = fbm(direction * 8.0 + seed_offset) - 0.5;
		float bands = 0.5 + 0.5 * sin((latitude + turbulence * 0.18) * 44.0);
		float longitude = atan(direction.z, direction.x);
		float storm_distance = length(vec2((longitude + 0.8) * 0.55, (latitude - 0.18) * 1.8));
		float storm = 1.0 - smoothstep(0.035, 0.12, storm_distance);
		relief = clamp(0.56 + bands * 0.36 + (detail_noise - 0.5) * 0.22 - storm * 0.2, 0.28, 1.12);
	} else {
		float continents = fbm(direction * 5.0 + seed_offset);
		float land = smoothstep(0.47, 0.57, continents);
		float clouds = smoothstep(0.72, 0.86, fbm(direction * 42.0 + seed_offset));
		relief = mix(0.48, 0.82, land) + detail_noise * 0.12 + clouds * 0.2;
	}

	ALBEDO = body_tint.rgb * relief;
	ROUGHNESS = surface_style == 2 ? 0.68 : 0.92;
	METALLIC = 0.0;
}
