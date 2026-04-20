extends Node2D

## W4-3 — The Phantom
##
## Walled arena with four permanent dilation fields in the corners. The
## phantom boss drifts near the centre firing radial projectile bursts.
## Every cycle it marks a random dilation field by spawning a weak point
## inside it; the player must reach that field (slowing the projectiles
## inside to a navigable speed) and strike the weak-point. Three hits
## defeats the boss and grants ABILITY_DILATION.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const PHANTOM_SCENE := preload("res://scenes/enemies/phantom.tscn")
const DILATION_SCENE := preload("res://scenes/objects/dilation_field.tscn")

const ARENA_LEFT_TILE: int = -9
const ARENA_RIGHT_TILE: int = 9
const ARENA_CEILING_TILE: int = -6
const ARENA_FLOOR_TILE: int = 7

const ARENA_CENTER: Vector2 = Vector2(0.0, 32.0)

## Corner positions for the four permanent dilation fields, ~4 tiles
## inside the walls.
const FIELD_POSITIONS: Array = [
	Vector2(-160, -32),  # top-left
	Vector2( 160, -32),  # top-right
	Vector2(-160,  96),  # bottom-left
	Vector2( 160,  96),  # bottom-right
]


func _ready() -> void:
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_arena()
	_place_dilation_fields()
	_spawn_phantom()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_arena() -> void:
	LevelBuilder.build_hline(tilemap, ARENA_FLOOR_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
	LevelBuilder.build_hline(tilemap, ARENA_CEILING_TILE, ARENA_LEFT_TILE, ARENA_RIGHT_TILE)
	LevelBuilder.build_vline(tilemap, ARENA_LEFT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)
	LevelBuilder.build_vline(tilemap, ARENA_RIGHT_TILE, ARENA_CEILING_TILE, ARENA_FLOOR_TILE)


func _place_dilation_fields() -> void:
	for pos in FIELD_POSITIONS:
		var field := DILATION_SCENE.instantiate()
		field.permanent = true
		field.global_position = pos
		add_child(field)


func _spawn_phantom() -> void:
	var phantom := PHANTOM_SCENE.instantiate()
	phantom.arena_center = ARENA_CENTER
	phantom.global_position = ARENA_CENTER
	phantom.boss_defeated.connect(_on_phantom_defeated)
	add_child(phantom)


func _on_phantom_defeated() -> void:
	GameManager.set_ability(GameManager.ABILITY_DILATION, true)
	var floor_y: float = ARENA_FLOOR_TILE * 32
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(0.0, floor_y - 40.0)
	add_child(exit_portal)

	var canvas := CanvasLayer.new()
	canvas.layer = 15
	var flash := ColorRect.new()
	flash.color = Color(0.5, 0.7, 1.0, 0.4)
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
