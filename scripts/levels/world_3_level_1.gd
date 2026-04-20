extends Node2D

## W3-1 — The Ceiling Loop
##
## Three enclosed shafts placed at distinct x-offsets. The player wall-jumps
## up each shaft; a teleport seam placed above the shaft's landing platform
## flings them into the next shaft's floor area. The third shaft swaps its
## seam for the level exit.
##
## Player abilities on entry: jump + sideways + wall-jump. Gravity is reset
## in _ready() so a mid-flip death from W3-2 or W3-3 doesn't persist.

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const SEAM_SCENE := preload("res://scenes/objects/teleport_seam.tscn")

const SHAFT_LEFT_OUTER: int = 0
const SHAFT_RIGHT_OUTER: int = 8
const SHAFT_TOP: int = 2
const SHAFT_BOTTOM: int = 14
const LANDING_PLATFORM_ROW: int = 6
const LANDING_PLATFORM_HALF: int = 1  # 3 tiles wide centered on shaft-x
const SEAM_TILE_ROW: int = 3
const EMERGE_TILE_ROW: int = 13

## Shaft center-x tiles. Shafts sit 28 tiles apart so teleports visibly
## fling the camera across the screen.
const SHAFT_A_CENTER: int = -36
const SHAFT_B_CENTER: int = 0
const SHAFT_C_CENTER: int = 36
const SHAFT_HALF_WIDTH: int = 4  # 4 tiles either side of center → 8-wide shaft


func _ready() -> void:
	# Reset gravity so a mid-flip respawn from another W3 level doesn't
	# carry rotation into this jump-only-looking scene.
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap.tile_set = LevelBuilder.create_tileset()
	_build_shaft(SHAFT_A_CENTER)
	_build_shaft(SHAFT_B_CENTER)
	_build_shaft(SHAFT_C_CENTER)
	_place_seams()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _build_shaft(center_x: int) -> void:
	var left_wall: int = center_x - SHAFT_HALF_WIDTH
	var right_wall: int = center_x + SHAFT_HALF_WIDTH
	# Floor and ceiling.
	LevelBuilder.build_hline(tilemap, SHAFT_BOTTOM, left_wall, right_wall)
	LevelBuilder.build_hline(tilemap, SHAFT_TOP, left_wall, right_wall)
	# Walls.
	LevelBuilder.build_vline(tilemap, left_wall, SHAFT_TOP, SHAFT_BOTTOM)
	LevelBuilder.build_vline(tilemap, right_wall, SHAFT_TOP, SHAFT_BOTTOM)
	# Landing platform — resting point before the final jump into the seam.
	LevelBuilder.build_hline(
		tilemap,
		LANDING_PLATFORM_ROW,
		center_x - LANDING_PLATFORM_HALF,
		center_x + LANDING_PLATFORM_HALF,
	)


func _place_seams() -> void:
	# Source seam in each shaft at (center, SEAM_TILE_ROW); partner at the
	# next shaft's (center, EMERGE_TILE_ROW). preserve_offset=false gives
	# clean emergence positions.
	var seam_a_top := _make_seam(Vector2i(SHAFT_A_CENTER, SEAM_TILE_ROW))
	var seam_b_bottom := _make_seam(Vector2i(SHAFT_B_CENTER, EMERGE_TILE_ROW))
	var seam_b_top := _make_seam(Vector2i(SHAFT_B_CENTER, SEAM_TILE_ROW))
	var seam_c_bottom := _make_seam(Vector2i(SHAFT_C_CENTER, EMERGE_TILE_ROW))

	seam_a_top.partner_path = seam_a_top.get_path_to(seam_b_bottom)
	seam_b_bottom.partner_path = seam_b_bottom.get_path_to(seam_a_top)
	seam_b_top.partner_path = seam_b_top.get_path_to(seam_c_bottom)
	seam_c_bottom.partner_path = seam_c_bottom.get_path_to(seam_b_top)


func _make_seam(tile_pos: Vector2i) -> Area2D:
	var seam := SEAM_SCENE.instantiate()
	seam.position = LevelBuilder.tile_to_world(tile_pos)
	seam.seam_width = 32.0
	seam.seam_height = 16.0
	seam.preserve_offset = false
	add_child(seam)
	return seam


func _place_exit() -> void:
	var exit_portal := EXIT_SCENE.instantiate()
	# Position the exit where C's top seam would have been — player
	# reaches it by wall-jumping up the third shaft.
	exit_portal.position = LevelBuilder.tile_to_world(Vector2i(SHAFT_C_CENTER, SEAM_TILE_ROW))
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player,
		SHAFT_A_CENTER - SHAFT_HALF_WIDTH - 2,
		SHAFT_C_CENTER + SHAFT_HALF_WIDTH + 2,
		SHAFT_TOP - 4,
		SHAFT_BOTTOM + 2,
	)
