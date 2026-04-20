extends Node

## Manages time dilation fields and era state.
## Dilation fields slow everything inside to 20% speed (except the player).
## Era shifts swap between Past/Present/Future geometry.

enum Era { PAST, PRESENT, FUTURE }

signal era_changed(new_era: Era)
signal dilation_field_spawned(field: Node2D)
signal dilation_field_expired(field: Node2D)

const DILATION_FACTOR: float = 0.2
const ERA_SHIFT_COOLDOWN: float = 1.5

var current_era: Era = Era.PRESENT
var dilation_fields: Array[Node2D] = []
var _era_cooldown: float = 0.0

## Era display names
const ERA_NAMES := {
	Era.PAST: "Past",
	Era.PRESENT: "Present",
	Era.FUTURE: "Future",
}

## Era tint colors for visual feedback
const ERA_TINTS := {
	Era.PAST: Color(1.1, 0.95, 0.8, 1.0),
	Era.PRESENT: Color(1.0, 1.0, 1.0, 1.0),
	Era.FUTURE: Color(0.85, 0.9, 1.15, 1.0),
}


func _process(delta: float) -> void:
	if _era_cooldown > 0:
		_era_cooldown -= delta

	# Era shift input (gated on ability)
	if not GameManager.has_ability(GameManager.ABILITY_ERA_SHIFT):
		return
	if Input.is_action_just_pressed("era_shift_earlier"):
		era_shift(-1)
	elif Input.is_action_just_pressed("era_shift_later"):
		era_shift(1)


## Returns the time-scaled delta for a given node.
## Checks if the node is inside any active dilation field.
func get_scaled_delta(node: Node2D, delta: float) -> float:
	for field in dilation_fields:
		if not is_instance_valid(field):
			continue
		if field.is_node_inside(node):
			return delta * DILATION_FACTOR
	return delta


## Check if a position is inside any dilation field
func is_position_dilated(pos: Vector2) -> bool:
	for field in dilation_fields:
		if not is_instance_valid(field):
			continue
		if field.is_position_inside(pos):
			return true
	return false


## Register a new dilation field
func register_field(field: Node2D) -> void:
	dilation_fields.append(field)
	dilation_field_spawned.emit(field)


## Unregister an expired dilation field
func unregister_field(field: Node2D) -> void:
	dilation_fields.erase(field)
	dilation_field_expired.emit(field)


## Shift era by direction (-1 = earlier, +1 = later)
func era_shift(direction: int) -> bool:
	if not can_era_shift():
		return false

	var new_era_int: int = int(current_era) + direction
	if new_era_int < 0 or new_era_int > 2:
		return false

	# Check if shift would embed the player
	if LevelStateManager.would_embed_player(new_era_int):
		_flash_warning()
		return false

	_era_cooldown = ERA_SHIFT_COOLDOWN
	current_era = new_era_int as Era
	LevelStateManager.swap_era(new_era_int)
	era_changed.emit(current_era)
	_era_transition_effect(current_era)
	return true


func can_era_shift() -> bool:
	return _era_cooldown <= 0


func get_era_cooldown_progress() -> float:
	return clampf(1.0 - _era_cooldown / ERA_SHIFT_COOLDOWN, 0.0, 1.0)


func _flash_warning() -> void:
	# Brief red flash on the screen to indicate blocked shift
	var root := get_tree().root
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	var rect := ColorRect.new()
	rect.color = Color(1, 0.2, 0.2, 0.3)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	root.add_child(canvas)
	var tween := canvas.create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.3)
	tween.tween_callback(canvas.queue_free)


func _era_transition_effect(era: Era) -> void:
	# Brief color wash matching the destination era
	var tint: Color = ERA_TINTS.get(era, Color.WHITE)
	var root := get_tree().root
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	var rect := ColorRect.new()
	rect.color = Color(tint.r, tint.g, tint.b, 0.35)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	root.add_child(canvas)
	var tween := canvas.create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)
