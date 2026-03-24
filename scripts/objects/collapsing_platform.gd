extends StaticBody2D

## Platform that collapses shortly after the player stands on it.
## Shakes briefly, then falls away and disables collision.

const PLATFORM_COLOR := Color(0.35, 0.28, 0.28, 1.0)
const SHAKE_COLOR := Color(0.5, 0.3, 0.3, 1.0)
const SHAKE_DURATION := 0.4
const FALL_DURATION := 0.6
const RESPAWN_DELAY := 4.0

@export var platform_width: float = 96.0
@export var platform_height: float = 12.0

var _triggered: bool = false
var _shaking: bool = false
var _fallen: bool = false
var _original_position: Vector2
var _detect_area: Area2D


func _ready() -> void:
	_original_position = position

	# Build collision shape
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(platform_width, platform_height)
	shape.shape = rect
	add_child(shape)

	# Detection area slightly above the platform to detect landing
	_detect_area = Area2D.new()
	var detect_shape := CollisionShape2D.new()
	var detect_rect := RectangleShape2D.new()
	detect_rect.size = Vector2(platform_width - 4, platform_height + 16)
	detect_shape.shape = detect_rect
	detect_shape.position = Vector2(0, -8)
	_detect_area.add_child(detect_shape)
	_detect_area.body_entered.connect(_on_body_entered)
	_detect_area.collision_layer = 0
	_detect_area.collision_mask = 1
	add_child(_detect_area)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body == GameManager.player:
		_triggered = true
		_collapse()


func _collapse() -> void:
	_shaking = true
	queue_redraw()

	# Shake phase
	var tween := create_tween()
	for i in range(6):
		var offset := Vector2(randf_range(-3, 3), randf_range(-2, 2))
		tween.tween_property(self, "position", _original_position + offset, SHAKE_DURATION / 6.0)
	tween.tween_property(self, "position", _original_position, 0.01)

	# Fall phase
	tween.tween_callback(func() -> void:
		_shaking = false
		_fallen = true
		# Disable collision so player falls through
		collision_layer = 0
		collision_mask = 0
		queue_redraw()
	)
	var fall_target := _original_position + GravityManager.gravity_vector.normalized() * 300
	tween.tween_property(self, "position", fall_target, FALL_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, FALL_DURATION)

	# Respawn
	tween.tween_interval(RESPAWN_DELAY)
	tween.tween_callback(_respawn)


func _respawn() -> void:
	position = _original_position
	modulate.a = 1.0
	collision_layer = 1
	collision_mask = 1
	_triggered = false
	_fallen = false
	queue_redraw()


func _draw() -> void:
	var half_w := platform_width / 2
	var half_h := platform_height / 2
	var color := SHAKE_COLOR if _shaking else PLATFORM_COLOR
	if _fallen:
		color.a = 0.3
	# Main body
	draw_rect(Rect2(-half_w, -half_h, platform_width, platform_height), color)
	# Crack lines to hint it's unstable
	var crack_color := color.darkened(0.3)
	draw_line(Vector2(-half_w * 0.5, -half_h), Vector2(0, half_h), crack_color, 1.0)
	draw_line(Vector2(half_w * 0.3, -half_h), Vector2(half_w * 0.6, half_h), crack_color, 1.0)
