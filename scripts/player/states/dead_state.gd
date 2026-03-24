extends PlayerState

## Death state — plays a rewind visual then respawns at checkpoint.

const DEATH_DELAY: float = 1.2
const REWIND_COLOR := Color(0.5, 0.7, 1.0, 0.3)
const GHOST_COLOR := Color(0.4, 0.5, 0.8, 0.15)


func enter() -> void:
	player.velocity = Vector2.ZERO
	player.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

	# Rewind visual — screen desaturation + ghost trail
	_play_rewind_effect()

	var tween := player.get_tree().create_tween()
	tween.tween_callback(_respawn).set_delay(DEATH_DELAY)


func exit() -> void:
	player.process_mode = Node.PROCESS_MODE_INHERIT


func _respawn() -> void:
	player.process_mode = Node.PROCESS_MODE_INHERIT
	GameManager.respawn_player()
	state_machine.transition_to("idle")


func _play_rewind_effect() -> void:
	var root := player.get_tree().root

	# Screen overlay — blue desaturation
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	var overlay := ColorRect.new()
	overlay.color = REWIND_COLOR
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	root.add_child(canvas)

	# Fade the overlay
	var tween := canvas.create_tween()
	tween.tween_property(overlay, "color:a", 0.0, DEATH_DELAY)
	tween.tween_callback(canvas.queue_free)

	# Ghost trail at death position — fading silhouette rotated to match gravity
	var ghost_script := preload("res://scripts/player/death_ghost.gd")
	var ghost := Node2D.new()
	ghost.set_script(ghost_script)
	ghost.global_position = player.global_position
	ghost.z_index = 5
	ghost.gravity_rotation = -GravityManager.gravity_angle_radians
	root.add_child(ghost)


func physics_process(_delta: float) -> void:
	pass
