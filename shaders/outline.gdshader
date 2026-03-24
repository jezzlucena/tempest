shader_type canvas_item;

// Cel-shaded outline shader — thick black edges on geometry.
// Apply to CanvasGroup or individual sprites.

uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.9);

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	if (col.a < 0.1) {
		// Check neighbors for edge detection
		float a = 0.0;
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;

		a += texture(TEXTURE, UV + vec2(-size.x, 0)).a;
		a += texture(TEXTURE, UV + vec2(size.x, 0)).a;
		a += texture(TEXTURE, UV + vec2(0, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(0, size.y)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
		a += texture(TEXTURE, UV + vec2(size.x, size.y)).a;

		if (a > 0.0) {
			COLOR = outline_color;
		} else {
			COLOR = col;
		}
	} else {
		COLOR = col;
	}
}
