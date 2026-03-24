extends Node2D

## Level 3 — "The Chronolith"
##
## Layout (tile coords, 32px tiles):
##   Section 3A (x: 0-60):   The Approach — gauntlet combining all mechanics
##   Section 3B (x: 65-105): The Chronolith Arena — boss fight (M9)

@onready var tilemap_past: TileMapLayer = $TileMapPast
@onready var tilemap_present: TileMapLayer = $TileMapPresent
@onready var tilemap_future: TileMapLayer = $TileMapFuture
@onready var player: CharacterBody2D = $Player

const CHECKPOINT_SCENE := preload("res://scenes/objects/checkpoint.tscn")
const SPIKE_SCENE := preload("res://scenes/objects/hazard_spike.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/moving_platform.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/basic_enemy.tscn")
const BOSS_SCENE := preload("res://scenes/boss/chronolith.tscn")
const HEALTH_SCENE := preload("res://scenes/objects/health_collectible.tscn")

var boss: Node2D = null
var boss_activated: bool = false


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

	_build_section_3a()
	_build_boss_arena()
	_place_checkpoints()
	_place_hazards()
	_place_moving_platforms()
	_place_enemies()
	_place_collectibles()
	_add_tutorial_hints()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())
	TimeManager.era_changed.connect(_on_era_changed)
	# Monitor respawns to reset boss if player is outside the arena
	GameManager.player_respawned.connect(_on_player_respawned)


func _on_era_changed(era: int) -> void:
	var tess_bg := get_node_or_null("TessellationBG")
	if tess_bg and tess_bg.material:
		var morph_values := {
			TimeManager.Era.PAST: 0.0,
			TimeManager.Era.PRESENT: 0.5,
			TimeManager.Era.FUTURE: 1.0,
		}
		var tween := create_tween()
		tween.tween_property(tess_bg.material, "shader_parameter/morph",
			morph_values.get(era, 0.5), 0.5)


func _all_tilemaps() -> Array:
	return [tilemap_past, tilemap_present, tilemap_future]


# ── Section 3A — The Approach ───────────────────────────────────────────────
## Gauntlet combining all mechanics in a flowing sequence. Not harder than L2D.
## Dilation for timing, era shift to bridge gaps, gravity to traverse walls.
func _build_section_3a() -> void:
	var floor_y := 20
	var ceil_y := 4

	# ── Room 1: Dilation challenge (x: 0-18) ──
	# Fast-moving platforms over a pit — need dilation to time jumps
	for tm in _all_tilemaps():
		LevelBuilder.build_vline(tm, 0, ceil_y, floor_y)
		LevelBuilder.build_hline(tm, floor_y, 0, 6)
		LevelBuilder.build_hline(tm, ceil_y, 0, 18)
		LevelBuilder.build_hline(tm, floor_y, 14, 18)
		LevelBuilder.build_vline(tm, 18, ceil_y, floor_y)
		# Gap from x=7 to x=13 — moving platforms cross it

	# Open right wall
	for tm in _all_tilemaps():
		LevelBuilder.clear_rect(tm, Vector2i(18, 12), Vector2i(18, 18))

	# ── Room 2: Era shift challenge (x: 20-40) ──
	# Gap bridged only in Past, but Past has a wall blocking the far side
	# Solution: cross in Past, shift to Present/Future to continue
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, ceil_y, 20, 40)
		LevelBuilder.build_vline(tm, 20, ceil_y, floor_y)
		LevelBuilder.build_vline(tm, 40, ceil_y, floor_y)
		LevelBuilder.clear_rect(tm, Vector2i(20, 12), Vector2i(20, 18))
		LevelBuilder.clear_rect(tm, Vector2i(40, 12), Vector2i(40, 18))
		# Shared floor on sides
		LevelBuilder.build_hline(tm, floor_y, 20, 26)
		LevelBuilder.build_hline(tm, floor_y, 34, 40)

	# Past: bridge across the gap
	LevelBuilder.build_hline(tilemap_past, 18, 27, 33)
	# Past: wall blocks the far side exit
	LevelBuilder.build_vline(tilemap_past, 34, ceil_y + 2, floor_y)

	# Present: no bridge, no wall
	# Future: floating stepping stones
	LevelBuilder.build_rect(tilemap_future, Vector2i(28, 16), Vector2i(29, 16))
	LevelBuilder.build_rect(tilemap_future, Vector2i(31, 14), Vector2i(32, 14))

	# ── Room 3: Gravity challenge (x: 42-60) ──
	# Must rotate gravity to traverse — platforms on walls and ceiling
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, floor_y, 42, 60)
		LevelBuilder.build_hline(tm, ceil_y, 42, 60)
		LevelBuilder.build_vline(tm, 42, ceil_y, floor_y)
		LevelBuilder.build_vline(tm, 60, ceil_y, floor_y)
		LevelBuilder.clear_rect(tm, Vector2i(42, 12), Vector2i(42, 18))

	# Central pillar blocking direct path
	for tm in _all_tilemaps():
		LevelBuilder.build_rect(tm, Vector2i(49, 10), Vector2i(52, floor_y))

	# Platforms to route around the pillar (on walls, ceiling)
	for tm in _all_tilemaps():
		# Right wall platforms (gravity CW)
		LevelBuilder.build_hline(tm, ceil_y + 3, 53, 58)
		# Ceiling platform (gravity 180)
		LevelBuilder.build_hline(tm, ceil_y + 1, 46, 52)
		# Left of pillar — small platform
		LevelBuilder.build_hline(tm, 12, 44, 48)

	# Open right wall to boss arena
	for tm in _all_tilemaps():
		LevelBuilder.clear_rect(tm, Vector2i(60, 12), Vector2i(60, 18))


# ── Section 3B — Boss Arena ──────────────────────────────────────────────────
func _build_boss_arena() -> void:
	_place_boss_trigger()
	_spawn_boss()
	var ox := 65
	var arena_size := 30
	var floor_y := 20
	var ceil_y := -10  # Tall arena

	# ── Square arena with platforms on all 4 sides ──
	for tm in _all_tilemaps():
		# Main enclosure
		LevelBuilder.build_hline(tm, floor_y, ox, ox + arena_size)        # Bottom
		LevelBuilder.build_hline(tm, ceil_y, ox, ox + arena_size)         # Top
		LevelBuilder.build_vline(tm, ox, ceil_y, floor_y)                 # Left
		LevelBuilder.build_vline(tm, ox + arena_size, ceil_y, floor_y)    # Right
		# Entry from 3A
		LevelBuilder.clear_rect(tm, Vector2i(ox, 12), Vector2i(ox, 18))

		# ── Floor platforms ──
		LevelBuilder.build_hline(tm, floor_y - 3, ox + 4, ox + 8)
		LevelBuilder.build_hline(tm, floor_y - 3, ox + arena_size - 8, ox + arena_size - 4)
		LevelBuilder.build_hline(tm, floor_y - 6, ox + 12, ox + 18)

		# ── Ceiling platforms (for gravity 180°) ──
		LevelBuilder.build_hline(tm, ceil_y + 3, ox + 4, ox + 8)
		LevelBuilder.build_hline(tm, ceil_y + 3, ox + arena_size - 8, ox + arena_size - 4)
		LevelBuilder.build_hline(tm, ceil_y + 6, ox + 12, ox + 18)

		# ── Left wall platforms (for gravity 270°) ──
		LevelBuilder.build_hline(tm, ceil_y + 8, ox + 1, ox + 4)
		LevelBuilder.build_hline(tm, ceil_y + 16, ox + 1, ox + 4)

		# ── Right wall platforms (for gravity 90°) ──
		LevelBuilder.build_hline(tm, ceil_y + 8, ox + arena_size - 4, ox + arena_size - 1)
		LevelBuilder.build_hline(tm, ceil_y + 16, ox + arena_size - 4, ox + arena_size - 1)

	# Era-specific variations in the arena (Phase 3 uses these)
	# Past: extra platforms (more walkable surface)
	LevelBuilder.build_hline(tilemap_past, floor_y - 10, ox + 8, ox + 22)
	LevelBuilder.build_hline(tilemap_past, ceil_y + 10, ox + 8, ox + 22)

	# Future: floating islands
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 14, 4), Vector2i(ox + 16, 4))
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 10, 0), Vector2i(ox + 12, 0))
	LevelBuilder.build_rect(tilemap_future, Vector2i(ox + 18, -2), Vector2i(ox + 20, -2))


func _place_checkpoints() -> void:
	_add_checkpoint(Vector2(3 * 32, 20 * 32))        # Start 3A room 1
	_add_checkpoint(Vector2(22 * 32, 20 * 32))        # Start 3A room 2
	_add_checkpoint(Vector2(44 * 32, 20 * 32))        # Start 3A room 3
	_add_checkpoint(Vector2(67 * 32, 20 * 32))        # Boss arena entry


func _place_hazards() -> void:
	# 3A Room 1 — spikes in the pit
	_add_spike(Vector2(10 * 32, 20 * 32), 5)

	# 3A Room 2 — spikes in the gap
	_add_spike(Vector2(30 * 32, 20 * 32), 4)

	# 3A Room 3 — spikes near the central pillar (in the gap before it)
	_add_spike(Vector2(46 * 32, 19 * 32), 2)

	# Boss arena — spikes on the floor (1 tile above floor at y=20)
	_add_spike(Vector2(80 * 32, 19 * 32), 6)


func _place_moving_platforms() -> void:
	# 3A Room 1 — fast platforms over the pit (need dilation)
	var mp1 := PLATFORM_SCENE.instantiate()
	mp1.position = Vector2(8 * 32, 16 * 32)
	mp1.waypoints = [Vector2(3 * 32, 16 * 32), Vector2(16 * 32, 16 * 32)]
	mp1.speed = 450.0
	mp1.platform_width = 48.0
	add_child(mp1)

	var mp2 := PLATFORM_SCENE.instantiate()
	mp2.position = Vector2(10 * 32, 12 * 32)
	mp2.waypoints = [Vector2(10 * 32, 6 * 32), Vector2(10 * 32, 19 * 32)]
	mp2.speed = 420.0
	mp2.platform_width = 48.0
	add_child(mp2)


func _place_enemies() -> void:
	# 3A Room 2 — enemy on the Past bridge
	var enemy := ENEMY_SCENE.instantiate()
	enemy.position = Vector2(30 * 32, 18 * 32)
	enemy.waypoints = [Vector2(28 * 32, 18 * 32), Vector2(33 * 32, 18 * 32)]
	enemy.speed = 55.0
	add_child(enemy)

	# 3A Room 3 — enemy patrolling
	var enemy2 := ENEMY_SCENE.instantiate()
	enemy2.position = Vector2(55 * 32, 20 * 32)
	enemy2.waypoints = [Vector2(53 * 32, 20 * 32), Vector2(58 * 32, 20 * 32)]
	enemy2.speed = 65.0
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


func _place_collectibles() -> void:
	# 3A Room 1 — above the moving platforms (requires dilation + precise jump)
	_add_collectible(Vector2(10 * 32, 8 * 32))

	# 3A Room 2 — on the Future stepping stones (requires era shift to Future)
	_add_collectible(Vector2(31 * 32, 13 * 32))

	# 3A Room 3 — above the ceiling platform (requires gravity rotation to 180)
	_add_collectible(Vector2(49 * 32, 3 * 32))


func _add_collectible(pos: Vector2) -> void:
	var c := HEALTH_SCENE.instantiate()
	c.position = pos
	add_child(c)


func _add_tutorial_hints() -> void:
	_add_label(Vector2(3 * 32, 6 * 32), "Slow the platforms to time your jumps")
	_add_label(Vector2(22 * 32, 6 * 32), "The Past holds a bridge — but also a wall...")
	_add_label(Vector2(44 * 32, 6 * 32), "Rotate gravity to route around the pillar")


func _add_label(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)


func _add_kill_zone() -> void:
	# Level 3 bounds: x 0-95, y -10 to 20 (tile coords)
	LevelBuilder.add_kill_zones(self, player, -2, 100, -14, 24)


func _spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate()
	# Center of the arena: ox=65, arena_size=30 → center at (65+15)*32 = 80*32
	boss.position = Vector2(80 * 32, 5 * 32)
	boss.boss_defeated.connect(_on_boss_defeated)
	add_child(boss)


func _place_boss_trigger() -> void:
	# Trigger zone at the arena entry
	var trigger := Area2D.new()
	trigger.position = Vector2(67 * 32, 14 * 32)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 192)
	shape.shape = rect
	trigger.add_child(shape)
	trigger.body_entered.connect(func(body: Node2D) -> void:
		if body == player and not boss_activated:
			boss_activated = true
			_activate_boss()
	)
	add_child(trigger)


func _activate_boss() -> void:
	if boss == null:
		return

	# Seal the arena entrance
	for tm in _all_tilemaps():
		LevelBuilder.build_vline(tm, 65, 12, 18)

	# Brief dramatic pause
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func() -> void:
		boss.activate()
	)

	# Flash the screen
	var canvas := CanvasLayer.new()
	canvas.layer = 15
	var flash := ColorRect.new()
	flash.color = Color(0.5, 0.4, 0.7, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(flash)
	add_child(canvas)
	var flash_tween := canvas.create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 1.0)
	flash_tween.tween_callback(canvas.queue_free)


func _on_player_respawned() -> void:
	if not boss_activated:
		return
	if boss == null:
		return
	if boss._defeated:
		return
	# Player has already been moved to checkpoint. Check if outside the arena.
	var arena_left: float = 65 * 32
	if player.global_position.x < arena_left:
		_reset_boss()


func _reset_boss() -> void:
	# Deactivate boss
	boss.deactivate()
	boss_activated = false

	# Unseal the arena entrance
	for tm in _all_tilemaps():
		LevelBuilder.clear_rect(tm, Vector2i(65, 12), Vector2i(65, 18))


func _on_boss_defeated() -> void:
	# Victory sequence
	# Unseal arena
	for tm in _all_tilemaps():
		LevelBuilder.clear_rect(tm, Vector2i(65, 12), Vector2i(65, 18))

	# White out effect
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	var white := ColorRect.new()
	white.color = Color(1, 1, 1, 0)
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(white)
	add_child(canvas)

	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(white, "color:a", 1.0, 2.0)
	tween.tween_interval(1.0)
	tween.tween_callback(func() -> void:
		GameManager._show_victory()
	)
