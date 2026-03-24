shader_type canvas_item;

// Dilation bubble visual — rippling distortion with blue tint.
// Applied to the dilation field's visual layer.

uniform float life_ratio : hint_range(0.0, 1.0) = 0.0;
uniform float radius_norm : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 center = vec2(0.5);
	float dist = distance(UV, center) / radius_norm;

	// Circular fade
	float edge = smoothstep(1.0, 0.8, dist);
	float inner = smoothstep(0.0, 0.3, dist);

	// Ripple
	float ripple = sin(dist * 20.0 - TIME * 3.0) * 0.5 + 0.5;
	ripple *= edge * inner;

	// Blue tint that fades with lifetime
	float fade = 1.0 - life_ratio;
	vec4 col = vec4(0.3, 0.5, 0.9, 0.15 * edge * fade + 0.05 * ripple * fade);

	COLOR = col;
}
