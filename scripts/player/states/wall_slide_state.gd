extends PlayerState

## Slow descent while pressed against a wall. Jump to wall-jump away.

const WALL_SLIDE_SPEED: float = 80.0
const WALL_JUMP_VELOCITY: float = 400.0
const WALL_JUMP_PUSH: float = 350.0


func enter() -> void:
	player.visual_state = player.VisualState.WALL_SLIDE


func physics_process(delta: float) -> void:
	# Slow gravity descent along wall
	var grav_dir := GravityManager.gravity_vector.normalized()
	var gravity_component := player.velocity.dot(grav_dir)
	# Clamp fall speed along gravity direction
	if gravity_component > WALL_SLIDE_SPEED:
		player.velocity -= grav_dir * (gravity_component - WALL_SLIDE_SPEED)
	else:
		apply_gravity(delta)

	apply_lateral_movement(delta)
	player.move_and_slide()

	# Wall jump: push away from wall + upward
	if Input.is_action_just_pressed("jump"):
		var wall_normal := player.get_wall_normal()
		player.velocity = wall_normal * WALL_JUMP_PUSH + GravityManager.get_up_direction() * WALL_JUMP_VELOCITY
		state_machine.transition_to("jump")
		return

	if player.is_on_floor():
		state_machine.transition_to("idle")
		return

	# Left the wall
	if not player.is_on_wall():
		state_machine.transition_to("fall")
