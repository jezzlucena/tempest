extends Node2D

## W1-L1 — The Still Plaza (first level)
##
## The player spawns on a small platform surrounded by pitfalls. A single
## moving platform oscillates overhead. The level exit hovers about one
## jump above the moving platform, in the middle of the arena.
##
## The only available ability in this level is Jump. Sideways movement,
## wall jump, gravity, dilation and era shift are all locked. See WORLDS.md.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/moving_platform.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")

## Tile row for the spawn platform. 5 tiles wide, centered on x=0.
const SPAWN_PLATFORM_ROW: int = 12
const SPAWN_PLATFORM_HALF_WIDTH: int = 2  # tiles each side of center

## Moving platform hovers between MOVING_PLATFORM_X_MIN/MAX at MOVING_PLATFORM_Y.
const MOVING_PLATFORM_Y: float = 304.0
const MOVING_PLATFORM_X_MIN: float = -160.0
const MOVING_PLATFORM_X_MAX: float = 160.0
const MOVING_PLATFORM_SPEED: float = 60.0
const MOVING_PLATFORM_WIDTH: float = 64.0

## Level exit position. ~1 jump (128 px) above the moving platform top,
## placed out of direct reach from the spawn platform.
const EXIT_POSITION: Vector2 = Vector2(0, 168)


func _ready() -> void:
	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_spawn_platform()
	_place_moving_platform()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_spawn_platform() -> void:
	LevelBuilder.build_hline(
		tilemap,
		SPAWN_PLATFORM_ROW,
		-SPAWN_PLATFORM_HALF_WIDTH,
		SPAWN_PLATFORM_HALF_WIDTH,
	)


func _place_moving_platform() -> void:
	var mp := PLATFORM_SCENE.instantiate()
	mp.position = Vector2((MOVING_PLATFORM_X_MIN + MOVING_PLATFORM_X_MAX) * 0.5, MOVING_PLATFORM_Y)
	mp.waypoints = [
		Vector2(MOVING_PLATFORM_X_MIN, MOVING_PLATFORM_Y),
		Vector2(MOVING_PLATFORM_X_MAX, MOVING_PLATFORM_Y),
	]
	mp.speed = MOVING_PLATFORM_SPEED
	mp.platform_width = MOVING_PLATFORM_WIDTH
	add_child(mp)


func _place_exit() -> void:
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = EXIT_POSITION
	add_child(exit_portal)


func _add_kill_zone() -> void:
	# Tight bounds: anything off the spawn platform drops into a kill zone.
	# Left/right pits extend far enough that even a flung body dies cleanly.
	LevelBuilder.add_kill_zones(self, player, -10, 10, -6, 18)
