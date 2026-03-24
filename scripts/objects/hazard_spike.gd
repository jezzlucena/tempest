extends Area2D

## Spike hazard — deals 1 damage on contact from any direction.
## Draws as a multi-directional spike cluster (diamond shapes pointing all ways).

const SPIKE_COLOR := Color(0.8, 0.2, 0.2, 0.9)
const SPIKE_INNER := Color(0.6, 0.15, 0.15, 0.9)
const BASE_COLOR := Color(0.4, 0.15, 0.15, 0.9)

@export var spike_count: int = 1
@export var spike_width: float = 32.0
@export var spike_height: float = 20.0

var _collision_built: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not _collision_built:
		_build_collision()


func _build_collision() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(spike_width * spike_count, spike_height)
	shape_node.shape = rect
	shape_node.position = Vector2(0, -spike_height / 2)
	add_child(shape_node)
	_collision_built = true


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body == GameManager.player:
		body.take_damage(1)


func _draw() -> void:
	var total_width := spike_width * spike_count
	for i in range(spike_count):
		var cx := -total_width / 2 + i * spike_width + spike_width / 2
		var cy := -spike_height / 2
		var hw := spike_width / 2 - 2  # half width
		var hh := spike_height / 2 - 1  # half height

		# Outer diamond — spikes pointing all 4 directions
		var outer := PackedVector2Array([
			Vector2(cx, cy - hh),       # top spike
			Vector2(cx + hw, cy),       # right spike
			Vector2(cx, cy + hh),       # bottom spike
			Vector2(cx - hw, cy),       # left spike
		])
		draw_colored_polygon(outer, SPIKE_COLOR)

		# Inner diamond for depth
		var inner_scale := 0.45
		var inner := PackedVector2Array([
			Vector2(cx, cy - hh * inner_scale),
			Vector2(cx + hw * inner_scale, cy),
			Vector2(cx, cy + hh * inner_scale),
			Vector2(cx - hw * inner_scale, cy),
		])
		draw_colored_polygon(inner, SPIKE_INNER)
