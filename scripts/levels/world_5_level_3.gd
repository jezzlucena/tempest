extends Node2D

## W5-3 — The Archivist
##
## Square walled arena layered across all three eras. The boss drifts near
## the centre; every cycle it forces an era shift and spawns an era-locked
## weak-point at that era's authored pocket. The player must reach the
## pocket and touch the weak-point while the required era is active.
##
## Walls are identical in every era so the shift can never embed the
## player. Era palette only affects the floor/ceiling/walls colour.

@onready var tilemap_past: TileMapLayer = $TileMapPast
@onready var tilemap_present: TileMapLayer = $TileMapPresent
@onready var tilemap_future: TileMapLayer = $TileMapFuture
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const ARCHIVIST_SCENE := preload("res://scenes/enemies/archivist.tscn")

const ERA_COLOR_PAST := Color(0.45, 0.38, 0.25)
const ERA_COLOR_PRESENT := Color(0.28, 0.28, 0.33)
const ERA_COLOR_FUTURE := Color(0.2, 0.25, 0.42)

const ARENA_LEFT_TILE: int = -9
const ARENA_RIGHT_TILE: int = 9
const ARENA_CEILING_TILE: int = -6
const ARENA_FLOOR_TILE: int = 7

const ARENA_CENTER: Vector2 = Vector2(0.0, 32.0)

## Weak-point pocket per era. Kept distinct so the player learns to read
## the era-tint on the boss's halo and sprint to the matching pocket.
const ERA_POCKETS: Dictionary = {
	int(TimeManager.Era.PAST): Vector2(-200.0, -64.0),    # top-left
	int(TimeManager.Era.PRESENT): Vector2(200.0, -64.0),  # top-right
	int(TimeManager.Era.FUTURE): Vector2(0.0, 160.0),     # bottom centre
}


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

	_build_arena()
	_spawn_archivist()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _all_tilemaps() -> Array:
	return [tilemap_past, tilemap_present, tilemap_future]


func _build_arena() -> void:
	# Same walls in every era → no risk of an era shift embedding the player.
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, ARENA_FLOOR_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
		LevelBuilder.build_hline(tm, ARENA_CEILING_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
		LevelBuilder.build_vline(tm, ARENA_LEFT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)
		LevelBuilder.build_vline(tm, ARENA_RIGHT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)


func _spawn_archivist() -> void:
	var boss := ARCHIVIST_SCENE.instantiate()
	boss.arena_center = ARENA_CENTER
	boss.era_pockets = ERA_POCKETS.duplicate()
	boss.global_position = ARENA_CENTER
	boss.boss_defeated.connect(_on_archivist_defeated)
	add_child(boss)


func _on_archivist_defeated() -> void:
	GameManager.set_ability(GameManager.ABILITY_ERA_SHIFT, true)
	# Reset to Present so the exit and post-fight world read cleanly.
	TimeManager.current_era = TimeManager.Era.PRESENT
	LevelStateManager.swap_era(TimeManager.Era.PRESENT)
	TimeManager.era_changed.emit(TimeManager.current_era)

	var floor_y: float = ARENA_FLOOR_TILE * 32
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(0.0, floor_y - 40.0)
	add_child(exit_portal)

	var canvas := CanvasLayer.new()
	canvas.layer = 15
	var flash := ColorRect.new()
	flash.color = Color(0.95, 0.9, 0.8, 0.45)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(flash)
	add_child(canvas)
	var tween := canvas.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 1.6)
	tween.tween_callback(canvas.queue_free)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		ARENA_LEFT_TILE - 2,
		ARENA_RIGHT_TILE + 2,
		ARENA_CEILING_TILE - 2,
		ARENA_FLOOR_TILE + 2,
	)
