extends Node2D

## W1-L2 — Three Tier Tempo
##
## Same spawn shape as W1-L1 — small platform over pitfalls — but now three
## moving platforms stack above the player, each one jump apart. Each is a
## little faster than the one below, so the timing window tightens as the
## player climbs. The exit hovers one jump above the top platform.
##
## Jump only: no sideways movement, no wall jump, no gravity, no dilation,
## no era shift.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/moving_platform.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")

const SPAWN_PLATFORM_ROW: int = 12
const SPAWN_PLATFORM_HALF_WIDTH: int = 2

## One "jump distance" in pixels. Jump peak is ~127 px, so 112 gives a
## comfortable margin while staying recognizably within one jump.
const JUMP_DISTANCE: float = 112.0

## Spawn-platform feet Y — matches SPAWN_PLATFORM_ROW * 32.
const SPAWN_FEET_Y: float = 384.0

## Each moving platform's vertical center. Top of the platform collision is
## 8 px above (platform_height = 16).
const PLATFORM_HALF_HEIGHT: float = 8.0
const PLATFORM_1_Y: float = SPAWN_FEET_Y - JUMP_DISTANCE + PLATFORM_HALF_HEIGHT    # 280
const PLATFORM_2_Y: float = PLATFORM_1_Y - JUMP_DISTANCE                           # 168
const PLATFORM_3_Y: float = PLATFORM_2_Y - JUMP_DISTANCE                           # 56

const EXIT_POSITION: Vector2 = Vector2(0, PLATFORM_3_Y - PLATFORM_HALF_HEIGHT - JUMP_DISTANCE)

## Horizontal oscillation range (same for all three so a straight jump always
## has a window where the next platform passes overhead).
const PLATFORM_X_RANGE: float = 160.0
const PLATFORM_WIDTH: float = 64.0

## Each platform is a little faster than the previous.
const PLATFORM_1_SPEED: float = 60.0
const PLATFORM_2_SPEED: float = 100.0
const PLATFORM_3_SPEED: float = 160.0


func _ready() -> void:
	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_spawn_platform()
	_place_moving_platform(PLATFORM_1_Y, PLATFORM_1_SPEED, 0.0)
	_place_moving_platform(PLATFORM_2_Y, PLATFORM_2_SPEED, PLATFORM_X_RANGE)
	_place_moving_platform(PLATFORM_3_Y, PLATFORM_3_SPEED, -PLATFORM_X_RANGE)
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


## Place a moving platform at the given height and speed, starting at
## start_x on its horizontal track (so adjacent platforms can begin with
## offset phases).
func _place_moving_platform(y: float, speed: float, start_x: float) -> void:
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
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = EXIT_POSITION
	add_child(exit_portal)


func _add_kill_zone() -> void:
	# Taller bounds than W1-L1 since the player climbs significantly.
	# Top kill wall is well above the exit so a miss lands in the void.
	LevelBuilder.add_kill_zones(self, player, -10, 10, -12, 18)
