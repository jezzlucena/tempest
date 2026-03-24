extends Area2D

## Visible level exit portal. Triggers level transition when the player enters.

const PORTAL_COLOR := Color(0.3, 0.9, 0.5, 0.6)
const RING_COLOR := Color(0.4, 1.0, 0.6, 0.8)
const GLOW_COLOR := Color(0.3, 0.9, 0.5, 0.1)
const WIDTH := 32.0
const HEIGHT := 80.0

var _time: float = 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		GameManager.go_to_next_level()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := sin(_time * 3.0) * 0.2 + 0.8

	# Glow
	draw_circle(Vector2.ZERO, 50.0, GLOW_COLOR * Color(1, 1, 1, pulse))

	# Portal frame
	var half_w := WIDTH / 2
	var half_h := HEIGHT / 2
	var frame := PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h),
	])
	draw_colored_polygon(frame, Color(PORTAL_COLOR.r, PORTAL_COLOR.g, PORTAL_COLOR.b, 0.2 * pulse))
	draw_polyline(frame + PackedVector2Array([frame[0]]), RING_COLOR * Color(1, 1, 1, pulse), 2.0)

	# Arrow pointing right
	var arrow_col := RING_COLOR * Color(1, 1, 1, pulse)
	draw_line(Vector2(-8, 0), Vector2(8, 0), arrow_col, 2.0)
	draw_line(Vector2(4, -6), Vector2(10, 0), arrow_col, 2.0)
	draw_line(Vector2(4, 6), Vector2(10, 0), arrow_col, 2.0)
