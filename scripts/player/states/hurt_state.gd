extends PlayerState

## Brief knockback + invincibility frames after taking damage.

var timer: float = 0.0
const HURT_DURATION: float = 0.4
const KNOCKBACK_FORCE: float = 250.0


func enter() -> void:
	player.visual_state = player.VisualState.HURT
	timer = HURT_DURATION
	player.is_invincible = true
	# Knockback in up direction
	player.velocity = GravityManager.get_up_direction() * KNOCKBACK_FORCE


func exit() -> void:
	pass


func physics_process(delta: float) -> void:
	timer -= delta
	apply_gravity(delta)
	player.move_and_slide()

	if timer <= 0:
		player.is_invincible = false
		if player.hp <= 0:
			state_machine.transition_to("dead")
		elif player.is_on_floor():
			state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
