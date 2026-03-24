shader_type canvas_item;

// Era transition effect — chromatic aberration + color wash.
// Apply to a full-screen ColorRect on a CanvasLayer.

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 era_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 center = vec2(0.5);
	vec2 dir = UV - center;
	float dist = length(dir);

	// Chromatic aberration — spread RGB channels
	float aberration = intensity * 0.02;
	float vignette = smoothstep(0.0, 0.7, dist) * intensity;

	// Color wash with era tint
	vec4 tint = era_tint;
	tint.a = intensity * 0.3 * (0.5 + vignette);

	COLOR = tint;
}
