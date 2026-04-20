extends PlayerState


func enter() -> void:
	player.visual_state = player.VisualState.JUMP
	# Apply jump impulse in the up direction
	player.velocity += GravityManager.get_up_direction() * abs(player.JUMP_VELOCITY)


func physics_process(delta: float) -> void:
	apply_gravity(delta)
	apply_lateral_movement(delta)
	player.move_and_slide()

	# Transition to fall when moving in gravity direction (past apex)
	var grav_dir := GravityManager.gravity_vector.normalized()
	if player.velocity.dot(grav_dir) > 0:
		state_machine.transition_to("fall")
		return

	# Check for wall slide opportunity (requires wall-jump ability)
	if player.is_on_wall() and not player.is_on_floor() and GameManager.has_ability(GameManager.ABILITY_WALL_JUMP):
		state_machine.transition_to("wall_slide")
