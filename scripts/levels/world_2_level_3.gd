extends Node2D

## W2-3 — The Wall Crawler
##
## Enclosed chamber: floor, ceiling, and side walls. The spider boss begins
## clung to the ceiling and cycles: ceiling patrol (firing webs) → drop →
## floor patrol (stompable) → climb back up. Three stomps defeats it.
##
## Defeating the spider grants the wall-jump ability, spawns an exit portal
## on the floor, and plays a flash cinematic.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const SPIDER_SCENE := preload("res://scenes/enemies/spider.tscn")

const ARENA_LEFT_TILE: int = -8
const ARENA_RIGHT_TILE: int = 8
const ARENA_CEILING_TILE: int = -2
const ARENA_FLOOR_TILE: int = 14

## Spider center Y values. The spider's body is a circle of radius 22, so
## on the ceiling its center sits 22 px below the ceiling surface, and on
## the floor its center sits 22 px above the floor surface.
const SPIDER_RADIUS: float = 22.0


func _ready() -> void:
	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_arena()
	_spawn_spider()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_arena() -> void:
	# Floor, ceiling, and side walls — fully enclosed.
	LevelBuilder.build_hline(tilemap, ARENA_FLOOR_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
	LevelBuilder.build_hline(tilemap, ARENA_CEILING_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
	LevelBuilder.build_vline(tilemap, ARENA_LEFT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)
	LevelBuilder.build_vline(tilemap, ARENA_RIGHT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)


func _spawn_spider() -> void:
	var spider := SPIDER_SCENE.instantiate()
	var ceiling_surface_y: float = (ARENA_CEILING_TILE + 1) * 32.0  # bottom face of ceiling tile
	var floor_surface_y: float = ARENA_FLOOR_TILE * 32.0            # top face of floor tile
	spider.ceiling_y = ceiling_surface_y + SPIDER_RADIUS
	spider.floor_y = floor_surface_y - SPIDER_RADIUS
	spider.patrol_left_x = (ARENA_LEFT_TILE + 1) * 32.0 + SPIDER_RADIUS + 8.0
	spider.patrol_right_x = ARENA_RIGHT_TILE * 32.0 - SPIDER_RADIUS - 8.0
	spider.global_position = Vector2(0.0, spider.ceiling_y)
	spider.boss_defeated.connect(_on_spider_defeated)
	add_child(spider)


func _on_spider_defeated() -> void:
	GameManager.set_ability(GameManager.ABILITY_WALL_JUMP, true)
	var floor_y: float = ARENA_FLOOR_TILE * 32.0
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(0.0, floor_y - 40.0)
	add_child(exit_portal)

	var canvas := CanvasLayer.new()
	canvas.layer = 15
	var flash := ColorRect.new()
	flash.color = Color(0.7, 0.9, 1.0, 0.35)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(flash)
	add_child(canvas)
	var tween := canvas.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 1.2)
	tween.tween_callback(canvas.queue_free)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		ARENA_LEFT_TILE - 2,
		ARENA_RIGHT_TILE + 2,
		ARENA_CEILING_TILE - 2,
		ARENA_FLOOR_TILE + 2,
	)
