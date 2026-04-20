extends Node2D

## W1-L3 — Sentry Gate
##
## Walled column with three stacked moving platforms (like W1-L2). The left
## wall seals the column along the entire height, but the right wall stops
## below the top platform — so the topmost platform extends past it. Riding
## it to its rightmost extent and dropping lands the player in an arena
## containing the W1 boss, a patrolling sentinel.
##
## Defeating the sentinel grants the sideways-movement ability, spawns an
## exit portal, and advances the player onward. Jump is still the only
## pre-boss ability.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/moving_platform.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const SENTINEL_SCENE := preload("res://scenes/enemies/sentinel.tscn")

const SPAWN_PLATFORM_ROW: int = 12
const SPAWN_PLATFORM_HALF_WIDTH: int = 2

## Platform stack — matches W1-L2's spacing so muscle memory carries over.
const JUMP_DISTANCE: float = 112.0
const SPAWN_FEET_Y: float = 384.0
const PLATFORM_HALF_HEIGHT: float = 8.0
const PLATFORM_1_Y: float = SPAWN_FEET_Y - JUMP_DISTANCE + PLATFORM_HALF_HEIGHT  # 280
const PLATFORM_2_Y: float = PLATFORM_1_Y - JUMP_DISTANCE                         # 168
const PLATFORM_3_Y: float = PLATFORM_2_Y - JUMP_DISTANCE                         # 56
const PLATFORM_WIDTH: float = 64.0

## Column walls. Left seals the full column; right stops below P3 so only P3
## can pass over it.
const COLUMN_LEFT_TILE: int = -8
const COLUMN_RIGHT_TILE: int = 8
const COLUMN_TOP_TILE: int = -2
const RIGHT_WALL_TOP_TILE: int = 3

## Platform horizontal ranges. P1 and P2 are fenced by both walls. P3 is
## fenced only by the left wall — its right extent reaches into the arena's
## vertical corridor so the player can ride it over and drop down.
const COLUMN_PLATFORM_X: float = 200.0
const P3_LEFT_X: float = -200.0
const P3_RIGHT_X: float = 400.0

const P1_SPEED: float = 60.0
const P2_SPEED: float = 100.0
const P3_SPEED: float = 160.0

## Arena to the right of the right wall.
const ARENA_FLOOR_ROW: int = 14
const ARENA_RIGHT_TILE: int = 18


func _ready() -> void:
	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_column_walls()
	_build_spawn_platform()
	_build_arena()
	_place_moving_platforms()
	_spawn_sentinel()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_column_walls() -> void:
	LevelBuilder.build_vline(tilemap, COLUMN_LEFT_TILE, COLUMN_TOP_TILE, ARENA_FLOOR_ROW)
	LevelBuilder.build_vline(tilemap, COLUMN_RIGHT_TILE, RIGHT_WALL_TOP_TILE, ARENA_FLOOR_ROW)


func _build_spawn_platform() -> void:
	LevelBuilder.build_hline(
		tilemap,
		SPAWN_PLATFORM_ROW,
		-SPAWN_PLATFORM_HALF_WIDTH,
		SPAWN_PLATFORM_HALF_WIDTH,
	)


func _build_arena() -> void:
	LevelBuilder.build_hline(tilemap, ARENA_FLOOR_ROW, COLUMN_RIGHT_TILE, ARENA_RIGHT_TILE)
	LevelBuilder.build_vline(tilemap, ARENA_RIGHT_TILE, COLUMN_TOP_TILE, ARENA_FLOOR_ROW)


func _place_moving_platforms() -> void:
	_place_platform(PLATFORM_1_Y, P1_SPEED, -COLUMN_PLATFORM_X, COLUMN_PLATFORM_X, 0.0)
	_place_platform(PLATFORM_2_Y, P2_SPEED, -COLUMN_PLATFORM_X, COLUMN_PLATFORM_X, COLUMN_PLATFORM_X)
	_place_platform(PLATFORM_3_Y, P3_SPEED, P3_LEFT_X, P3_RIGHT_X, P3_LEFT_X)


func _place_platform(y: float, speed: float, x_min: float, x_max: float, start_x: float) -> void:
	var mp := PLATFORM_SCENE.instantiate()
	mp.position = Vector2(start_x, y)
	mp.waypoints = [Vector2(x_min, y), Vector2(x_max, y)]
	mp.speed = speed
	mp.platform_width = PLATFORM_WIDTH
	add_child(mp)


func _spawn_sentinel() -> void:
	var sentinel := SENTINEL_SCENE.instantiate()
	var floor_y: float = ARENA_FLOOR_ROW * 32
	var arena_left_x: float = (COLUMN_RIGHT_TILE + 1) * 32
	var arena_right_x: float = ARENA_RIGHT_TILE * 32
	sentinel.position = Vector2((arena_left_x + arena_right_x) * 0.5, floor_y)
	sentinel.waypoints = [
		Vector2(arena_left_x + 24, floor_y),
		Vector2(arena_right_x - 24, floor_y),
	]
	sentinel.boss_defeated.connect(_on_sentinel_defeated)
	add_child(sentinel)


func _on_sentinel_defeated() -> void:
	# Grant the sideways-movement ability immediately so the player can walk
	# to the exit portal that spawns on the arena floor.
	GameManager.set_ability(GameManager.ABILITY_SIDEWAYS, true)
	var floor_y: float = ARENA_FLOOR_ROW * 32
	var arena_center_x: float = (COLUMN_RIGHT_TILE + ARENA_RIGHT_TILE) * 32 * 0.5
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(arena_center_x, floor_y - 40)
	add_child(exit_portal)

	var canvas := CanvasLayer.new()
	canvas.layer = 15
	var flash := ColorRect.new()
	flash.color = Color(0.5, 0.8, 1.0, 0.35)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(flash)
	add_child(canvas)
	var tween := canvas.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 1.2)
	tween.tween_callback(canvas.queue_free)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		COLUMN_LEFT_TILE - 2,
		ARENA_RIGHT_TILE + 2,
		COLUMN_TOP_TILE - 2,
		ARENA_FLOOR_ROW + 2,
	)
