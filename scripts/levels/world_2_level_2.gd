extends Node2D

## W2-2 — The Narrow Shaft
##
## A tall enclosed shaft. The player climbs from the floor to the top via
## six 4-tile ledges that alternate between the right and left walls and
## overlap by a single tile at x=0. The overlap tile is the "safe" straight-
## up jump; veering away from it overshoots into the opposite wall.
##
## Jump + sideways only — no wall-slide (that arrives with the W2 boss).

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")

const SHAFT_LEFT_WALL_TILE: int = -4
const SHAFT_RIGHT_WALL_TILE: int = 4
const SHAFT_TOP_TILE: int = -10
const SHAFT_FLOOR_TILE: int = 18


func _ready() -> void:
	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_shaft()
	_build_ledges()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_shaft() -> void:
	# Walls, ceiling, and floor — seal the shaft.
	LevelBuilder.build_vline(tilemap, SHAFT_LEFT_WALL_TILE, SHAFT_TOP_TILE, SHAFT_FLOOR_TILE)
	LevelBuilder.build_vline(tilemap, SHAFT_RIGHT_WALL_TILE, SHAFT_TOP_TILE, SHAFT_FLOOR_TILE)
	LevelBuilder.build_hline(tilemap, SHAFT_TOP_TILE, SHAFT_LEFT_WALL_TILE, SHAFT_RIGHT_WALL_TILE)
	LevelBuilder.build_hline(tilemap, SHAFT_FLOOR_TILE, SHAFT_LEFT_WALL_TILE + 1, SHAFT_RIGHT_WALL_TILE - 1)


func _build_ledges() -> void:
	# Alternating-wall ledges, overlapping by one tile at x=0.
	LevelBuilder.build_hline(tilemap, 15, 0, 3)    # right-wall ledge
	LevelBuilder.build_hline(tilemap, 12, -3, 0)   # left-wall ledge
	LevelBuilder.build_hline(tilemap, 9, 0, 3)
	LevelBuilder.build_hline(tilemap, 6, -3, 0)
	LevelBuilder.build_hline(tilemap, 3, 0, 3)
	LevelBuilder.build_hline(tilemap, 0, -3, 0)    # top ledge — exit sits here


func _place_exit() -> void:
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = LevelBuilder.tile_to_world(Vector2i(-2, -1))
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		SHAFT_LEFT_WALL_TILE - 2,
		SHAFT_RIGHT_WALL_TILE + 2,
		SHAFT_TOP_TILE - 2,
		SHAFT_FLOOR_TILE + 2,
	)
