extends Node2D

## Time dilation field — a bubble that slows everything inside to 20% speed.
## Spawned by the player, lives for DURATION seconds, then dissipates.

const DURATION: float = 4.0
const RADIUS: float = 96.0  # ~3 tiles
const BUBBLE_COLOR := Color(0.3, 0.5, 0.9, 0.15)
const BUBBLE_EDGE_COLOR := Color(0.4, 0.6, 1.0, 0.4)
const BUBBLE_PULSE_SPEED: float = 3.0

var time_alive: float = 0.0
var _area: Area2D


func _ready() -> void:
	# Create the detection area
	_area = Area2D.new()
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape_node.shape = circle
	_area.add_child(shape_node)
	# Monitorable but doesn't block physics
	_area.collision_layer = 0
	_area.collision_mask = 0
	add_child(_area)

	TimeManager.register_field(self)


func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= DURATION:
		_expire()
		return
	queue_redraw()


func _expire() -> void:
	TimeManager.unregister_field(self)
	# Fade out
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


## Check if a node's global position is inside this field
func is_node_inside(node: Node2D) -> bool:
	return global_position.distance_to(node.global_position) <= RADIUS


## Check if a world position is inside this field
func is_position_inside(pos: Vector2) -> bool:
	return global_position.distance_to(pos) <= RADIUS


func _draw() -> void:
	var life_ratio := time_alive / DURATION
	var fade := 1.0 - life_ratio  # Fades as it expires
	var pulse := sin(time_alive * BUBBLE_PULSE_SPEED) * 0.3 + 0.7

	# Filled bubble
	var fill_color := BUBBLE_COLOR
	fill_color.a *= fade * pulse
	draw_circle(Vector2.ZERO, RADIUS, fill_color)

	# Edge ring
	var edge_color := BUBBLE_EDGE_COLOR
	edge_color.a *= fade
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 64, edge_color, 2.0)

	# Inner ripple rings
	var ripple_r := fmod(time_alive * 40.0, RADIUS)
	var ripple_color := BUBBLE_EDGE_COLOR
	ripple_color.a *= fade * 0.3
	draw_arc(Vector2.ZERO, ripple_r, 0, TAU, 32, ripple_color, 1.0)

	# Time remaining indicator — shrinking inner circle
	var remaining_radius := RADIUS * (1.0 - life_ratio) * 0.3
	var indicator_color := Color(0.6, 0.8, 1.0, 0.3 * fade)
	draw_circle(Vector2.ZERO, remaining_radius, indicator_color)
