extends Node2D

## W2-1 — The Rising Stair
##
## Gap-chain of fixed platforms climbing diagonally up and to the right.
## The returning player has jump + sideways, so the level rehearses jump
## rhythm and lateral control. Each step is comfortably within one jump
## (3 tiles vertical, 3-4 tiles lateral).

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")


func _ready() -> void:
	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_platforms()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_platforms() -> void:
	# Spawn ledge (bottom-left).
	LevelBuilder.build_hline(tilemap, 16, -12, -6)
	# Ascending diagonal steps.
	LevelBuilder.build_hline(tilemap, 13, -3, -1)
	LevelBuilder.build_hline(tilemap, 10, 2, 4)
	LevelBuilder.build_hline(tilemap, 7, 7, 9)
	# Final ledge — wider, holds the exit.
	LevelBuilder.build_hline(tilemap, 4, 12, 15)


func _place_exit() -> void:
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = LevelBuilder.tile_to_world(Vector2i(14, 3))
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(self, player, -14, 17, -2, 18)
