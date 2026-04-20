extends Node2D

## W4-1 — Bullet Storm Gallery
##
## Horizontal corridor lined with stationary turrets. Three fire DOWN from
## the ceiling, three fire UP from the floor, staggered so the player can
## always find a gap by reading the rhythm. No dilation yet — this is a
## pure timing challenge that previews the hazards the boss will intensify.
##
## Gravity is reset on _ready() in case the player dies carrying a
## rotation from W3-2 or W3-3.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const EMITTER_SCENE := preload("res://scenes/objects/projectile_emitter.tscn")

const CORRIDOR_LEFT_WALL: int = -1
const CORRIDOR_RIGHT_WALL: int = 31
const FLOOR_ROW: int = 14
const CEILING_ROW: int = 8

const FIRE_INTERVAL: float = 1.8
const PROJECTILE_SPEED: float = 220.0

## [tile_x, start_delay] pairs.
const CEILING_TURRETS: Array = [
	[5, 0.0],
	[15, 0.6],
	[25, 1.2],
]
const FLOOR_TURRETS: Array = [
	[10, 0.3],
	[20, 0.9],
	[28, 1.5],
]


func _ready() -> void:
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_corridor()
	_place_turrets()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_corridor() -> void:
	LevelBuilder.build_hline(tilemap, FLOOR_ROW, 0, 30)
	LevelBuilder.build_hline(tilemap, CEILING_ROW, 0, 30)
	LevelBuilder.build_vline(tilemap, CORRIDOR_LEFT_WALL, CEILING_ROW, FLOOR_ROW)
	LevelBuilder.build_vline(tilemap, CORRIDOR_RIGHT_WALL, CEILING_ROW, FLOOR_ROW)


func _place_turrets() -> void:
	for turret_data in CEILING_TURRETS:
		_add_turret(
			Vector2(int(turret_data[0]) * 32 + 16, (CEILING_ROW + 1) * 32),
			Vector2.DOWN,
			float(turret_data[1]),
		)
	for turret_data in FLOOR_TURRETS:
		_add_turret(
			Vector2(int(turret_data[0]) * 32 + 16, FLOOR_ROW * 32),
			Vector2.UP,
			float(turret_data[1]),
		)


func _add_turret(pos: Vector2, dir: Vector2, start_delay: float) -> void:
	var emitter := EMITTER_SCENE.instantiate()
	emitter.position = pos
	emitter.direction = dir
	emitter.projectile_speed = PROJECTILE_SPEED
	emitter.fire_interval = FIRE_INTERVAL
	emitter.start_delay = start_delay
	add_child(emitter)


func _place_exit() -> void:
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(29 * 32 + 16, FLOOR_ROW * 32 - 40)
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		CORRIDOR_LEFT_WALL - 2,
		CORRIDOR_RIGHT_WALL + 2,
		CEILING_ROW - 4,
		FLOOR_ROW + 4,
	)
