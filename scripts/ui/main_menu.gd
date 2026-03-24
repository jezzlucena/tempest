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

const LEVEL_NAMES := [
	"Level 1 — The Ascending Ruin",
	"Level 2 — The Fractured Gallery",
	"Level 3 — The Chronolith",
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
				GameManager.go_to_level(0)
			"Level Select":
				current_screen = Screen.LEVELS
				selected_index = 0
			"Controls":
				current_screen = Screen.CONTROLS
				selected_index = 0


func _handle_levels_input(event: InputEventKey) -> void:
	if event.keycode == KEY_W or event.keycode == KEY_UP:
		selected_index = (selected_index - 1 + LEVEL_NAMES.size()) % LEVEL_NAMES.size()
	elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
		selected_index = (selected_index + 1) % LEVEL_NAMES.size()
	elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		GameManager.go_to_level(selected_index)
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

	_draw_centered_text("LEVEL SELECT", Vector2(cx, cy - 120), 32, TITLE_COLOR)

	for i in range(LEVEL_NAMES.size()):
		var y_pos: float = cy - 20 + i * 45
		var color: Color = HIGHLIGHT_COLOR if i == selected_index else TEXT_COLOR
		var prefix: String = "> " if i == selected_index else "  "
		_draw_centered_text(prefix + LEVEL_NAMES[i], Vector2(cx, y_pos), 20, color)

	_draw_centered_text("W/S to navigate, Space to select, Esc to go back", Vector2(cx, size.y - 40), 12, DIM_COLOR)


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
