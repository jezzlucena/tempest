extends Area2D

## Pendulum blade hazard — swings between two points.
## Respects TimeManager dilation — can be slowed by dilation fields.

const BLADE_COLOR := Color(0.7, 0.3, 0.3, 0.9)
const BLADE_EDGE := Color(0.9, 0.4, 0.4, 0.9)
const SLOWED_COLOR := Color(0.3, 0.4, 0.8, 0.9)

var pos_a: Vector2 = Vector2.ZERO
var pos_b: Vector2 = Vector2.ZERO
var speed: float = 200.0
var _progress: float = 0.0  # 0.0 = pos_a, 1.0 = pos_b
var _direction: float = 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Collision shape
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 80)
	shape.shape = rect
	add_child(shape)


func _physics_process(delta: float) -> void:
	var scaled_delta: float = TimeManager.get_scaled_delta(self, delta)
	var dist := pos_a.distance_to(pos_b)
	if dist < 1.0:
		return
	var step := (speed * scaled_delta) / dist
	_progress += step * _direction
	if _progress >= 1.0:
		_progress = 1.0
		_direction = -1.0
	elif _progress <= 0.0:
		_progress = 0.0
		_direction = 1.0
	global_position = pos_a.lerp(pos_b, _progress)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		body.take_damage(1)


func _draw() -> void:
	var is_slowed := TimeManager.is_position_dilated(global_position)
	var color := SLOWED_COLOR if is_slowed else BLADE_COLOR
	var edge := BLADE_EDGE if not is_slowed else Color(0.4, 0.5, 0.9, 0.9)
	# Vertical blade shape
	var points := PackedVector2Array([
		Vector2(0, -40),
		Vector2(6, -30),
		Vector2(6, 30),
		Vector2(0, 40),
		Vector2(-6, 30),
		Vector2(-6, -30),
	])
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), edge, 1.5)
