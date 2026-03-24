extends CharacterBody2D

## Basic patrol enemy — walks between waypoints, damages player on contact.
## Affected by gravity and time dilation.

const BODY_COLOR := Color(0.7, 0.25, 0.25, 0.9)
const EYE_COLOR := Color(1.0, 0.4, 0.2, 0.9)
const SLOWED_COLOR := Color(0.4, 0.3, 0.6, 0.9)
const ENEMY_WIDTH: float = 20.0
const ENEMY_HEIGHT: float = 28.0

@export var speed: float = 80.0
@export var damage: int = 1

var waypoints: Array = []
var current_waypoint_index: int = 0
var _moving_forward: bool = true
var _contact_area: Area2D


func _ready() -> void:
	# Contact damage area
	_contact_area = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ENEMY_WIDTH + 4, ENEMY_HEIGHT + 4)
	shape.shape = rect
	shape.position = Vector2(0, -ENEMY_HEIGHT / 2)
	_contact_area.add_child(shape)
	_contact_area.body_entered.connect(_on_body_entered)
	_contact_area.collision_layer = 0
	_contact_area.collision_mask = 1
	add_child(_contact_area)

	if waypoints.is_empty():
		waypoints = [global_position]


func _physics_process(delta: float) -> void:
	var scaled_delta: float = TimeManager.get_scaled_delta(self, delta)

	up_direction = GravityManager.get_up_direction()
	velocity += GravityManager.gravity_vector * scaled_delta

	# Rotate collision to match gravity
	var grav_rot := -GravityManager.gravity_angle_radians
	$CollisionShape2D.rotation = grav_rot
	$CollisionShape2D.position = Vector2(0, -14).rotated(grav_rot)

	# Move toward current waypoint
	if waypoints.size() >= 2:
		var target: Vector2 = waypoints[current_waypoint_index]
		var dir := (target - global_position).normalized()
		var grav_dir := GravityManager.gravity_vector.normalized()
		# Project movement onto lateral axis (perpendicular to gravity)
		var lateral := dir - dir.dot(grav_dir) * grav_dir
		if lateral.length() > 0.01:
			lateral = lateral.normalized()
		velocity = velocity.dot(grav_dir) * grav_dir + lateral * speed

		# Check if reached waypoint
		if global_position.distance_to(target) < 16.0:
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

	move_and_slide()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		body.take_damage(damage)


func _draw() -> void:
	var is_slowed := TimeManager.is_position_dilated(global_position)
	var color := SLOWED_COLOR if is_slowed else BODY_COLOR

	# Rotate sprite to match gravity (same as player)
	draw_set_transform(Vector2.ZERO, -GravityManager.gravity_angle_radians)

	# Body — angular, geometric shape
	var points := PackedVector2Array([
		Vector2(0, -ENEMY_HEIGHT),
		Vector2(ENEMY_WIDTH / 2, -ENEMY_HEIGHT * 0.6),
		Vector2(ENEMY_WIDTH / 2, 0),
		Vector2(-ENEMY_WIDTH / 2, 0),
		Vector2(-ENEMY_WIDTH / 2, -ENEMY_HEIGHT * 0.6),
	])
	draw_colored_polygon(points, color)

	# Eye — angular, menacing
	var eye_y := -ENEMY_HEIGHT * 0.7
	var facing := 1.0 if _moving_forward else -1.0
	draw_rect(Rect2(facing * 2 - 3, eye_y - 2, 6, 4), EYE_COLOR)
