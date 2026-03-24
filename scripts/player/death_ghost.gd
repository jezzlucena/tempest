extends Node2D

## Fading ghost silhouette left at the player's death position.

var alpha: float = 0.4
var gravity_rotation: float = 0.0


func _process(delta: float) -> void:
	alpha -= delta * 0.35
	if alpha <= 0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, gravity_rotation)
	var col := Color(0.4, 0.5, 0.8, alpha)
	draw_rect(Rect2(-12, -48, 24, 48), col)
	draw_circle(Vector2(3, -34), 3.0, Color(0.6, 0.8, 1.0, alpha))
