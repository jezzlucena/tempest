extends Control

## True-ending screen — shown after defeating the Chronolith while the
## Infinity Visor was worn. Unlike the default completion, the Wanderer
## keeps the full kit and the timeline is sealed rather than fractured.

const BG_COLOR := Color(0.03, 0.03, 0.08, 1.0)
const TITLE_COLOR := Color(1.0, 0.92, 0.7, 1.0)
const TEXT_COLOR := Color(0.9, 0.85, 0.75, 1.0)
const DIM_COLOR := Color(0.55, 0.5, 0.45, 0.6)
const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.4, 1.0)
const KNOT_COLOR := Color(1.0, 0.85, 0.4, 1.0)
const KNOT_GLOW := Color(1.0, 0.8, 0.3, 0.18)

var _time: float = 0.0
var selected_index: int = 0
var _input_enabled: bool = false

const MENU_ITEMS := ["Play Again", "Main Menu"]


func _ready() -> void:
	# Longer delay than the standard completion — let the moment land.
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_callback(func() -> void:
		_input_enabled = true
	)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if not event is InputEventKey or not event.pressed:
		return

	if event.keycode == KEY_W or event.keycode == KEY_UP:
		selected_index = (selected_index - 1 + MENU_ITEMS.size()) % MENU_ITEMS.size()
	elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
		selected_index = (selected_index + 1) % MENU_ITEMS.size()
	elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		match selected_index:
			0:  # Play Again
				GameManager.go_to_level(0, 0)
			1:  # Main Menu
				GameManager.go_to_menu()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0

	# Central trefoil knot — three overlapping lobes rotating slowly with a
	# soft glow. The knot grows in over the first two seconds.
	var knot_scale: float = clampf(_time / 2.0, 0.1, 1.0)
	_draw_trefoil(Vector2(cx, cy - 150), 80.0 * knot_scale, _time * 0.6)

	# Title — fades in over 2.5s
	var title_alpha: float = clampf((_time - 0.5) / 2.0, 0.0, 1.0)
	_draw_centered("The loop completes.", Vector2(cx, cy - 30), 36,
		Color(TITLE_COLOR.r, TITLE_COLOR.g, TITLE_COLOR.b, title_alpha))

	# Divider line
	var line_alpha: float = clampf((_time - 1.5) / 1.0, 0.0, 0.6)
	draw_line(Vector2(cx - 160, cy + 5), Vector2(cx + 160, cy + 5),
		Color(0.6, 0.5, 0.3, line_alpha), 1.0)

	# Story text
	var story_alpha: float = clampf((_time - 2.0) / 2.0, 0.0, 0.85)
	var story_color := Color(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, story_alpha)
	_draw_centered("The Visor sees what the Chronolith hid.", Vector2(cx, cy + 35), 16, story_color)
	_draw_centered("Three shards, three eras, one true core.", Vector2(cx, cy + 60), 16, story_color)
	_draw_centered("The shockwave stills itself against the knot.", Vector2(cx, cy + 85), 16, story_color)

	# Stats
	var stats_alpha: float = clampf((_time - 3.0) / 1.5, 0.0, 0.7)
	var stats_color := Color(DIM_COLOR.r, DIM_COLOR.g, DIM_COLOR.b, stats_alpha)
	_draw_centered("The Wanderer walks on with every ability intact.", Vector2(cx, cy + 120), 14, stats_color)

	# Menu
	if _input_enabled:
		var menu_alpha: float = clampf((_time - 4.0) / 1.0, 0.0, 1.0)
		for i in range(MENU_ITEMS.size()):
			var y_pos: float = cy + 175 + i * 35
			var is_selected: bool = (i == selected_index)
			var base_color: Color = HIGHLIGHT_COLOR if is_selected else TEXT_COLOR
			var color := Color(base_color.r, base_color.g, base_color.b, menu_alpha)
			var prefix: String = "> " if is_selected else "  "
			_draw_centered(prefix + MENU_ITEMS[i], Vector2(cx, y_pos), 20, color)
		var hint_color := Color(DIM_COLOR.r, DIM_COLOR.g, DIM_COLOR.b, menu_alpha * 0.7)
		_draw_centered("W/S to navigate, Space to select", Vector2(cx, size.y - 30), 12, hint_color)

	# Gold-flecked particles
	var particle_alpha: float = clampf(_time / 5.0, 0.0, 0.35)
	for i in range(12):
		var phase: float = i * 0.55 + _time * 0.25
		var px: float = cx + sin(phase * 1.2) * 320
		var py: float = cy + cos(phase * 0.75) * 220
		var particle_size: float = 2.0 + sin(phase * 2.3) * 1.2
		draw_circle(Vector2(px, py), particle_size,
			Color(1.0, 0.85, 0.45, particle_alpha * (0.5 + sin(phase) * 0.3)))


## Draw a trefoil-knot silhouette: the parametric curve (2+cos(3t))·(cos(2t), sin(2t))
## traced as a closed polyline, with a soft halo behind it.
func _draw_trefoil(origin: Vector2, radius: float, rotation: float) -> void:
	var points := PackedVector2Array()
	var segments: int = 240
	var scale: float = radius / 3.0
	for i in range(segments + 1):
		var t: float = (float(i) / segments) * TAU
		var r: float = 2.0 + cos(3.0 * t)
		var x: float = r * cos(2.0 * t)
		var y: float = r * sin(2.0 * t)
		var rotated := Vector2(x, y).rotated(rotation) * scale
		points.append(origin + rotated)

	# Halo — wide, dim.
	for i in range(segments):
		draw_line(points[i], points[i + 1], KNOT_GLOW, 14.0)
	# Core line — bright.
	for i in range(segments):
		draw_line(points[i], points[i + 1], KNOT_COLOR, 3.0)
	# Tiny inner ring to anchor the eye.
	draw_circle(origin, radius * 0.1, KNOT_COLOR * Color(1, 1, 1, 0.9))


func _draw_centered(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(pos.x - text_size.x / 2, pos.y + text_size.y / 4), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
