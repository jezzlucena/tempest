extends AnimatableBody2D

## Moving platform that travels between waypoints.
## Respects TimeManager dilation.

const PLATFORM_COLOR := Color(0.35, 0.35, 0.45, 1.0)
const PLATFORM_ACCENT := Color(0.45, 0.45, 0.55, 1.0)

@export var speed: float = 100.0
@export var platform_width: float = 96.0
@export var platform_height: float = 16.0

var waypoints: Array = []
var current_waypoint_index: int = 0
var _moving_forward: bool = true


func _ready() -> void:
	# Build collision shape to match size
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(platform_width, platform_height)
	shape_node.shape = rect
	add_child(shape_node)

	if waypoints.is_empty():
		waypoints = [global_position]


func _physics_process(delta: float) -> void:
	if waypoints.size() < 2:
		return

	var scaled_delta: float = TimeManager.get_scaled_delta(self, delta)
	var target: Vector2 = waypoints[current_waypoint_index]
	var direction: Vector2 = (target - global_position).normalized()
	var distance: float = global_position.distance_to(target)
	var move_amount: float = speed * scaled_delta

	if move_amount >= distance:
		global_position = target
		# Advance to next waypoint
		if _moving_forward:
			current_waypoint_index += 1
			if current_waypoint_index >= waypoints.size():
				current_waypoint_index = waypoints.size() - 2
				_moving_forward = false
		else:
			current_waypoint_index -= 1
			if current_waypoint_index < 0:
				current_waypoint_index = 1
				_moving_forward = true
	else:
		global_position += direction * move_amount


func _draw() -> void:
	var half_w := platform_width / 2
	var half_h := platform_height / 2
	# Main platform body
	draw_rect(Rect2(-half_w, -half_h, platform_width, platform_height), PLATFORM_COLOR)
	# Top accent line
	draw_rect(Rect2(-half_w, -half_h, platform_width, 3), PLATFORM_ACCENT)
	# Edge notches
	draw_rect(Rect2(-half_w, -half_h, 4, platform_height), PLATFORM_ACCENT)
	draw_rect(Rect2(half_w - 4, -half_h, 4, platform_height), PLATFORM_ACCENT)
