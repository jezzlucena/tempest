extends CharacterBody2D

## The Still Plaza Sentinel — W1 boss.
## Patrols horizontally between waypoints. The player can defeat it by
## landing on its head (stomp). Any other contact damages the player.

signal boss_defeated

const BODY_COLOR := Color(0.32, 0.28, 0.38, 1.0)
const OUTLINE_COLOR := Color(0.75, 0.8, 0.95, 0.9)
const EYE_COLOR := Color(0.95, 0.35, 0.35, 1.0)
const HURT_COLOR := Color(1.0, 0.95, 0.95, 1.0)
const WIDTH: float = 36.0
const HEIGHT: float = 48.0

## Bounce imparted to the player on a successful stomp.
const STOMP_BOUNCE: float = 420.0

@export var speed: float = 120.0
@export var damage: int = 1
@export var max_hp: int = 1

var hp: int
var waypoints: Array = []
var current_waypoint_index: int = 0
var _moving_forward: bool = true
var _defeated: bool = false
var _hurt_flash: float = 0.0
var _eye_pulse: float = 0.0
var _contact_area: Area2D


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_contact_area = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH + 4, HEIGHT + 4)
	shape.shape = rect
	shape.position = Vector2(0, -HEIGHT / 2.0)
	_contact_area.add_child(shape)
	_contact_area.body_entered.connect(_on_body_entered)
	_contact_area.collision_layer = 0
	_contact_area.collision_mask = 1
	add_child(_contact_area)
	if waypoints.is_empty():
		waypoints = [global_position]


func _physics_process(delta: float) -> void:
	if _defeated:
		return

	up_direction = GravityManager.get_up_direction()
	velocity += GravityManager.gravity_vector * delta

	if waypoints.size() >= 2:
		var target: Vector2 = waypoints[current_waypoint_index]
		var to_target := target - global_position
		var grav_dir := GravityManager.gravity_vector.normalized()
		var lateral_to_target := to_target - to_target.dot(grav_dir) * grav_dir
		if lateral_to_target.length() > 0.01:
			lateral_to_target = lateral_to_target.normalized()
		velocity = velocity.dot(grav_dir) * grav_dir + lateral_to_target * speed

		if global_position.distance_to(target) < 24.0:
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

	_hurt_flash = max(0.0, _hurt_flash - delta)
	_eye_pulse += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _defeated:
		return
	if body != GameManager.player:
		return
	var player_body: CharacterBody2D = body as CharacterBody2D
	if player_body == null:
		return
	# Position-only check: contact is a stomp when the player's feet sit
	# above the sentinel's midpoint. The Area2D body_entered signal is
	# deferred and often arrives after move_and_slide has already zeroed
	# the player's falling velocity, so a velocity-based descent check
	# misclassifies stomps as side hits.
	var up: Vector2 = GravityManager.get_up_direction()
	var rel: Vector2 = player_body.global_position - global_position
	var above_amount: float = rel.dot(up)
	var is_above: bool = above_amount > HEIGHT * 0.5

	if is_above:
		_take_stomp(player_body)
	else:
		player_body.take_damage(damage)


func _take_stomp(player_body: CharacterBody2D) -> void:
	hp -= 1
	_hurt_flash = 0.3
	var up := GravityManager.get_up_direction()
	player_body.velocity = up * STOMP_BOUNCE
	if hp <= 0:
		_defeat()


func _defeat() -> void:
	_defeated = true
	velocity = Vector2.ZERO
	_contact_area.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 0.3), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void:
		boss_defeated.emit()
	)


func _draw() -> void:
	var color := BODY_COLOR if _hurt_flash <= 0 else HURT_COLOR
	draw_set_transform(Vector2.ZERO, -GravityManager.gravity_angle_radians)

	var hw := WIDTH / 2.0
	var body := PackedVector2Array([
		Vector2(-hw * 0.7, 0),
		Vector2(hw * 0.7, 0),
		Vector2(hw, -HEIGHT * 0.6),
		Vector2(hw * 0.55, -HEIGHT),
		Vector2(-hw * 0.55, -HEIGHT),
		Vector2(-hw, -HEIGHT * 0.6),
	])
	draw_colored_polygon(body, color)
	draw_polyline(body + PackedVector2Array([body[0]]), OUTLINE_COLOR, 1.5)

	var pulse := sin(_eye_pulse * 3.0) * 0.25 + 0.75
	var facing := 1.0 if _moving_forward else -1.0
	var eye_col := EYE_COLOR
	eye_col.a = pulse
	draw_rect(Rect2(facing * 4.0 - 5.0, -HEIGHT * 0.76, 10.0, 6.0), eye_col)
