extends Node2D

## W3-2 — The Inverted Corridor
##
## Horizontal corridor with walkable floor AND ceiling. Three invisible
## flip triggers along the way force 180° gravity rotations on contact.
## Player alternates between floor and ceiling as they progress right.
##
## Abilities on entry: jump + sideways + wall-jump. Gravity reset in
## _ready(). Spike clusters on both surfaces punish mistimed jumps.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const TRIGGER_SCENE := preload("res://scenes/objects/gravity_trigger.tscn")
const SPIKE_SCENE := preload("res://scenes/objects/hazard_spike.tscn")

const CORRIDOR_LEFT_WALL: int = -1
const CORRIDOR_RIGHT_WALL: int = 31
const FLOOR_ROW: int = 14
const CEILING_ROW: int = 8
const INTERIOR_TOP_ROW: int = 9
const INTERIOR_BOTTOM_ROW: int = 13

## Trigger positions (tile x). Each flips gravity 180° once.
const TRIGGER_X_POSITIONS: Array = [8, 16, 24]
## Spike positions — alternating floor/ceiling per segment.
const FLOOR_SPIKE_TILES: Array = [4, 20]    # segments where gravity is normal
const CEILING_SPIKE_TILES: Array = [12, 27] # segments where gravity is inverted


func _ready() -> void:
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_corridor()
	_place_triggers()
	_place_spikes()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_corridor() -> void:
	LevelBuilder.build_hline(tilemap, FLOOR_ROW, 0, 30)
	LevelBuilder.build_hline(tilemap, CEILING_ROW, 0, 30)
	LevelBuilder.build_vline(tilemap, CORRIDOR_LEFT_WALL, CEILING_ROW, FLOOR_ROW)
	LevelBuilder.build_vline(tilemap, CORRIDOR_RIGHT_WALL, CEILING_ROW, FLOOR_ROW)


func _place_triggers() -> void:
	for tile_x in TRIGGER_X_POSITIONS:
		var trigger := TRIGGER_SCENE.instantiate()
		# Place trigger center in the middle of the corridor height.
		var center_y: float = (INTERIOR_TOP_ROW + INTERIOR_BOTTOM_ROW) * 16.0 + 16.0
		trigger.position = Vector2(int(tile_x) * 32 + 16, center_y)
		trigger.size = Vector2(32, 160)  # 1 tile wide, interior height
		trigger.rotation_direction = 2   # 180° flip
		add_child(trigger)


func _place_spikes() -> void:
	# Floor-mounted: base at floor top, spikes point up.
	for tile_x in FLOOR_SPIKE_TILES:
		var spike := SPIKE_SCENE.instantiate()
		spike.position = Vector2(int(tile_x) * 32 + 16, FLOOR_ROW * 32)
		spike.spike_count = 2
		add_child(spike)
	# Ceiling-mounted: base at ceiling bottom, spikes point down (180° rotation).
	for tile_x in CEILING_SPIKE_TILES:
		var spike := SPIKE_SCENE.instantiate()
		spike.position = Vector2(int(tile_x) * 32 + 16, CEILING_ROW * 32 + 32)
		spike.rotation = PI
		spike.spike_count = 2
		add_child(spike)


func _place_exit() -> void:
	# Player ends on the ceiling after three flips, so the exit sits on the
	# ceiling at the far right. Exit center placed so a ceiling-walking
	# player's body overlaps it cleanly.
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(29 * 32 + 16, CEILING_ROW * 32 + 48)
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		CORRIDOR_LEFT_WALL - 2,
		CORRIDOR_RIGHT_WALL + 2,
		CEILING_ROW - 4,
		FLOOR_ROW + 4,
	)
