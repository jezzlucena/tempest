extends Area2D

## Gravity trigger — forces a gravity rotation the first time the player
## crosses the trigger, then disables itself so the player can't oscillate
## by re-entering the zone. Used in W3-2 to preview gravity flips before
## the ability is granted.

@export var rotation_direction: int = 2  # 2 = 180°, 1 = 90° CW, -1 = 90° CCW
@export var size: Vector2 = Vector2(32, 224)
@export var show_hint: bool = true

const HINT_COLOR := Color(0.5, 0.7, 1.0, 0.18)
const HINT_EDGE_COLOR := Color(0.6, 0.8, 1.0, 0.55)

var _fired: bool = false


func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	add_child(shape_node)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _fired:
		return
	if body != GameManager.player:
		return
	_fired = true
	GravityManager.rotate_gravity(rotation_direction, true)
	set_deferred("monitoring", false)
	queue_redraw()


func _draw() -> void:
	if not show_hint or _fired:
		return
	var half := size * 0.5
	var rect := Rect2(-half, size)
	draw_rect(rect, HINT_COLOR)
	# Dashed vertical guide lines at the edges
	var x_left := -half.x
	var x_right := half.x
	var dash := 12.0
	var gap := 6.0
	var y := -half.y
	while y < half.y:
		var seg_end: float = min(y + dash, half.y)
		draw_line(Vector2(x_left, y), Vector2(x_left, seg_end), HINT_EDGE_COLOR, 2.0)
		draw_line(Vector2(x_right, y), Vector2(x_right, seg_end), HINT_EDGE_COLOR, 2.0)
		y += dash + gap
