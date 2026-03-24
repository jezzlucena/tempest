extends Node

## Manages per-era TileMapLayers — toggles visibility and collision on era shift.

var era_layers: Dictionary = {}  # era int -> TileMapLayer
var player_ref: CharacterBody2D = null


## Register a tilemap layer for a specific era
func register_era_layer(era: int, layer: TileMapLayer) -> void:
	era_layers[era] = layer
	# Only the current era is active
	var is_active: bool = (era == TimeManager.current_era)
	layer.visible = is_active
	layer.collision_enabled = is_active


## Clear all registered layers (call when changing levels)
func clear_layers() -> void:
	era_layers.clear()


## Swap to a new era — disable old, enable new
func swap_era(new_era: int) -> void:
	for era in era_layers:
		var layer: TileMapLayer = era_layers[era]
		if not is_instance_valid(layer):
			continue
		var is_active: bool = (int(era) == int(new_era))
		layer.visible = is_active
		layer.collision_enabled = is_active


## Check if shifting to the given era would embed the player in solid geometry
func would_embed_player(target_era: int) -> bool:
	if not era_layers.has(target_era):
		return false

	var player: CharacterBody2D = GameManager.player
	if player == null:
		return false

	var target_layer: TileMapLayer = era_layers[target_era]
	if not is_instance_valid(target_layer):
		return false

	# Temporarily enable the target layer to query collision
	var was_enabled: bool = target_layer.collision_enabled
	target_layer.collision_enabled = true

	# Get the player's collision shape and check overlap
	var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()

	# Find the player's collision shape
	var col_shape: CollisionShape2D = null
	for child in player.get_children():
		if child is CollisionShape2D:
			col_shape = child
			break

	if col_shape == null:
		target_layer.collision_enabled = was_enabled
		return false

	query.shape = col_shape.shape
	query.transform = player.global_transform * col_shape.transform
	query.collision_mask = 1
	# Exclude the player's own body
	query.exclude = [player.get_rid()]

	var results: Array[Dictionary] = space.intersect_shape(query, 1)

	# Restore original state
	target_layer.collision_enabled = was_enabled

	return results.size() > 0


## Get the currently active tilemap
func get_active_tilemap() -> TileMapLayer:
	if era_layers.has(TimeManager.current_era):
		return era_layers[TimeManager.current_era]
	return null
