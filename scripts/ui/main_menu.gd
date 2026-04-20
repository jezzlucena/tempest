extends Control

## Main menu — title, level select, and controls screen.

enum Screen { TITLE, LEVELS, CONTROLS }

var current_screen: Screen = Screen.TITLE
var selected_index: int = 0

const BG_COLOR := Color(0.08, 0.07, 0.1, 1.0)
const TEXT_COLOR := Color(0.6, 0.7, 0.9, 0.9)
const TITLE_COLOR := Color(0.7, 0.85, 1.0, 1.0)
const HIGHLIGHT_COLOR := Color(0.4, 0.9, 0.6, 1.0)
const DIM_COLOR := Color(0.4, 0.45, 0.55, 0.6)

## Flat list of (world, level, label) tuples for the level-select screen.
const LEVEL_ENTRIES := [
	[0, 0, "W0-1 — The Ascending Ruin"],
	[0, 1, "W0-2 — The Fractured Gallery"],
	[0, 2, "W0-3 — The Chronolith"],
	[1, 0, "W1-1 — The Still Plaza"],
	[1, 1, "W1-2 — Three Tier Tempo"],
	[1, 2, "W1-3 — Sentry Gate"],
	[2, 0, "W2-1 — The Rising Stair"],
	[2, 1, "W2-2 — The Narrow Shaft"],
	[2, 2, "W2-3 — The Wall Crawler"],
	[3, 0, "W3-1 — The Ceiling Loop"],
	[3, 1, "W3-2 — The Inverted Corridor"],
	[3, 2, "W3-3 — The Tumbler"],
	[4, 0, "W4-1 — Bullet Storm Gallery"],
	[4, 1, "W4-2 — Racing Platforms"],
	[4, 2, "W4-3 — The Phantom"],
	[5, 0, "W5-1 — The Stacked Archive"],
	[5, 1, "W5-2 — The Shifting Halls"],
	[5, 2, "W5-3 — The Archivist"],
]

var title_menu: Array = []

const CONTROLS := [
	["A / D or Left / Right", "Move left / right"],
	["Space / W / Up", "Jump (also wall-jump)"],
	["Q / E", "Rotate gravity left / right"],
	["Right Click", "Hold to aim, release to cast time dilation field"],
	["Shift + Left", "Era shift to earlier era"],
	["Shift + Right", "Era shift to later era"],
	["", ""],
	["Esc", "Return to menu (from any level)"],
]

var _time: float = 0.0

## Level-select scrolling — the list is always anchored so the selected
## row sits at the centre of the screen. _levels_scroll is the animated
## current scroll position (px). Snaps on screen entry, lerps on navigation.
const LEVEL_ROW_HEIGHT: float = 45.0
const LEVEL_FADE_RANGE: float = 260.0   # px either side of centre where rows fully visible
const LEVEL_FADE_FLOOR: float = 0.18    # minimum alpha for far rows
const LEVEL_SCROLL_SMOOTHING: float = 14.0
var _levels_scroll: float = 0.0


func _ready() -> void:
	_rebuild_menu()


func _rebuild_menu() -> void:
	title_menu = []
	if GameManager.has_save():
		title_menu.append("Continue")
	title_menu.append("New Game")
	title_menu.append("Level Select")
	title_menu.append("Controls")
	selected_index = 0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

	if current_screen == Screen.LEVELS:
		# Smoothly lerp the visible scroll toward the row for the current
		# selection. Frame-rate-independent blend via exp smoothing.
		var target: float = float(selected_index) * LEVEL_ROW_HEIGHT
		var t: float = 1.0 - exp(-delta * LEVEL_SCROLL_SMOOTHING)
		_levels_scroll = lerp(_levels_scroll, target, t)

	if Input.is_action_just_pressed("ui_menu"):
		if current_screen != Screen.TITLE:
			current_screen = Screen.TITLE
			_rebuild_menu()
			return


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match current_screen:
		Screen.TITLE:
			_handle_title_input(event)
		Screen.LEVELS:
			_handle_levels_input(event)
		Screen.CONTROLS:
			_handle_controls_input(event)


func _handle_title_input(event: InputEventKey) -> void:
	if event.keycode == KEY_W or event.keycode == KEY_UP:
		selected_index = (selected_index - 1 + title_menu.size()) % title_menu.size()
	elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
		selected_index = (selected_index + 1) % title_menu.size()
	elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		var choice: String = title_menu[selected_index]
		match choice:
			"Continue":
				GameManager.continue_game()
			"New Game":
				GameManager.go_to_level(0, 0)
			"Level Select":
				current_screen = Screen.LEVELS
				selected_index = 0
				_levels_scroll = float(selected_index) * LEVEL_ROW_HEIGHT
			"Controls":
				current_screen = Screen.CONTROLS
				selected_index = 0


func _handle_levels_input(event: InputEventKey) -> void:
	if event.keycode == KEY_W or event.keycode == KEY_UP:
		selected_index = (selected_index - 1 + LEVEL_ENTRIES.size()) % LEVEL_ENTRIES.size()
	elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
		selected_index = (selected_index + 1) % LEVEL_ENTRIES.size()
	elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		var entry: Array = LEVEL_ENTRIES[selected_index]
		GameManager.go_to_level(int(entry[0]), int(entry[1]))
	elif event.keycode == KEY_ESCAPE:
		current_screen = Screen.TITLE
		selected_index = 0


func _handle_controls_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		current_screen = Screen.TITLE
		selected_index = title_menu.find("Controls")


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	match current_screen:
		Screen.TITLE:
			_draw_title()
		Screen.LEVELS:
			_draw_levels()
		Screen.CONTROLS:
			_draw_controls()


func _draw_title() -> void:
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0

	# Title
	var pulse := sin(_time * 2.0) * 0.1 + 0.9
	_draw_centered_text("TEMPEST", Vector2(cx, cy - 120), 48, TITLE_COLOR * Color(1, 1, 1, pulse))
	_draw_centered_text("Where gravity bends and time fractures", Vector2(cx, cy - 70), 14, DIM_COLOR)

	# Menu items
	for i in range(title_menu.size()):
		var y_pos: float = cy + i * 40
		var color: Color = HIGHLIGHT_COLOR if i == selected_index else TEXT_COLOR
		var prefix: String = "> " if i == selected_index else "  "
		_draw_centered_text(prefix + title_menu[i], Vector2(cx, y_pos), 22, color)

	_draw_centered_text("W/S to navigate, Space to select", Vector2(cx, size.y - 40), 12, DIM_COLOR)


func _draw_levels() -> void:
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0

	# Title and footer are fixed to the viewport; the list scrolls between them.
	var title_y: float = 80.0
	var footer_y: float = size.y - 40.0
	_draw_centered_text("LEVEL SELECT", Vector2(cx, title_y), 32, TITLE_COLOR)

	# Define a vertical band the list renders into. Rows outside are clipped
	# by fade-to-zero so the list feels like a focused slot-reel.
	var band_top: float = title_y + 40.0
	var band_bottom: float = footer_y - 30.0

	var total: int = LEVEL_ENTRIES.size()
	for i in range(total):
		var base_y: float = float(i) * LEVEL_ROW_HEIGHT
		var y_pos: float = cy + (base_y - _levels_scroll)
		if y_pos < band_top - LEVEL_ROW_HEIGHT or y_pos > band_bottom + LEVEL_ROW_HEIGHT:
			continue

		# Fade based on distance from centre; the selected row (at cy) is
		# fully opaque, and rows toward the band edges dim to LEVEL_FADE_FLOOR.
		var dist: float = abs(y_pos - cy)
		var fade: float = clampf(1.0 - dist / LEVEL_FADE_RANGE, LEVEL_FADE_FLOOR, 1.0)
		var base_color: Color = HIGHLIGHT_COLOR if i == selected_index else TEXT_COLOR
		var color: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * fade)
		var prefix: String = "> " if i == selected_index else "  "
		var label: String = LEVEL_ENTRIES[i][2]
		_draw_centered_text(prefix + label, Vector2(cx, y_pos), 20, color)

	# Up/down hints if there are entries off the visible band.
	var pulse: float = sin(_time * 3.0) * 0.25 + 0.75
	if selected_index > 0:
		var hint_col := DIM_COLOR
		hint_col.a *= pulse
		_draw_centered_text("▲", Vector2(cx, band_top + 10.0), 18, hint_col)
	if selected_index < total - 1:
		var hint_col := DIM_COLOR
		hint_col.a *= pulse
		_draw_centered_text("▼", Vector2(cx, band_bottom - 10.0), 18, hint_col)

	_draw_centered_text("W/S to navigate, Space to select, Esc to go back", Vector2(cx, footer_y), 12, DIM_COLOR)


func _draw_controls() -> void:
	var cx: float = size.x / 2.0
	var start_y: float = 100.0

	_draw_centered_text("CONTROLS", Vector2(cx, start_y), 32, TITLE_COLOR)

	var y: float = start_y + 60
	for entry in CONTROLS:
		var key: String = entry[0]
		var desc: String = entry[1]
		if key == "":
			y += 10
			continue
		# Key on the left, description on the right
		_draw_text(key, Vector2(cx - 180, y), 16, HIGHLIGHT_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
		_draw_text(desc, Vector2(cx - 140, y), 16, TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		y += 32

	_draw_centered_text("Press Space or Esc to go back", Vector2(cx, size.y - 40), 12, DIM_COLOR)


func _draw_centered_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(pos.x - text_size.x / 2, pos.y + text_size.y / 4), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)


func _draw_text(text: String, pos: Vector2, font_size: int, color: Color, alignment: HorizontalAlignment) -> void:
	var font: Font = ThemeDB.fallback_font
	if alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(pos.x - text_size.x, pos.y), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	else:
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
