extends PlayerState

## Coyote time: brief window after leaving a ledge where jump is still allowed
var coyote_timer: float = 0.0
const COYOTE_TIME: float = 0.1


func enter() -> void:
	player.visual_state = player.VisualState.FALL
	coyote_timer = COYOTE_TIME


func physics_process(delta: float) -> void:
	coyote_timer -= delta
	apply_gravity(delta)
	apply_lateral_movement(delta)
	player.move_and_slide()

	if player.is_on_floor():
		player.trigger_land()
		if get_movement_input().length() > 0.01:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return

	# Coyote jump
	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		state_machine.transition_to("jump")
		return

	# Wall slide
	if player.is_on_wall():
		state_machine.transition_to("wall_slide")
