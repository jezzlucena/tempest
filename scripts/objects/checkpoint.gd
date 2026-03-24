extends Area2D

## Checkpoint — saves respawn position when the player enters.
## Only the most recently touched checkpoint stays active.

const SIZE := Vector2(32, 64)
const INACTIVE_COLOR := Color(0.3, 0.3, 0.5, 0.6)
const ACTIVE_COLOR := Color(0.4, 0.7, 1.0, 0.8)

var activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.checkpoint_activated.connect(_on_any_checkpoint_activated)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body == GameManager.player:
		activated = true
		GameManager.set_checkpoint(global_position + Vector2(0, -SIZE.y / 2))
		queue_redraw()


func _on_any_checkpoint_activated() -> void:
	# Deactivate if this isn't the current checkpoint
	var my_pos := global_position + Vector2(0, -SIZE.y / 2)
	if my_pos.distance_to(GameManager.current_checkpoint_position) > 8.0:
		activated = false
		queue_redraw()


func _draw() -> void:
	var color := ACTIVE_COLOR if activated else INACTIVE_COLOR
	var rect := Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y)
	draw_rect(rect, color)
