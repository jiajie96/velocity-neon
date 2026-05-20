shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 color : source_color = vec4(0.2, 0.7, 0.9, 0.8);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float ring_width : hint_range(0.01, 0.5) = 0.15;
uniform float edge_softness : hint_range(0.01, 0.3) = 0.08;
uniform float distortion_strength : hint_range(0.0, 0.3) = 0.05;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);

	// Ring mask — expanding ring with soft inner and outer edges
	float ring_outer = progress;
	float ring_inner = max(0.0, progress - ring_width);

	float outer_mask = 1.0 - smoothstep(ring_outer - edge_softness, ring_outer, dist);
	float inner_mask = smoothstep(ring_inner, ring_inner + edge_softness, dist);
	float ring = outer_mask * inner_mask;

	// Fade out as the ring expands
	float fade = 1.0 - progress * progress;

	// Slight energy concentration at the leading edge
	float edge_glow = smoothstep(ring_outer - ring_width * 0.3, ring_outer, dist) * outer_mask;

	vec3 final_color = color.rgb * (1.0 + edge_glow * 2.0);
	float final_alpha = ring * fade * color.a;

	ALBEDO = final_color;
	EMISSION = final_color * (1.0 + edge_glow * 3.0);
	ALPHA = final_alpha;
}
