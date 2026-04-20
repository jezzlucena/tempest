extends Node
class_name PlayerState

## Base class for all player states.

var player: CharacterBody2D
var state_machine: Node


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_process(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


## Helper: apply gravity to player velocity
func apply_gravity(delta: float) -> void:
	player.velocity += GravityManager.gravity_vector * delta


## Helper: get screen-relative horizontal input converted to world space.
## Screen→World requires rotating by -gravity_angle (inverse of camera view rotation).
## Returns zero if the player lacks the sideways-movement ability.
func get_movement_input() -> Vector2:
	if not GameManager.has_ability(GameManager.ABILITY_SIDEWAYS):
		return Vector2.ZERO
	var input_dir := Input.get_axis("move_left", "move_right")
	return Vector2(input_dir, 0).rotated(-GravityManager.gravity_angle_radians)


## Helper: apply lateral movement (perpendicular to gravity)
func apply_lateral_movement(delta: float, speed: float = -1.0) -> void:
	if speed < 0:
		speed = player.SPEED
	var move_dir := get_movement_input()
	var target_vel := move_dir * speed
	var accel := speed * 10.0 * delta
	var grav_dir := GravityManager.gravity_vector.normalized()
	var gravity_component := player.velocity.dot(grav_dir) * grav_dir
	var lateral_component := player.velocity - gravity_component
	if move_dir.length() > 0.01:
		lateral_component = lateral_component.move_toward(target_vel, accel)
	else:
		lateral_component = lateral_component.move_toward(Vector2.ZERO, accel)
	player.velocity = gravity_component + lateral_component
