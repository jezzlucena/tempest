extends Node2D

## Level 2 — "The Fractured Gallery"
##
## Layout (tile coords, 32px tiles):
##   Section 2A (x: 0-35):    The Slow Hall — time dilation tutorial
##   Section 2B (x: 40-70):   The Triptych — era shift tutorial
##   Section 2C (x: 75-110):  The Shattered Atrium — dilation + era shift
##   Section 2D (x: 115-150): The Impossible Corridor — all three mechanics

@onready var tilemap_past: TileMapLayer = $TileMapPast
@onready var tilemap_present: TileMapLayer = $TileMapPresent
@onready var tilemap_future: TileMapLayer = $TileMapFuture
@onready var player: CharacterBody2D = $Player

const CHECKPOINT_SCENE := preload("res://scenes/objects/checkpoint.tscn")
const SPIKE_SCENE := preload("res://scenes/objects/hazard_spike.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/moving_platform.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/basic_enemy.tscn")
const COLLAPSING_SCENE := preload("res://scenes/objects/collapsing_platform.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const HEALTH_SCENE := preload("res://scenes/objects/health_collectible.tscn")


func _ready() -> void:
	tilemap_past.tile_set = LevelBuilder.create_tileset(Color(0.45, 0.38, 0.25))
	tilemap_present.tile_set = LevelBuilder.create_tileset(Color(0.28, 0.28, 0.33))
	tilemap_future.tile_set = LevelBuilder.create_tileset(Color(0.2, 0.25, 0.42))

	LevelStateManager.clear_layers()
	LevelStateManager.register_era_layer(TimeManager.Era.PAST, tilemap_past)
	LevelStateManager.register_era_layer(TimeManager.Era.PRESENT, tilemap_present)
	LevelStateManager.register_era_layer(TimeManager.Era.FUTURE, tilemap_future)

	TimeManager.current_era = TimeManager.Era.PRESENT
	LevelStateManager.swap_era(TimeManager.Era.PRESENT)

	_build_section_2a()
	_build_section_2b()
	_build_section_2c()
	_build_section_2d()
	_place_checkpoints()
	_place_hazards()
	_place_moving_platforms()
	_place_enemies()
	_place_collectibles()
	_add_tutorial_hints()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())
	TimeManager.era_changed.connect(_on_era_changed)


func _on_era_changed(era: int) -> void:
	# Update tessellation shader morph based on era
	var tess_bg := get_node_or_null("TessellationBG")
	if tess_bg and tess_bg.material:
		var morph_values := {
			TimeManager.Era.PAST: 0.0,
			TimeManager.Era.PRESENT: 0.5,
			TimeManager.Era.FUTURE: 1.0,
		}
		var target_morph: float = morph_values.get(era, 0.5)
		var tween := create_tween()
		tween.tween_property(tess_bg.material, "shader_parameter/morph", target_morph, 0.5)


# ── Helpers ─────────────────────────────────────────────────────────────────
func _all_tilemaps() -> Array:
	return [tilemap_past, tilemap_present, tilemap_future]


func _build_shared_room(from_x: int, to_x: int, floor_y: int, ceil_y: int) -> void:
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, floor_y, from_x, to_x)
		LevelBuilder.build_hline(tm, ceil_y, from_x, to_x)
		LevelBuilder.build_vline(tm, from_x, ceil_y, floor_y)
		LevelBuilder.build_vline(tm, to_x, ceil_y, floor_y)


func _open_wall_shared(x: int, from_y: int, to_y: int) -> void:
	for tm in _all_tilemaps():
		LevelBuilder.clear_rect(tm, Vector2i(x, from_y), Vector2i(x, to_y))


# ── Section 2A — The Slow Hall ──────────────────────────────────────────────
func _build_section_2a() -> void:
	_build_shared_room(0, 35, 18, 8)
	_open_wall_shared(35, 12, 16)
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, 15, 8, 11)
		LevelBuilder.build_hline(tm, 14, 18, 21)
		LevelBuilder.build_hline(tm, 15, 28, 31)


# ── Section 2B — The Triptych ───────────────────────────────────────────────
func _build_section_2b() -> void:
	var ox := 40
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, 18, ox - 5, ox + 30)
		LevelBuilder.build_hline(tm, 8, ox - 5, ox + 30)
		LevelBuilder.build_vline(tm, ox - 5, 8, 18)
		LevelBuilder.build_vline(tm, ox + 30, 8, 18)
		LevelBuilder.clear_rect(tm, Vector2i(ox - 5, 12), Vector2i(ox - 5, 16))
		LevelBuilder.build_hline(tm, 18, ox, ox + 8)
		LevelBuilder.build_hline(tm, 18, ox + 20, ox + 28)

	# Open right wall for 2C transition
	_open_wall_shared(ox + 30, 12, 16)

	# Past: solid bridge + pillars
	LevelBuilder.build_hline(tilemap_past, 16, ox + 9, ox + 19)
	LevelBuilder.build_vline(tilemap_past, ox + 9, 12, 16)
	LevelBuilder.build_vline(tilemap_past, ox + 19, 12, 16)
	LevelBuilder.build_hline(tilemap_past, 12, ox + 3, ox + 6)
	LevelBuilder.build_hline(tilemap_past, 12, ox + 22, ox + 25)

	# Present: collapsed stumps
	LevelBuilder.build_rect(tilemap_present, Vector2i(ox + 9, 17), Vector2i(ox + 10, 17))
	LevelBuilder.build_rect(tilemap_present, Vector2i(ox + 18, 17), Vector2i(ox + 19, 17))

	# Future: floating platform
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 13, 14), Vector2i(ox + 15, 14))
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 5, 11), Vector2i(ox + 6, 11))
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 24, 10), Vector2i(ox + 25, 10))


# ── Section 2C — The Shattered Atrium ───────────────────────────────────────
## Large open space. Present: gap too wide + fast debris. Past: bridge + pendulum.
## Solution: shift to Past, dilation the pendulum, cross, shift back.
func _build_section_2c() -> void:
	var ox := 75
	var floor_y := 18
	var ceil_y := 4  # Taller room for the atrium

	# ── Common structure ──
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, floor_y, ox - 5, ox + 35)
		LevelBuilder.build_hline(tm, ceil_y, ox - 5, ox + 35)
		LevelBuilder.build_vline(tm, ox - 5, ceil_y, floor_y)
		LevelBuilder.build_vline(tm, ox + 35, ceil_y, floor_y)
		# Entry from 2B
		LevelBuilder.clear_rect(tm, Vector2i(ox - 5, 12), Vector2i(ox - 5, 16))
		# Shared floor on sides
		LevelBuilder.build_hline(tm, floor_y, ox, ox + 8)
		LevelBuilder.build_hline(tm, floor_y, ox + 24, ox + 32)

	# Open right wall for 2D transition
	_open_wall_shared(ox + 35, 12, 16)

	# ── PRESENT: Massive gap with fast-moving debris (impassable without era shift) ──
	# Just some broken platform fragments
	LevelBuilder.build_rect(tilemap_present, Vector2i(ox + 10, 17), Vector2i(ox + 11, 17))
	LevelBuilder.build_rect(tilemap_present, Vector2i(ox + 20, 16), Vector2i(ox + 21, 16))

	# ── PAST: Bridge exists but guarded by a massive pendulum ──
	LevelBuilder.build_hline(tilemap_past, 16, ox + 9, ox + 23)
	# Ornate arches
	LevelBuilder.build_vline(tilemap_past, ox + 9, 10, 16)
	LevelBuilder.build_vline(tilemap_past, ox + 23, 10, 16)
	LevelBuilder.build_hline(tilemap_past, 10, ox + 9, ox + 23)
	# Upper gallery in past
	LevelBuilder.build_hline(tilemap_past, 8, ox + 5, ox + 12)
	LevelBuilder.build_hline(tilemap_past, 8, ox + 20, ox + 28)

	# ── FUTURE: Floating stepping stones across the gap ──
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 10, 14), Vector2i(ox + 11, 14))
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 14, 12), Vector2i(ox + 15, 12))
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 18, 13), Vector2i(ox + 19, 13))
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 22, 15), Vector2i(ox + 23, 15))


# ── Section 2D — The Impossible Corridor ────────────────────────────────────
## All three mechanics required.
## Floor collapses (Present) → gravity rotate to wall → crusher blocks wall path →
## dilation the crusher → wall dead-ends in Present → era shift to Past → reach exit.
func _build_section_2d() -> void:
	var ox := 115
	var floor_y := 18
	var ceil_y := 6
	var cor_h := floor_y - ceil_y

	# ── Segment 1: Floor collapses in Present, must rotate gravity ──
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, ceil_y, ox - 5, ox + 35)   # Ceiling
		LevelBuilder.build_vline(tm, ox - 5, ceil_y, floor_y)   # Left wall
		LevelBuilder.build_vline(tm, ox + 35, ceil_y, floor_y)  # Right wall
		LevelBuilder.clear_rect(tm, Vector2i(ox - 5, 12), Vector2i(ox - 5, 16))

	# Present floor: solid start, then collapsing platforms
	LevelBuilder.build_hline(tilemap_present, floor_y, ox - 5, ox - 1)
	# Collapsing floor from ox to ox+5 (falls when stepped on)
	_add_collapsing_row(Vector2(ox * 32 + 16, floor_y * 32 + 6), 6)
	# Gap in present floor from ox+6 to ox+18

	# Past: full floor throughout (safe but still needs gravity for later)
	LevelBuilder.build_hline(tilemap_past, floor_y, ox - 5, ox + 35)

	# Future: floor is fragmented
	LevelBuilder.build_hline(tilemap_future, floor_y, ox - 5, ox + 3)
	LevelBuilder.build_hline(tilemap_future, floor_y, ox + 14, ox + 20)
	LevelBuilder.build_hline(tilemap_future, floor_y, ox + 28, ox + 35)

	# ── Segment 2: Walk on the right wall (gravity rotated CW) ──
	# Platforms along the right wall (accessible when gravity points right)
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, ceil_y + 4, ox + 8, ox + 15)

	# Crusher obstacle in the wall path — fast moving, needs dilation
	# (Placed as pendulum in _place_hazards)

	# ── Segment 3: Wall dead-ends in Present, continues in Past ──
	# Present: wall at ox+20 blocks the path
	LevelBuilder.build_vline(tilemap_present, ox + 20, ceil_y, ceil_y + 6)

	# Past: no wall here — path continues
	# (tilemap_past doesn't have this wall)

	# Future: crystalline wall partially blocks
	LevelBuilder.build_vline(tilemap_future, ox + 20, ceil_y, ceil_y + 3)

	# ── Exit area ──
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, floor_y, ox + 25, ox + 35)

	# Exit trigger position at ox+33


func _place_checkpoints() -> void:
	_add_checkpoint(Vector2(3 * 32, 18 * 32))        # Start 2A
	_add_checkpoint(Vector2(16 * 32, 18 * 32))        # Mid 2A
	_add_checkpoint(Vector2(42 * 32, 18 * 32))        # Start 2B
	_add_checkpoint(Vector2(62 * 32, 18 * 32))        # End 2B
	_add_checkpoint(Vector2(77 * 32, 18 * 32))        # Start 2C
	_add_checkpoint(Vector2(100 * 32, 18 * 32))       # End 2C
	_add_checkpoint(Vector2(117 * 32, 18 * 32))       # Start 2D
	_add_checkpoint(Vector2(145 * 32, 18 * 32))       # End 2D (exit)


func _place_hazards() -> void:
	# 2A — Pendulum blades
	_add_pendulum(Vector2(12 * 32, 10 * 32), Vector2(12 * 32, 16 * 32), 200.0)
	_add_pendulum(Vector2(22 * 32, 10 * 32), Vector2(22 * 32, 16 * 32), 250.0)
	_add_pendulum(Vector2(32 * 32, 10 * 32), Vector2(32 * 32, 16 * 32), 220.0)

	# 2B — Spikes in the gap
	_add_spike(Vector2(54 * 32, 18 * 32), 4)

	# 2C — Massive pendulum in the Past (guards the bridge)
	# This is the key puzzle: shift to Past, dilation this pendulum, cross
	_add_pendulum(Vector2(91 * 32, 6 * 32), Vector2(91 * 32, 16 * 32), 180.0)

	# 2C — Spikes in the gap bottom
	_add_spike(Vector2(86 * 32, 18 * 32), 6)

	# 2D — Horizontal crusher in the wall path (needs dilation)
	_add_pendulum(Vector2(126 * 32, 8 * 32), Vector2(133 * 32, 8 * 32), 200.0)

	# 2D — Spikes below the collapsing floor
	_add_spike(Vector2(125 * 32, 18 * 32), 5)

	# Level exit portal
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(148 * 32, 16 * 32)
	add_child(exit_portal)


func _add_pendulum(pos_a: Vector2, pos_b: Vector2, spd: float) -> void:
	var pendulum_script := preload("res://scripts/objects/pendulum_visual.gd")
	var pendulum := Area2D.new()
	pendulum.set_script(pendulum_script)
	pendulum.position = pos_a
	pendulum.pos_a = pos_a
	pendulum.pos_b = pos_b
	pendulum.speed = spd
	add_child(pendulum)


func _place_moving_platforms() -> void:
	# 2C — Fast-moving debris in the Present gap
	var debris := PLATFORM_SCENE.instantiate()
	debris.position = Vector2(86 * 32, 14 * 32)
	debris.waypoints = [Vector2(83 * 32, 14 * 32), Vector2(96 * 32, 14 * 32)]
	debris.speed = 180.0
	debris.platform_width = 48.0
	add_child(debris)


func _place_enemies() -> void:
	# 2C — Patrol enemy on the Past bridge
	var enemy := ENEMY_SCENE.instantiate()
	enemy.position = Vector2(88 * 32, 16 * 32)
	enemy.waypoints = [Vector2(85 * 32, 16 * 32), Vector2(95 * 32, 16 * 32)]
	enemy.speed = 60.0
	add_child(enemy)

	# 2D — Enemy patrolling the exit area
	var enemy2 := ENEMY_SCENE.instantiate()
	enemy2.position = Vector2(140 * 32, 18 * 32)
	enemy2.waypoints = [Vector2(137 * 32, 18 * 32), Vector2(147 * 32, 18 * 32)]
	enemy2.speed = 70.0
	add_child(enemy2)


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
	_add_label(Vector2(5 * 32, 10 * 32), "Right-click to cast a time dilation field")
	_add_label(Vector2(5 * 32, 11 * 32), "Slow down the blades to pass safely")
	_add_label(Vector2(42 * 32, 10 * 32), "Shift+Left / Shift+Right to change eras")
	_add_label(Vector2(42 * 32, 11 * 32), "The bridge exists in the Past...")
	_add_label(Vector2(77 * 32, 6 * 32), "Combine your powers: shift era, then slow the pendulum")
	_add_label(Vector2(117 * 32, 8 * 32), "Floor collapses — rotate gravity!")
	_add_label(Vector2(117 * 32, 9 * 32), "Path blocked? Try another era...")


func _add_label(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)


func _add_collapsing_row(start_pos: Vector2, count: int) -> void:
	for i in range(count):
		var cp := COLLAPSING_SCENE.instantiate()
		cp.position = start_pos + Vector2(i * 32, 0)
		cp.platform_width = 32.0
		cp.platform_height = 12.0
		add_child(cp)


const SHARD_SCENE := preload("res://scenes/objects/infinity_shard.tscn")


func _place_collectibles() -> void:
	# 2A — between the 2nd and 3rd pendulums, on the high platform
	_add_collectible(Vector2(20 * 32, 13 * 32))

	# 2B — on the Future-only floating block (requires era shift to Future)
	_add_collectible(Vector2(46 * 32, 10 * 32))

	# 2C — on the Past upper gallery (requires era shift + platforming)
	_add_collectible(Vector2(96 * 32, 7 * 32))

	# Present-only: second fragment of the Infinity Visor, hidden deep in
	# 2D's Impossible Corridor in a spot the other eras occlude.
	var shard := SHARD_SCENE.instantiate()
	shard.position = LevelBuilder.tile_to_world(Vector2i(130, 10))
	shard.shard_id = GameManager.ITEM_SHARD_PRESENT
	shard.required_era = int(TimeManager.Era.PRESENT)
	shard.era_tint = Color(0.85, 0.9, 1.0, 1.0)
	add_child(shard)


func _add_collectible(pos: Vector2) -> void:
	var c := HEALTH_SCENE.instantiate()
	c.position = pos
	add_child(c)


func _add_kill_zone() -> void:
	# Level 2 bounds: x 0-150, y 4 to 18 (tile coords)
	LevelBuilder.add_kill_zones(self, player, -2, 152, 0, 22)
