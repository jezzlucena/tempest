shader_type canvas_item;

// Escher-style tessellation pattern that morphs between eras.
// morph: 0.0 = Past (warm, geometric), 0.5 = Present (neutral), 1.0 = Future (alien)
// Apply to background ColorRect or floor visuals.

uniform float morph : hint_range(0.0, 1.0) = 0.5;
uniform float scale : hint_range(1.0, 20.0) = 8.0;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.15;

// Past colors: warm sepia
const vec3 PAST_A = vec3(0.45, 0.38, 0.25);
const vec3 PAST_B = vec3(0.55, 0.45, 0.3);

// Present colors: muted gray
const vec3 PRESENT_A = vec3(0.18, 0.18, 0.22);
const vec3 PRESENT_B = vec3(0.25, 0.25, 0.3);

// Future colors: cool blue-violet
const vec3 FUTURE_A = vec3(0.15, 0.18, 0.35);
const vec3 FUTURE_B = vec3(0.22, 0.25, 0.45);

float hex_pattern(vec2 p) {
	p = abs(p);
	return max(p.x + p.y * 0.577, p.y * 1.154);
}

void fragment() {
	float t = TIME * scroll_speed + time_offset;
	vec2 uv = UV * scale + vec2(t * 0.3, t * 0.1);

	// Hexagonal tessellation
	vec2 hex_uv = uv;
	hex_uv.x += step(1.0, mod(floor(hex_uv.y), 2.0)) * 0.5;
	vec2 cell = floor(hex_uv);
	vec2 local = fract(hex_uv) - 0.5;

	float hex = hex_pattern(local);
	float edge = smoothstep(0.45, 0.5, hex);

	// Morph the pattern complexity
	float pattern = mix(
		sin(cell.x * 3.0 + cell.y * 2.0) * 0.5 + 0.5,  // Simple (Past)
		sin(cell.x * 7.0 + cell.y * 5.0 + t) * 0.5 + 0.5, // Complex (Future)
		morph
	);

	// Color interpolation across eras
	vec3 color_a = mix(PAST_A, mix(PRESENT_A, FUTURE_A, clamp((morph - 0.5) * 2.0, 0.0, 1.0)), clamp(morph * 2.0, 0.0, 1.0));
	vec3 color_b = mix(PAST_B, mix(PRESENT_B, FUTURE_B, clamp((morph - 0.5) * 2.0, 0.0, 1.0)), clamp(morph * 2.0, 0.0, 1.0));

	vec3 col = mix(color_a, color_b, pattern);
	col = mix(col, col * 0.6, edge); // Darken edges

	COLOR = vec4(col, 0.7);
}
