extends Node

## Manages the global gravity direction.
## Gravity can rotate in 90° increments. Camera and player controls follow.

signal gravity_rotated(new_angle: float)

## Gravity angle in degrees: 0, 90, 180, 270
var gravity_angle: float = 0.0
## Gravity angle in radians (derived)
var gravity_angle_radians: float = 0.0
## The current gravity vector applied to physics
var gravity_vector: Vector2 = Vector2(0, 980)
## Whether a rotation is currently in progress
var is_rotating: bool = false

const GRAVITY_STRENGTH: float = 980.0
const ROTATION_DURATION: float = 0.25
const ROTATION_COOLDOWN: float = 0.5

var _cooldown_timer: float = 0.0
var _player: CharacterBody2D = null


func _ready() -> void:
	_update_vector()


func _process(delta: float) -> void:
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

	# Listen for gravity rotation input
	if _player == null:
		_player = GameManager.player
		return

	# Player-driven gravity rotation is gated on the gravity ability.
	# Boss-forced rotations call rotate_gravity(dir, true) and bypass this.
	if not GameManager.has_ability(GameManager.ABILITY_GRAVITY):
		return
	if Input.is_action_just_pressed("gravity_left"):
		rotate_gravity(-1)
	elif Input.is_action_just_pressed("gravity_right"):
		rotate_gravity(1)


## Rotate gravity by direction (-1 = CCW 90°, +1 = CW 90°)
## Set force=true to bypass can_rotate() checks (used by boss).
func rotate_gravity(direction: int, force: bool = false) -> void:
	if not force and not can_rotate():
		return

	is_rotating = true
	_cooldown_timer = ROTATION_COOLDOWN

	# Snap starting angle to nearest 90° to prevent drift from interrupted rotations
	var snapped_start: float = round(gravity_angle / 90.0) * 90.0
	var target_angle: float = snapped_start + direction * 90.0
	target_angle = fmod(target_angle + 360.0, 360.0)

	var tween := get_tree().create_tween()
	tween.tween_method(_set_gravity_angle, gravity_angle, snapped_start + direction * 90.0, ROTATION_DURATION)
	tween.tween_callback(_finish_rotation.bind(target_angle))


func can_rotate() -> bool:
	if is_rotating:
		return false
	if _cooldown_timer > 0:
		return false
	return true


func _set_gravity_angle(angle: float) -> void:
	gravity_angle = angle
	_update_vector()


func _finish_rotation(final_angle: float) -> void:
	gravity_angle = fmod(final_angle + 360.0, 360.0)
	_update_vector()
	is_rotating = false
	gravity_rotated.emit(gravity_angle)


func _update_vector() -> void:
	gravity_angle_radians = deg_to_rad(gravity_angle)
	gravity_vector = Vector2(sin(gravity_angle_radians), cos(gravity_angle_radians)) * GRAVITY_STRENGTH


## Snap gravity to the nearest 90° increment. Called on respawn to fix
## interrupted rotation tweens.
func snap_to_nearest() -> void:
	gravity_angle = round(gravity_angle / 90.0) * 90.0
	gravity_angle = fmod(gravity_angle + 360.0, 360.0)
	_update_vector()
	is_rotating = false
	_cooldown_timer = 0.0


## Returns the up direction (opposite of gravity)
func get_up_direction() -> Vector2:
	return -gravity_vector.normalized()
