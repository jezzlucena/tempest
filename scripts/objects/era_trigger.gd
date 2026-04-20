extends Area2D

## Era trigger — sets the current era to a fixed value on player contact.
## Reusable: fires each time the player re-enters, so stepping out of a
## trigger and back in re-applies the shift.
##
## Used by W5 levels to author era progression while the player doesn't
## have the era-shift ability. Calls the direct LevelStateManager.swap_era
## path so the trigger is reliable even when the gated TimeManager.era_shift
## would refuse (cooldown or small embed overlap).

@export var target_era: int = 0  # 0 = Past, 1 = Present, 2 = Future
@export var size: Vector2 = Vector2(32, 192)
@export var show_hint: bool = true

const ERA_TINTS := {
	0: Color(0.45, 0.38, 0.25, 0.25),  # Past — warm brown
	1: Color(0.32, 0.32, 0.38, 0.22),  # Present — cool gray
	2: Color(0.2, 0.3, 0.55, 0.28),    # Future — cool blue
}
const EDGE_COLOR := Color(0.9, 0.85, 1.0, 0.7)


func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	add_child(shape_node)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body != GameManager.player:
		return
	if int(TimeManager.current_era) == target_era:
		return  # already in the target era — no-op
	TimeManager.current_era = target_era as TimeManager.Era
	LevelStateManager.swap_era(target_era)
	TimeManager.era_changed.emit(TimeManager.current_era)
	queue_redraw()


func _draw() -> void:
	if not show_hint:
		return
	var half := size * 0.5
	var rect := Rect2(-half, size)
	var tint: Color = ERA_TINTS.get(target_era, Color(1, 1, 1, 0.2))
	draw_rect(rect, tint)
	# Two dashed edge lines hinting the doorway.
	var dash := 10.0
	var gap := 6.0
	var y := -half.y
	while y < half.y:
		var seg_end: float = min(y + dash, half.y)
		draw_line(Vector2(-half.x, y), Vector2(-half.x, seg_end), EDGE_COLOR, 2.0)
		draw_line(Vector2(half.x, y), Vector2(half.x, seg_end), EDGE_COLOR, 2.0)
		y += dash + gap
