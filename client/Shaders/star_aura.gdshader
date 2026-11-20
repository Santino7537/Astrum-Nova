shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 aura_color : source_color = vec4(1.0, 0.75, 0.4, 1.0);
uniform float aura_strength = 1.4;
uniform float aura_opacity = 0.55;

void vertex() {
	vec3 camera_right = INV_VIEW_MATRIX[0].xyz;
	vec3 camera_up = INV_VIEW_MATRIX[1].xyz;
	vec3 world_center = MODEL_MATRIX[3].xyz;
	vec3 world_vertex = world_center + camera_right * VERTEX.x + camera_up * VERTEX.y;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world_vertex, 1.0);
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float radius = length(centered_uv);
	if (radius >= 1.0) {
		discard;
	}

	float angle = atan(centered_uv.y, centered_uv.x);
	float rays = 0.92 + 0.08 * sin(angle * 34.0 + 2.0 * sin(angle * 7.0 + TIME * 0.18));
	float inner_fade = smoothstep(0.25, 0.4, radius);
	float outer_fade = 1.0 - smoothstep(0.72, 1.0, radius);
	float radial_glow = exp(-radius * 2.8) * inner_fade * outer_fade * rays;
	ALBEDO = aura_color.rgb;
	EMISSION = aura_color.rgb * aura_strength;
	ALPHA = radial_glow * aura_opacity;
}
