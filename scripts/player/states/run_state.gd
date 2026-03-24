extends PlayerState


func enter() -> void:
	player.visual_state = player.VisualState.RUN
	player._run_cycle = 0.0


func physics_process(delta: float) -> void:
	apply_gravity(delta)
	apply_lateral_movement(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to("jump")
		return

	if get_movement_input().length() < 0.01:
		state_machine.transition_to("idle")
