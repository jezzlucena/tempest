extends Node2D

## W3-3 — The Tumbler
##
## Square walled arena. The Tumbler cycles CEILING → DROP → FLOOR → CLIMB
## and forces a 90° CW gravity rotation on every successful stomp. Three
## stomps defeats it, granting ABILITY_GRAVITY.
##
## All four sides are solid walls so any of them can become "floor"
## depending on the current gravity angle. Arena center is slightly offset
## because the tile grid is symmetric around tile 0 but the interior's
## inner faces land at (-192, 224) — so arena_center.y = 16.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const TUMBLER_SCENE := preload("res://scenes/enemies/tumbler.tscn")

const ARENA_LEFT_TILE: int = -7
const ARENA_RIGHT_TILE: int = 7
const ARENA_CEILING_TILE: int = -7
const ARENA_FLOOR_TILE: int = 7

const ARENA_CENTER: Vector2 = Vector2(0.0, 16.0)
const TUMBLER_OFFSET: float = 182.0  # distance center → ceiling/floor surface, minus radius
const TUMBLER_PATROL_RANGE: float = 150.0


func _ready() -> void:
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_arena()
	_spawn_tumbler()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_arena() -> void:
	# Four solid walls enclosing the interior.
	LevelBuilder.build_hline(tilemap, ARENA_FLOOR_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
	LevelBuilder.build_hline(tilemap, ARENA_CEILING_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
	LevelBuilder.build_vline(tilemap, ARENA_LEFT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)
	LevelBuilder.build_vline(tilemap, ARENA_RIGHT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)


func _spawn_tumbler() -> void:
	var tumbler := TUMBLER_SCENE.instantiate()
	tumbler.arena_center = ARENA_CENTER
	tumbler.ceiling_offset = TUMBLER_OFFSET
	tumbler.floor_offset = TUMBLER_OFFSET
	tumbler.patrol_range = TUMBLER_PATROL_RANGE
	tumbler.boss_defeated.connect(_on_tumbler_defeated)
	add_child(tumbler)


func _on_tumbler_defeated() -> void:
	GameManager.set_ability(GameManager.ABILITY_GRAVITY, true)

	# Place the exit just off whatever surface is currently "floor" so the
	# player lands on it post-bounce regardless of which rotation phase the
	# fight ended in.
	var up: Vector2 = GravityManager.get_up_direction()
	var floor_pos: Vector2 = ARENA_CENTER - up * TUMBLER_OFFSET
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = floor_pos + up * 24.0
	# Rotate the exit's drawing to read correctly in the current orientation.
	exit_portal.rotation = -GravityManager.gravity_angle_radians
	add_child(exit_portal)

	var canvas := CanvasLayer.new()
	canvas.layer = 15
	var flash := ColorRect.new()
	flash.color = Color(0.6, 0.8, 1.0, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(flash)
	add_child(canvas)
	var tween := canvas.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 1.4)
	tween.tween_callback(canvas.queue_free)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		ARENA_LEFT_TILE - 2,
		ARENA_RIGHT_TILE + 2,
		ARENA_CEILING_TILE - 2,
		ARENA_FLOOR_TILE + 2,
	)
