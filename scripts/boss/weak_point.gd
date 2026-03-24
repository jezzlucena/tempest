extends Area2D

## Boss weak point — appears briefly, can be struck by the player.
## May be era-locked (only solid in a specific era).

signal hit

const ACTIVE_COLOR := Color(1.0, 0.85, 0.3, 1.0)
const GHOST_COLOR := Color(0.5, 0.5, 0.7, 0.4)
const PULSE_SPEED := 5.0
const SIZE := 36.0

var active: bool = false
var lifetime: float = 2.0
var _timer: float = 0.0
var required_era: int = -1  # -1 = any era


func _ready() -> void:
	z_index = 5
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = SIZE
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	monitoring = false
	visible = false


func activate(duration: float = 2.0, era: int = -1) -> void:
	lifetime = duration
	_timer = 0.0
	required_era = era
	active = true
	visible = true
	monitoring = true


func deactivate() -> void:
	active = false
	visible = false
	set_deferred("monitoring", false)


func _process(delta: float) -> void:
	if not active:
		return
	_timer += delta
	if _timer >= lifetime:
		deactivate()
		return
	queue_redraw()


func is_in_correct_era() -> bool:
	if required_era < 0:
		return true
	return int(TimeManager.current_era) == required_era


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if body != GameManager.player:
		return
	if not is_in_correct_era():
		return
	hit.emit()
	deactivate()


func _draw() -> void:
	if not active:
		return
	var in_era := is_in_correct_era()
	var base_color := ACTIVE_COLOR if in_era else GHOST_COLOR
	var pulse := sin(_timer * PULSE_SPEED) * 0.3 + 0.7
	var remaining := clampf(1.0 - (_timer / lifetime), 0.3, 1.0)

	# Filled circle
	var fill_color := base_color
	fill_color.a = 0.5 * pulse * remaining
	draw_circle(Vector2.ZERO, SIZE, fill_color)

	# Bright outer ring
	var ring_color := base_color
	ring_color.a = 0.9 * remaining
	draw_arc(Vector2.ZERO, SIZE, 0, TAU, 48, ring_color, 3.0)

	# Inner diamond — solid and bright
	var half := SIZE * 0.55
	var diamond := PackedVector2Array([
		Vector2(0, -half), Vector2(half, 0),
		Vector2(0, half), Vector2(-half, 0),
	])
	var diamond_color := base_color
	diamond_color.a = 0.9 * pulse * remaining
	draw_colored_polygon(diamond, diamond_color)

	# Spinning indicator lines
	var spin := _timer * 3.0
	for i in range(4):
		var angle := spin + i * TAU / 4.0
		var from := Vector2(cos(angle), sin(angle)) * SIZE * 1.2
		var to := Vector2(cos(angle), sin(angle)) * SIZE * 1.6
		var line_color := base_color
		line_color.a = 0.7 * pulse * remaining
		draw_line(from, to, line_color, 2.0)

	# Era label when era-locked
	if required_era >= 0:
		var era_names := ["Past", "Present", "Future"]
		var label_color := ACTIVE_COLOR if in_era else Color(1, 0.4, 0.4, 0.7)
		var font := ThemeDB.fallback_font
		var text: String = era_names[required_era]
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		draw_string(font, Vector2(-text_size.x / 2, SIZE + 20), text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 12, label_color)
