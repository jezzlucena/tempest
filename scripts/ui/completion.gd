extends Control

## Completion screen — shown after defeating the Chronolith.

const BG_COLOR := Color(0.04, 0.03, 0.07, 1.0)
const TITLE_COLOR := Color(0.7, 0.85, 1.0, 1.0)
const TEXT_COLOR := Color(0.5, 0.6, 0.8, 1.0)
const DIM_COLOR := Color(0.35, 0.4, 0.5, 0.6)
const HIGHLIGHT_COLOR := Color(0.4, 0.9, 0.6, 1.0)

var _time: float = 0.0
var _fade_in: float = 0.0
var selected_index: int = 0
var _input_enabled: bool = false

const MENU_ITEMS := ["Play Again", "Level Select", "Main Menu"]


func _ready() -> void:
	# Delay input so the player doesn't accidentally skip
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(func() -> void:
		_input_enabled = true
	)


func _process(delta: float) -> void:
	_time += delta
	_fade_in = minf(_time / 2.0, 1.0)
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
				GameManager.go_to_level(0)
			1:  # Level Select
				GameManager.go_to_menu()
			2:  # Main Menu
				GameManager.go_to_menu()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0

	# Title — fades in over 2s
	var title_alpha: float = clampf(_time / 2.0, 0.0, 1.0)
	_draw_centered("The Wanderer transcends.", Vector2(cx, cy - 130), 36,
		Color(TITLE_COLOR.r, TITLE_COLOR.g, TITLE_COLOR.b, title_alpha))

	# Divider line
	var line_alpha: float = clampf((_time - 1.0) / 1.0, 0.0, 0.5)
	draw_line(Vector2(cx - 120, cy - 85), Vector2(cx + 120, cy - 85),
		Color(0.4, 0.5, 0.7, line_alpha), 1.0)

	# Story text — fades in after 1s
	var story_alpha: float = clampf((_time - 1.0) / 2.0, 0.0, 0.8)
	var story_color := Color(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, story_alpha)
	_draw_centered("Every staircase now leads somewhere different.", Vector2(cx, cy - 55), 16, story_color)
	_draw_centered("The impossible architecture remembers your passage.", Vector2(cx, cy - 30), 16, story_color)

	# Stats area — fades in after 2s
	var stats_alpha: float = clampf((_time - 2.0) / 1.5, 0.0, 0.7)
	var stats_color := Color(DIM_COLOR.r, DIM_COLOR.g, DIM_COLOR.b, stats_alpha)
	_draw_centered("Gravity bent. Time fractured. Eras bridged.", Vector2(cx, cy + 20), 14, stats_color)
	_draw_centered("The Chronolith is silent.", Vector2(cx, cy + 45), 14, stats_color)

	# Menu — fades in after 3s
	if _input_enabled:
		var menu_alpha: float = clampf((_time - 3.0) / 1.0, 0.0, 1.0)
		for i in range(MENU_ITEMS.size()):
			var y_pos: float = cy + 100 + i * 35
			var is_selected: bool = (i == selected_index)
			var base_color: Color = HIGHLIGHT_COLOR if is_selected else TEXT_COLOR
			var color := Color(base_color.r, base_color.g, base_color.b, menu_alpha)
			var prefix: String = "> " if is_selected else "  "
			_draw_centered(prefix + MENU_ITEMS[i], Vector2(cx, y_pos), 20, color)

		var hint_color := Color(DIM_COLOR.r, DIM_COLOR.g, DIM_COLOR.b, menu_alpha * 0.7)
		_draw_centered("W/S to navigate, Space to select", Vector2(cx, size.y - 30), 12, hint_color)

	# Subtle animated particles (floating geometric shapes)
	var particle_alpha: float = clampf(_time / 4.0, 0.0, 0.3)
	for i in range(8):
		var phase: float = i * 0.8 + _time * 0.3
		var px: float = cx + sin(phase * 1.3) * 250
		var py: float = cy + cos(phase * 0.9) * 180
		var particle_size: float = 3.0 + sin(phase * 2.0) * 1.5
		draw_circle(Vector2(px, py), particle_size,
			Color(0.5, 0.6, 0.9, particle_alpha * (0.5 + sin(phase) * 0.3)))


func _draw_centered(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(pos.x - text_size.x / 2, pos.y + text_size.y / 4), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
