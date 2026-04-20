extends Node2D

## W4-2 — Racing Platforms
##
## Enclosed vertical shaft with four moving-platform tiers, each faster
## than the last. Without dilation the player has to time every jump
## precisely; wall-jump is available as a recovery tool if they slip off
## — the side walls reach from the top of the shaft down to the spawn
## platform, so a missed catch doesn't immediately kill.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/moving_platform.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")

const SPAWN_PLATFORM_ROW: int = 12
const SPAWN_PLATFORM_HALF_WIDTH: int = 2

## Proven W1-L2 spacing: ~112 px vertical feels like "one jump with margin".
const JUMP_DISTANCE: float = 112.0
const SPAWN_FEET_Y: float = 384.0
const PLATFORM_HALF_HEIGHT: float = 8.0
const PLATFORM_1_Y: float = SPAWN_FEET_Y - JUMP_DISTANCE + PLATFORM_HALF_HEIGHT  # 280
const PLATFORM_2_Y: float = PLATFORM_1_Y - JUMP_DISTANCE                         # 168
const PLATFORM_3_Y: float = PLATFORM_2_Y - JUMP_DISTANCE                         # 56
const PLATFORM_4_Y: float = PLATFORM_3_Y - JUMP_DISTANCE                         # -56

const PLATFORM_X_RANGE: float = 160.0
const PLATFORM_WIDTH: float = 64.0

## Speeds escalate tier-by-tier.
const PLATFORM_1_SPEED: float = 120.0
const PLATFORM_2_SPEED: float = 220.0
const PLATFORM_3_SPEED: float = 320.0
const PLATFORM_4_SPEED: float = 420.0

const SHAFT_LEFT_WALL: int = -8
const SHAFT_RIGHT_WALL: int = 8
const SHAFT_TOP: int = -10


func _ready() -> void:
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_shaft()
	_build_spawn_platform()
	_place_moving_platforms()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_shaft() -> void:
	# Walls on both sides so a missed tier can be recovered via wall-jump.
	LevelBuilder.build_vline(tilemap, SHAFT_LEFT_WALL, SHAFT_TOP, SPAWN_PLATFORM_ROW)
	LevelBuilder.build_vline(tilemap, SHAFT_RIGHT_WALL, SHAFT_TOP, SPAWN_PLATFORM_ROW)


func _build_spawn_platform() -> void:
	LevelBuilder.build_hline(
		tilemap,
		SPAWN_PLATFORM_ROW,
		-SPAWN_PLATFORM_HALF_WIDTH,
		SPAWN_PLATFORM_HALF_WIDTH,
	)


func _place_moving_platforms() -> void:
	_place_platform(PLATFORM_1_Y, PLATFORM_1_SPEED, 0.0)
	_place_platform(PLATFORM_2_Y, PLATFORM_2_SPEED, PLATFORM_X_RANGE)
	_place_platform(PLATFORM_3_Y, PLATFORM_3_SPEED, -PLATFORM_X_RANGE)
	_place_platform(PLATFORM_4_Y, PLATFORM_4_SPEED, 0.0)


func _place_platform(y: float, speed: float, start_x: float) -> void:
	var mp := PLATFORM_SCENE.instantiate()
	mp.position = Vector2(start_x, y)
	mp.waypoints = [
		Vector2(-PLATFORM_X_RANGE, y),
		Vector2(PLATFORM_X_RANGE, y),
	]
	mp.speed = speed
	mp.platform_width = PLATFORM_WIDTH
	add_child(mp)


func _place_exit() -> void:
	# Exit hovers one jump above the top (fastest) tier, in the middle.
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(0.0, PLATFORM_4_Y - PLATFORM_HALF_HEIGHT - JUMP_DISTANCE)
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		SHAFT_LEFT_WALL - 2,
		SHAFT_RIGHT_WALL + 2,
		SHAFT_TOP - 4,
		SPAWN_PLATFORM_ROW + 4,
	)
