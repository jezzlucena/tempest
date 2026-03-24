extends CanvasLayer

## HUD — HP pips, era indicator, dilation cooldown.

const PIP_MARGIN := Vector2(32, 32)
const HP_FULL_COLOR := Color(0.6, 0.85, 1.0, 0.9)
const HP_EMPTY_COLOR := Color(0.3, 0.3, 0.35, 0.4)
const HP_OUTLINE_COLOR := Color(0.8, 0.9, 1.0, 0.6)

var hp_display: Control
var era_label: Label
var cooldown_display: Control


func _ready() -> void:
	layer = 10

	# HP pips
	hp_display = Control.new()
	hp_display.custom_minimum_size = Vector2(600, 50)
	hp_display.position = PIP_MARGIN
	add_child(hp_display)
	hp_display.draw.connect(_draw_hp)

	# Era indicator
	era_label = Label.new()
	era_label.position = Vector2(32, 90)
	era_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 0.8))
	era_label.add_theme_font_size_override("font_size", 28)
	add_child(era_label)

	# Cooldown indicators
	cooldown_display = Control.new()
	cooldown_display.custom_minimum_size = Vector2(300, 80)
	cooldown_display.position = Vector2(32, 130)
	add_child(cooldown_display)
	cooldown_display.draw.connect(_draw_cooldowns)

	_connect_signals.call_deferred()


func _connect_signals() -> void:
	await get_tree().process_frame
	if GameManager.player:
		GameManager.player.hp_changed.connect(_on_hp_changed)
	TimeManager.era_changed.connect(_on_era_changed)
	_update_era_label()


func _process(_delta: float) -> void:
	hp_display.queue_redraw()
	cooldown_display.queue_redraw()


func _on_hp_changed(_new_hp: int) -> void:
	hp_display.queue_redraw()


func _on_era_changed(_new_era: int) -> void:
	_update_era_label()


func _update_era_label() -> void:
	var ename: String = TimeManager.ERA_NAMES.get(TimeManager.current_era, "???")
	var tint: Color = TimeManager.ERA_TINTS.get(TimeManager.current_era, Color.WHITE)
	era_label.text = ename
	era_label.add_theme_color_override("font_color", tint * Color(0.7, 0.7, 0.7, 0.9))


func _draw_hp() -> void:
	var max_hp: int = 3
	var current_hp: int = 3
	if GameManager.player:
		max_hp = GameManager.player.MAX_HP
		current_hp = GameManager.player.hp

	for i in range(max_hp):
		var x := i * 44.0
		var cx := x + 18.0
		var cy := 18.0
		var half := 15.0
		var color := HP_FULL_COLOR if i < current_hp else HP_EMPTY_COLOR
		var diamond := PackedVector2Array([
			Vector2(cx, cy - half),
			Vector2(cx + half, cy),
			Vector2(cx, cy + half),
			Vector2(cx - half, cy),
		])
		hp_display.draw_colored_polygon(diamond, color)
		hp_display.draw_polyline(diamond + PackedVector2Array([diamond[0]]), HP_OUTLINE_COLOR, 2.0)


func _draw_cooldowns() -> void:
	if not GameManager.player:
		return

	var y := 0.0

	# Dilation cooldown
	var dil_progress: float = GameManager.player.get_dilation_cooldown_progress()
	_draw_cooldown_bar(cooldown_display, Vector2(0, y), "Time", dil_progress,
		Color(0.4, 0.6, 1.0, 0.7))

	# Era shift cooldown
	var era_progress: float = TimeManager.get_era_cooldown_progress()
	_draw_cooldown_bar(cooldown_display, Vector2(0, y + 28), "Era", era_progress,
		Color(0.7, 0.5, 1.0, 0.7))


func _draw_cooldown_bar(target: Control, pos: Vector2, label: String, progress: float, color: Color) -> void:
	var bar_width := 160.0
	var bar_height := 16.0
	# Background
	target.draw_rect(Rect2(pos, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.25, 0.5))
	# Fill
	var fill_color := color if progress >= 1.0 else color * Color(0.6, 0.6, 0.6, 0.7)
	target.draw_rect(Rect2(pos, Vector2(bar_width * progress, bar_height)), fill_color)
	# Outline
	target.draw_rect(Rect2(pos, Vector2(bar_width, bar_height)), Color(0.5, 0.6, 0.7, 0.3), false, 1.0)
	# Label
	target.draw_string(ThemeDB.fallback_font, pos + Vector2(bar_width + 10, bar_height - 2),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
		Color(0.5, 0.6, 0.7, 0.7))
