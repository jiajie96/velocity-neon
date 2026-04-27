shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 grid_color : source_color = vec4(0.0, 0.8, 1.0, 0.3);
uniform vec4 accent_color : source_color = vec4(1.0, 0.0, 0.8, 0.15);
uniform vec4 bg_color : source_color = vec4(0.02, 0.01, 0.05, 1.0);
uniform float grid_spacing = 2.0;
uniform float line_width = 0.04;
uniform float major_every = 5.0;
uniform float major_width = 0.06;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 gp = world_pos.xz;

	// Minor grid
	vec2 grid = abs(fract(gp / grid_spacing - 0.5) - 0.5) * grid_spacing;
	float minor = min(grid.x, grid.y);
	float minor_mask = 1.0 - smoothstep(line_width * 0.5, line_width, minor);

	// Major grid
	float ms = grid_spacing * major_every;
	vec2 mgrid = abs(fract(gp / ms - 0.5) - 0.5) * ms;
	float major = min(mgrid.x, mgrid.y);
	float major_mask = 1.0 - smoothstep(major_width * 0.5, major_width, major);

	// Pulse animation
	float pulse = sin(TIME * 0.4) * 0.1 + 0.9;
	float accent_pulse = sin(TIME * 0.7 + 1.5) * 0.15 + 0.85;

	// Distance fade from camera center
	float dist = length(gp);
	float fade = 1.0 - smoothstep(35.0, 70.0, dist);

	// Combine
	vec3 col = bg_color.rgb;
	col = mix(col, grid_color.rgb * pulse, minor_mask * fade * grid_color.a);
	col = mix(col, accent_color.rgb * accent_pulse, major_mask * fade * accent_color.a);

	ALBEDO = col;
	EMISSION = (grid_color.rgb * minor_mask * grid_color.a + accent_color.rgb * major_mask * accent_color.a * 1.5) * fade * 2.0;
}
