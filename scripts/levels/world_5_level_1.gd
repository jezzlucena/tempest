extends Node2D

## W5-1 — The Stacked Archive
##
## Horizontal corridor layered across three eras. A gap is bridged only
## in Past, and a wall is absent only in Future. Era triggers along the
## way switch the player to the required era before each obstacle. The
## player never gains agency — triggers do the shifting — but by the end
## they've seen every era's geometry.

@onready var tilemap_past: TileMapLayer = $TileMapPast
@onready var tilemap_present: TileMapLayer = $TileMapPresent
@onready var tilemap_future: TileMapLayer = $TileMapFuture
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const TRIGGER_SCENE := preload("res://scenes/objects/era_trigger.tscn")

## Era palette — matches level_2.gd / level_3.gd conventions.
const ERA_COLOR_PAST := Color(0.45, 0.38, 0.25)
const ERA_COLOR_PRESENT := Color(0.28, 0.28, 0.33)
const ERA_COLOR_FUTURE := Color(0.2, 0.25, 0.42)

const FLOOR_ROW: int = 14
const CEILING_ROW: int = 0


func _ready() -> void:
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap_past.tile_set = LevelBuilder.create_tileset(ERA_COLOR_PAST)
	tilemap_present.tile_set = LevelBuilder.create_tileset(ERA_COLOR_PRESENT)
	tilemap_future.tile_set = LevelBuilder.create_tileset(ERA_COLOR_FUTURE)

	LevelStateManager.clear_layers()
	LevelStateManager.register_era_layer(TimeManager.Era.PAST, tilemap_past)
	LevelStateManager.register_era_layer(TimeManager.Era.PRESENT, tilemap_present)
	LevelStateManager.register_era_layer(TimeManager.Era.FUTURE, tilemap_future)

	TimeManager.current_era = TimeManager.Era.PRESENT
	LevelStateManager.swap_era(TimeManager.Era.PRESENT)

	_build_common()
	_build_past_specific()
	_build_present_specific()
	_place_triggers()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _all_tilemaps() -> Array:
	return [tilemap_past, tilemap_present, tilemap_future]


func _build_common() -> void:
	# Shared geometry across every era: entry platform, post-gap floor,
	# ceiling, side walls.
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, FLOOR_ROW, 0, 8)
		LevelBuilder.build_hline(tm, FLOOR_ROW, 15, 50)
		LevelBuilder.build_hline(tm, CEILING_ROW, 0, 50)
		LevelBuilder.build_vline(tm, -1, CEILING_ROW, FLOOR_ROW)
		LevelBuilder.build_vline(tm, 51, CEILING_ROW, FLOOR_ROW)


## Past is the only era that bridges the gap at x=9..14.
func _build_past_specific() -> void:
	LevelBuilder.build_hline(tilemap_past, FLOOR_ROW, 9, 14)
	# Past also has the wall at x=23 — same as Present. Only Future is clear.
	LevelBuilder.build_vline(tilemap_past, 23, 8, 13)


## Present has the wall at x=23 but no bridge.
func _build_present_specific() -> void:
	LevelBuilder.build_vline(tilemap_present, 23, 8, 13)


func _place_triggers() -> void:
	# Past trigger — right before the gap.
	_add_trigger(Vector2(7 * 32 + 16, 13 * 32), int(TimeManager.Era.PAST))
	# Future trigger — after the gap, before the wall.
	_add_trigger(Vector2(20 * 32 + 16, 13 * 32), int(TimeManager.Era.FUTURE))


func _add_trigger(pos: Vector2, target_era: int) -> void:
	var trigger := TRIGGER_SCENE.instantiate()
	trigger.position = pos
	trigger.target_era = target_era
	trigger.size = Vector2(32, 192)
	add_child(trigger)


func _place_exit() -> void:
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(48 * 32 + 16, FLOOR_ROW * 32 - 40)
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(self, player, -3, 52, -2, FLOOR_ROW + 4)
