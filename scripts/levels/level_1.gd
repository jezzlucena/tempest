extends Node2D

## Level 1 — "The Ascending Ruin"
##
## Layout (tile coords, 32px tiles):
##   Section 1A (x: 0-50):   The Courtyard — horizontal platforming
##   Section 1B (x: 55-75):  The Sealed Chamber — gravity tutorial room
##   Section 1C (x: 80-100): The Vertical Labyrinth — gravity shaft + Penrose stairs
##   Section 1D (x: 105-135): The Gatehouse — rapid gravity corridor

@onready var tilemap_past: TileMapLayer = $TileMapPast
@onready var tilemap: TileMapLayer = $TileMapPresent  # build target — Present is authoritative
@onready var tilemap_future: TileMapLayer = $TileMapFuture
@onready var player: CharacterBody2D = $Player

const CHECKPOINT_SCENE := preload("res://scenes/objects/checkpoint.tscn")
const SPIKE_SCENE := preload("res://scenes/objects/hazard_spike.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/moving_platform.tscn")
const SEAM_SCENE := preload("res://scenes/objects/teleport_seam.tscn")
const COLLAPSING_SCENE := preload("res://scenes/objects/collapsing_platform.tscn")
const HEALTH_SCENE := preload("res://scenes/objects/health_collectible.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const SHARD_SCENE := preload("res://scenes/objects/infinity_shard.tscn")

## Palette — matches W0-L2/W0-L3 era colours.
const ERA_COLOR_PAST := Color(0.45, 0.38, 0.25)
const ERA_COLOR_PRESENT := Color(0.28, 0.28, 0.33)
const ERA_COLOR_FUTURE := Color(0.2, 0.25, 0.42)

var _built: bool = false


func _ready() -> void:
	# Build all geometry into Present first, then mirror cells to Past and
	# Future so all three era tilemaps have identical collision — a clean
	# era shift, plus a hidden Past-shard pocket the player can only reach
	# after earning era-shift on a later run.
	tilemap.tile_set = LevelBuilder.create_tileset(ERA_COLOR_PRESENT)
	tilemap_past.tile_set = LevelBuilder.create_tileset(ERA_COLOR_PAST)
	tilemap_future.tile_set = LevelBuilder.create_tileset(ERA_COLOR_FUTURE)

	_build_section_1a()
	_build_section_1b()
	_build_section_1c()
	_build_section_1d()
	_mirror_tiles_to_other_eras()

	LevelStateManager.clear_layers()
	LevelStateManager.register_era_layer(TimeManager.Era.PAST, tilemap_past)
	LevelStateManager.register_era_layer(TimeManager.Era.PRESENT, tilemap)
	LevelStateManager.register_era_layer(TimeManager.Era.FUTURE, tilemap_future)
	TimeManager.current_era = TimeManager.Era.PRESENT
	LevelStateManager.swap_era(TimeManager.Era.PRESENT)

	_place_checkpoints()
	_place_hazards()
	_place_moving_platforms()
	_place_collectibles()
	_place_past_shard()
	_add_tutorial_hints()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())
	_built = true


func _mirror_tiles_to_other_eras() -> void:
	# Copy every used cell from Present into Past and Future. LevelBuilder
	# always uses source 0, atlas (0,0) so the fill is trivial.
	for cell in tilemap.get_used_cells():
		tilemap_past.set_cell(cell, LevelBuilder.TILE_SOURCE_ID, Vector2i(0, 0))
		tilemap_future.set_cell(cell, LevelBuilder.TILE_SOURCE_ID, Vector2i(0, 0))


# ── Section 1A — The Courtyard ──────────────────────────────────────────────
func _build_section_1a() -> void:
	# Left wall
	LevelBuilder.build_vline(tilemap, 0, 0, 19)
	# Floor with gaps
	LevelBuilder.build_hline(tilemap, 18, 0, 12)
	LevelBuilder.build_hline(tilemap, 18, 15, 22)
	LevelBuilder.build_hline(tilemap, 18, 26, 35)
	LevelBuilder.build_hline(tilemap, 18, 38, 50)
	# Partial ceiling
	LevelBuilder.build_hline(tilemap, 0, 0, 8)
	# Floating platforms
	LevelBuilder.build_hline(tilemap, 15, 8, 11)
	LevelBuilder.build_hline(tilemap, 12, 18, 20)
	LevelBuilder.build_hline(tilemap, 14, 30, 33)
	# Columns for wall-jump practice
	LevelBuilder.build_vline(tilemap, 7, 13, 17)
	LevelBuilder.build_vline(tilemap, 25, 10, 17)
	# Upper path
	LevelBuilder.build_hline(tilemap, 8, 3, 6)


# ── Section 1B — The Sealed Chamber ─────────────────────────────────────────
func _build_section_1b() -> void:
	var ox := 55
	var room_w := 16
	var room_h := 16
	# Transition corridor
	LevelBuilder.build_hline(tilemap, 18, 50, ox)
	LevelBuilder.build_hline(tilemap, 14, 50, ox)
	# Room walls
	LevelBuilder.build_hline(tilemap, 18, ox, ox + room_w)                  # Floor
	LevelBuilder.build_hline(tilemap, 18 - room_h, ox, ox + 6)             # Ceiling left
	LevelBuilder.build_hline(tilemap, 18 - room_h, ox + 10, ox + room_w)   # Ceiling right (gap = exit)
	LevelBuilder.build_vline(tilemap, ox, 18 - room_h, 14)                 # Left wall (above corridor)
	LevelBuilder.build_vline(tilemap, ox + room_w, 18 - room_h, 18)        # Right wall
	# Landing platform above ceiling exit
	LevelBuilder.build_hline(tilemap, 18 - room_h - 3, ox + 5, ox + 11)
	# Interior platforms
	LevelBuilder.build_hline(tilemap, 13, ox + 3, ox + 6)
	LevelBuilder.build_hline(tilemap, 10, ox + 10, ox + 13)
	# Gravity altar marker
	LevelBuilder.build_rect(tilemap, Vector2i(ox + 7, 17), Vector2i(ox + 9, 17))

	# Exit corridor from 1B ceiling area to 1C
	# After flipping gravity and landing above, walk right to exit
	LevelBuilder.build_hline(tilemap, 18 - room_h - 3, ox + 11, 80)
	LevelBuilder.build_hline(tilemap, 18 - room_h - 6, ox + 11, 80)  # Low ceiling


# ── Section 1C — The Vertical Labyrinth ─────────────────────────────────────
## Tall shaft with platforms on all 4 walls. Gravity rotation required.
## Contains a Penrose stair loop via teleport seams.
func _build_section_1c() -> void:
	var ox := 80
	var shaft_w := 18
	var shaft_h := 30

	var top := -8     # Shaft top y
	var bot := top + shaft_h  # Shaft bottom y

	# Shaft enclosure
	LevelBuilder.build_vline(tilemap, ox, top, bot)                   # Left wall
	LevelBuilder.build_vline(tilemap, ox + shaft_w, top, bot)         # Right wall
	LevelBuilder.build_hline(tilemap, bot, ox, ox + shaft_w)          # Bottom floor
	LevelBuilder.build_hline(tilemap, top, ox, ox + shaft_w)          # Top ceiling

	# Entry from 1B corridor — opening in the left wall near the top
	LevelBuilder.clear_rect(tilemap, Vector2i(ox, -5), Vector2i(ox, -3))

	# ── Platforms on all 4 walls (the player must rotate gravity to traverse) ──

	# BOTTOM side (gravity normal — floor platforms)
	LevelBuilder.build_hline(tilemap, bot - 4, ox + 2, ox + 6)
	LevelBuilder.build_hline(tilemap, bot - 8, ox + 10, ox + 14)

	# RIGHT side (gravity rotated 90° CW — right wall becomes floor)
	LevelBuilder.build_hline(tilemap, bot - 12, ox + 13, ox + 17)
	LevelBuilder.build_hline(tilemap, bot - 18, ox + 14, ox + 17)

	# TOP side (gravity 180° — ceiling becomes floor)
	LevelBuilder.build_hline(tilemap, top + 4, ox + 8, ox + 14)
	LevelBuilder.build_hline(tilemap, top + 3, ox + 2, ox + 5)

	# LEFT side (gravity 270° — left wall becomes floor)
	LevelBuilder.build_hline(tilemap, top + 8, ox + 1, ox + 5)
	LevelBuilder.build_hline(tilemap, top + 14, ox + 1, ox + 4)

	# CENTER floating platform — reachable from multiple orientations
	LevelBuilder.build_rect(tilemap, Vector2i(ox + 8, top + 12), Vector2i(ox + 10, top + 12))

	# ── Penrose stair illusion ──
	# Two teleport seams: one at bottom-left, one at top-right
	# Walking "down" the stairs loops you back to the top
	var seam_a := SEAM_SCENE.instantiate()
	seam_a.name = "SeamA"
	seam_a.position = LevelBuilder.tile_to_world(Vector2i(ox + 3, bot - 2))
	add_child(seam_a)

	var seam_b := SEAM_SCENE.instantiate()
	seam_b.name = "SeamB"
	seam_b.position = LevelBuilder.tile_to_world(Vector2i(ox + 3, top + 6))
	add_child(seam_b)

	# Link them after both are in the tree
	seam_a.partner_path = seam_a.get_path_to(seam_b)
	seam_b.partner_path = seam_b.get_path_to(seam_a)

	# Exit from shaft — opening in right wall near top, leads to 1D
	LevelBuilder.clear_rect(tilemap, Vector2i(ox + shaft_w, top + 2), Vector2i(ox + shaft_w, top + 4))

	# Bridge from shaft exit to 1D
	LevelBuilder.build_hline(tilemap, top + 5, ox + shaft_w, 105)


# ── Section 1D — The Gatehouse ──────────────────────────────────────────────
## Rapid gravity rotation corridor. Checkpoints every two rotations.
## Floor drops away → rotate to wall → wall spikes → rotate to ceiling →
## ceiling gap → rotate to opposite wall → reach exit.
func _build_section_1d() -> void:
	var ox := 105
	var cor_h := 12  # Corridor height in tiles
	var top := -8
	var bot := top + cor_h

	# ── Segment 1: Floor collapses, must rotate to right wall ──
	# Solid start
	LevelBuilder.build_hline(tilemap, bot, ox, ox + 2)
	# Collapsing floor — falls when player steps on it
	_add_collapsing_row(Vector2((ox + 3) * 32 + 16, bot * 32 + 6), 5)
	# Right wall acts as floor when gravity points right
	LevelBuilder.build_vline(tilemap, ox + 10, top, bot)   # Right boundary of seg 1
	# Ceiling
	LevelBuilder.build_hline(tilemap, top, ox, ox + 10)
	# Left wall
	LevelBuilder.build_vline(tilemap, ox, top, bot)
	# Platforms on the right wall (accessible with gravity rotated CW)
	LevelBuilder.build_hline(tilemap, top + 4, ox + 5, ox + 9)

	# ── Segment 2: Walk on ceiling (gravity 180°), gap in ceiling ──
	var ox2 := ox + 11
	LevelBuilder.build_vline(tilemap, ox2 - 1, top, bot)
	LevelBuilder.build_hline(tilemap, top, ox2, ox2 + 4)     # Ceiling (walkable)
	# Gap in ceiling
	LevelBuilder.build_hline(tilemap, top, ox2 + 7, ox2 + 12)  # Ceiling continues
	LevelBuilder.build_hline(tilemap, bot, ox2, ox2 + 12)      # Floor (now acts as ceiling)
	# Right wall of segment 2 / left wall of segment 3 — shared wall with opening
	LevelBuilder.build_vline(tilemap, ox2 + 12, top, top + 3)       # Top portion
	LevelBuilder.build_vline(tilemap, ox2 + 12, top + 7, bot)       # Bottom portion
	# Opening at y=-4 to y=-2 (top+4 to top+6) to pass into segment 3

	# Small platform to bridge the ceiling gap with gravity 180
	LevelBuilder.build_hline(tilemap, top + 2, ox2 + 4, ox2 + 7)

	# ── Segment 3: Rotate back to normal, final stretch ──
	var ox3 := ox2 + 13
	LevelBuilder.build_hline(tilemap, bot, ox3, ox3 + 8)    # Floor
	LevelBuilder.build_hline(tilemap, top, ox3, ox3 + 8)    # Ceiling
	LevelBuilder.build_vline(tilemap, ox3 + 8, top, bot)    # End wall

	# Victory area — a wider chamber at the end
	LevelBuilder.build_rect(tilemap, Vector2i(ox3 + 4, bot - 3), Vector2i(ox3 + 4, bot - 1))

	# Level exit portal
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = LevelBuilder.tile_to_world(Vector2i(ox3 + 6, bot - 2))
	add_child(exit_portal)


func _place_checkpoints() -> void:
	_add_checkpoint(Vector2(28 * 32, 18 * 32))       # Mid 1A
	_add_checkpoint(Vector2(57 * 32, 18 * 32))       # Start of 1B
	_add_checkpoint(Vector2(82 * 32, 20 * 32))       # Start of 1C (bottom of shaft)
	_add_checkpoint(Vector2(90 * 32, -5 * 32))       # Mid 1C (top area)
	_add_checkpoint(Vector2(107 * 32, -3 * 32))      # Start of 1D
	_add_checkpoint(Vector2(120 * 32, -7 * 32))      # Mid 1D (on ceiling when gravity 180)


func _place_hazards() -> void:
	# 1A — spikes in gaps
	_add_spike(Vector2(13.5 * 32, 18 * 32), 2)
	_add_spike(Vector2(24 * 32, 18 * 32), 3)
	_add_spike(Vector2(36.5 * 32, 18 * 32), 2)

	# 1B — wall spikes
	var spike_1b := SPIKE_SCENE.instantiate()
	spike_1b.position = Vector2(70 * 32, 14 * 32)
	spike_1b.rotation = deg_to_rad(-90)
	spike_1b.spike_count = 3
	add_child(spike_1b)

	# 1C — spikes inside the shaft (placed in open space, not inside walls)
	# Bottom spikes (1 tile above floor at y=22)
	_add_spike(Vector2(89 * 32, 21 * 32), 4)
	# Right wall spikes (1 tile inside shaft from right wall at x=98)
	_add_spike(Vector2(96 * 32, 10 * 32), 3)
	# Ceiling spikes (1 tile below ceiling at y=-8)
	_add_spike(Vector2(90 * 32, -7 * 32), 3)

	# 1D — spikes throughout the gauntlet
	# Segment 1: spikes in the gap below collapsing floor
	_add_spike(Vector2(112 * 32, 3 * 32), 3)
	# Segment 2: spikes above floor (1 tile up from floor at y=4)
	_add_spike(Vector2(120 * 32, 3 * 32), 3)


func _place_moving_platforms() -> void:
	# 1A — moving platform over the second gap
	var mp1 := PLATFORM_SCENE.instantiate()
	mp1.position = Vector2(24 * 32, 16 * 32)
	mp1.waypoints = [
		Vector2(23 * 32, 16 * 32),
		Vector2(26 * 32, 16 * 32),
	]
	mp1.speed = 60.0
	mp1.platform_width = 64.0
	add_child(mp1)

	# 1C — vertical moving platform inside the shaft
	var mp2 := PLATFORM_SCENE.instantiate()
	mp2.position = Vector2(92 * 32, 16 * 32)
	mp2.waypoints = [
		Vector2(92 * 32, 18 * 32),
		Vector2(92 * 32, 6 * 32),
	]
	mp2.speed = 50.0
	mp2.platform_width = 64.0
	add_child(mp2)


func _add_checkpoint(pos: Vector2) -> void:
	var cp := CHECKPOINT_SCENE.instantiate()
	cp.position = pos
	add_child(cp)


func _add_spike(pos: Vector2, count: int = 1) -> void:
	var spike := SPIKE_SCENE.instantiate()
	spike.position = pos
	spike.spike_count = count
	add_child(spike)


func _add_tutorial_hints() -> void:
	_add_label(Vector2(57 * 32, 16 * 32), "Press Q or E to shift gravity")
	_add_label(Vector2(82 * 32, 20 * 32), "Rotate gravity to climb the shaft")
	_add_label(Vector2(107 * 32, -2 * 32), "Quick rotations needed — stay calm")


func _add_label(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)


func _place_collectibles() -> void:
	# 1A — on the upper path (requires wall-jumping up the column at x=7)
	_add_collectible(Vector2(5 * 32, 7 * 32))

	# 1B — on the high interior platform inside the sealed chamber
	_add_collectible(Vector2(66 * 32, 9 * 32))

	# 1C — center of the shaft on the floating platform (reachable from multiple orientations)
	_add_collectible(Vector2(89 * 32, 3 * 32))


## Past-era shard — the first of three fragments of the Infinity Visor.
## Visible and collectable only while gravity-rotated travelers have also
## shifted to Past, deep in the Vertical Labyrinth shaft.
func _place_past_shard() -> void:
	var shard := SHARD_SCENE.instantiate()
	shard.position = LevelBuilder.tile_to_world(Vector2i(98, 5))
	shard.shard_id = GameManager.ITEM_SHARD_PAST
	shard.required_era = int(TimeManager.Era.PAST)
	shard.era_tint = Color(1.0, 0.72, 0.35, 1.0)
	add_child(shard)


func _add_collectible(pos: Vector2) -> void:
	var c := HEALTH_SCENE.instantiate()
	c.position = pos
	add_child(c)


func _add_collapsing_row(start_pos: Vector2, count: int) -> void:
	for i in range(count):
		var cp := COLLAPSING_SCENE.instantiate()
		cp.position = start_pos + Vector2(i * 32, 0)
		cp.platform_width = 32.0
		cp.platform_height = 12.0
		add_child(cp)


func _add_kill_zone() -> void:
	# Level 1 bounds: x 0-140, y -11 to 22 (tile coords)
	LevelBuilder.add_kill_zones(self, player, -2, 142, -14, 24)
