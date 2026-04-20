extends Node2D

## The Chronolith — 3-phase boss.
## Phase 1 (100-66% HP): Gravity — forced rotations, ceiling weak points
## Phase 2 (66-33% HP): Time — faster attacks, dilation-extended weak points
## Phase 3 (33-0% HP): Era — fractured arena, era-shifting weak points

signal boss_defeated

const MAX_HP: float = 30.0
const BODY_COLOR := Color(0.4, 0.35, 0.55, 0.9)
const DAMAGED_COLOR := Color(0.7, 0.3, 0.3, 0.9)
const BODY_SIZE := 80.0

## Interval at which the visor's true-core weak point shifts era while
## the boss fight is active.
const TRUE_CORE_SHIFT_INTERVAL: float = 3.5

var hp: float = MAX_HP
var current_phase: int = 1
var _phase_timer: float = 0.0
var _attack_timer: float = 0.0
var _rotation_angle: float = 0.0
var _active: bool = false
var _defeated: bool = false
## True when the killing blow came from the visor-only true core. Read
## by the level script to pick the true-ending branch.
var defeated_via_true_core: bool = false

var _weak_points: Array[Node2D] = []
var _current_phase_script: Node = null
## Always-present weak-point shown only while the Infinity Visor is worn.
## It never expires, just rotates required_era periodically.
var _true_core: Node2D = null
var _true_core_timer: float = 0.0
var _true_core_era_index: int = 0

const PROJECTILE_SCENE := preload("res://scenes/objects/projectile.tscn")
const WEAK_POINT_SCENE := preload("res://scenes/boss/weak_point.tscn")


func _ready() -> void:
	# Start inactive — activated by level script
	set_process(false)
	set_physics_process(false)


func activate() -> void:
	_active = true
	_defeated = false
	defeated_via_true_core = false
	set_process(true)
	set_physics_process(true)
	_enter_phase(1)
	# Listen for visor toggles mid-fight so we can spawn / despawn the
	# true core in response.
	if not GameManager.visor_toggled.is_connected(_on_visor_toggled):
		GameManager.visor_toggled.connect(_on_visor_toggled)
	_refresh_true_core_presence()


func deactivate() -> void:
	_active = false
	set_process(false)
	set_physics_process(false)
	_clear_weak_points()
	_clear_true_core()
	_clear_all_projectiles()
	# Reset state
	hp = MAX_HP
	current_phase = 1
	_phase_timer = 0.0
	_attack_timer = 0.0
	_p1_gravity_timer = 0.0
	_p1_weak_timer = 0.0
	_p2_gravity_timer = 0.0
	_p2_weak_timer = 0.0
	_p2_burst_count = 0
	_p3_weak_timer = 0.0
	_p3_era_cycle = 0
	_true_core_timer = 0.0
	_true_core_era_index = 0
	defeated_via_true_core = false


func _clear_all_projectiles() -> void:
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	# Also find any Projectile nodes not in groups
	for node in get_tree().current_scene.get_children():
		if node.has_method("_on_body_entered") and node is Area2D and node != self:
			if "speed" in node and "direction" in node:
				node.queue_free()


func _process(delta: float) -> void:
	if _defeated:
		return
	_phase_timer += delta
	_rotation_angle += delta * 0.5
	_tick_true_core(delta)
	queue_redraw()


## ── Infinity Visor: true-core weak point ────────────────────────────────

func _on_visor_toggled(_active_state: bool) -> void:
	if _defeated or not _active:
		return
	_refresh_true_core_presence()


## Ensure the true-core is alive iff the visor is currently active. Also
## clears any normal weak points when the visor switches on, since those
## are unreachable while worn.
func _refresh_true_core_presence() -> void:
	var visor_on: bool = GameManager.visor_active
	if visor_on:
		_clear_weak_points()
		if _true_core == null or not is_instance_valid(_true_core):
			_spawn_true_core()
	else:
		_clear_true_core()


func _spawn_true_core() -> void:
	var wp := WEAK_POINT_SCENE.instantiate()
	# Place on the ceiling relative to current gravity, like normal weak
	# points. It will not expire on its own.
	var up := GravityManager.get_up_direction()
	wp.global_position = global_position + up * 180.0
	wp.hit.connect(_on_true_core_hit)
	get_tree().current_scene.add_child(wp)
	# Huge lifetime so _process-driven era shifts, not the timer, retire it.
	wp.activate(9999.0, _true_core_era_index)
	_true_core = wp
	_true_core_timer = 0.0


func _clear_true_core() -> void:
	if _true_core != null and is_instance_valid(_true_core):
		_true_core.deactivate()
		_true_core.queue_free()
	_true_core = null


func _tick_true_core(delta: float) -> void:
	if _true_core == null or not is_instance_valid(_true_core):
		return
	_true_core_timer += delta
	# Follow the boss in case of gravity rotations, staying "above" it.
	var up := GravityManager.get_up_direction()
	_true_core.global_position = global_position + up * 180.0

	if _true_core_timer >= TRUE_CORE_SHIFT_INTERVAL:
		_true_core_timer = 0.0
		_true_core_era_index = (_true_core_era_index + 1) % 3
		# Update lock in-place — restart activate() with new era.
		_true_core.required_era = _true_core_era_index


func _on_true_core_hit() -> void:
	if _defeated:
		return
	# Each hit does proportional damage so three hits ends the fight,
	# similar pacing to normal weak points. Mark as true-core damage so
	# the level picks the true-ending branch when HP reaches zero.
	take_damage_from_true_core(10.0)
	# Refresh — the hit deactivates the weak point; we want it to persist.
	if _defeated:
		return
	if GameManager.visor_active:
		_clear_true_core()
		_spawn_true_core()


func take_damage(amount: float = 1.0) -> void:
	_receive_damage(amount, false)


func take_damage_from_true_core(amount: float = 1.0) -> void:
	_receive_damage(amount, true)


func _receive_damage(amount: float, via_true_core: bool) -> void:
	hp -= amount
	hp = max(hp, 0)
	if via_true_core and hp <= 0:
		defeated_via_true_core = true
	# Phase transitions by HP threshold, same pacing as before.
	var hp_ratio := hp / MAX_HP
	if hp_ratio <= 0:
		_defeat()
	elif hp_ratio <= 0.33 and current_phase < 3:
		_enter_phase(3)
	elif hp_ratio <= 0.66 and current_phase < 2:
		_enter_phase(2)


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_attack_timer += delta

	match current_phase:
		1: _phase_1_logic(delta)
		2: _phase_2_logic(delta)
		3: _phase_3_logic(delta)


func _enter_phase(phase: int) -> void:
	current_phase = phase
	_phase_timer = 0.0
	_attack_timer = 0.0
	_clear_weak_points()

	# Visual feedback — flash
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)


## ── Phase 1: Gravity ────────────────────────────────────────────────────────
## Slow-tracking projectiles. Periodically forces gravity shift.
## Weak points appear on the ceiling — player must rotate gravity to reach them.
var _p1_gravity_timer: float = 0.0
const P1_GRAVITY_INTERVAL: float = 5.0
const P1_ATTACK_INTERVAL: float = 1.8
const P1_WEAK_POINT_INTERVAL: float = 4.0
var _p1_weak_timer: float = 0.0

func _phase_1_logic(delta: float) -> void:
	_p1_gravity_timer += delta
	_p1_weak_timer += delta

	# Fire tracking projectiles
	if _attack_timer >= P1_ATTACK_INTERVAL:
		_attack_timer = 0.0
		_fire_projectile(true, 200.0)

	# Force gravity rotation periodically
	if _p1_gravity_timer >= P1_GRAVITY_INTERVAL:
		_p1_gravity_timer = 0.0
		_force_gravity_shift()

	# Spawn weak point on the "ceiling" (relative to current gravity)
	if _p1_weak_timer >= P1_WEAK_POINT_INTERVAL:
		_p1_weak_timer = 0.0
		_spawn_weak_point_on_ceiling(3.0)


## ── Phase 2: Time ───────────────────────────────────────────────────────────
## Faster projectiles in bursts. Gravity shifts happen more often.
## Weak points only appear for 2s — dilation extends the window.
const P2_ATTACK_INTERVAL: float = 0.25
const P2_BURST_PAUSE: float = 2.5
const P2_GRAVITY_INTERVAL: float = 3.5
const P2_WEAK_POINT_INTERVAL: float = 4.0
var _p2_gravity_timer: float = 0.0
var _p2_weak_timer: float = 0.0
var _p2_burst_count: int = 0

func _phase_2_logic(delta: float) -> void:
	_p2_gravity_timer += delta
	_p2_weak_timer += delta

	# Burst fire — 3 quick shots then a long pause
	if _attack_timer >= P2_ATTACK_INTERVAL:
		_attack_timer = 0.0
		_fire_projectile(true, 280.0)
		_p2_burst_count += 1
		if _p2_burst_count >= 3:
			_p2_burst_count = 0
			_attack_timer = -P2_BURST_PAUSE

	# Forced gravity
	if _p2_gravity_timer >= P2_GRAVITY_INTERVAL:
		_p2_gravity_timer = 0.0
		_force_gravity_shift()

	# Weak point — short window (player should dilation it)
	if _p2_weak_timer >= P2_WEAK_POINT_INTERVAL:
		_p2_weak_timer = 0.0
		_spawn_weak_point_on_ceiling(3.5)


## ── Phase 3: Era ────────────────────────────────────────────────────────────
## Frantic projectiles. Weak points are era-locked.
## Arena sections exist in different eras.
const P3_WEAK_POINT_INTERVAL: float = 4.5
var _p3_weak_timer: float = 0.0
var _p3_era_cycle: int = 0

func _phase_3_logic(delta: float) -> void:
	_p3_weak_timer += delta
	_p2_gravity_timer += delta

	# Same attack pattern as phase 2: burst fire
	if _attack_timer >= P2_ATTACK_INTERVAL:
		_attack_timer = 0.0
		_fire_projectile(true, 280.0)
		_p2_burst_count += 1
		if _p2_burst_count >= 3:
			_p2_burst_count = 0
			_attack_timer = -1.0

	# Same gravity shift rate as phase 2
	if _p2_gravity_timer >= P2_GRAVITY_INTERVAL:
		_p2_gravity_timer = 0.0
		_force_gravity_shift()

	# Era-locked weak points
	if _p3_weak_timer >= P3_WEAK_POINT_INTERVAL:
		_p3_weak_timer = 0.0
		var target_era := _p3_era_cycle % 3
		_p3_era_cycle += 1
		_spawn_weak_point_on_ceiling(10.5, target_era)


## ── Shared mechanics ────────────────────────────────────────────────────────

func _fire_projectile(tracking: bool, spd: float, dir: Vector2 = Vector2.ZERO) -> void:
	if not GameManager.player:
		return
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	if dir != Vector2.ZERO:
		proj.direction = dir.normalized()
	else:
		proj.direction = (GameManager.player.global_position - global_position).normalized()
	proj.speed = spd
	proj.tracking = tracking
	proj.tracking_strength = 1.0 if current_phase == 1 else 1.5
	get_tree().current_scene.add_child(proj)


func _force_gravity_shift() -> void:
	# Force a random 90° rotation (bypasses grounded check)
	var dir := 1 if randf() > 0.5 else -1
	GravityManager.rotate_gravity(dir, true)


func _spawn_weak_point_on_ceiling(duration: float, era: int = -1) -> void:
	# Normal weak points are suppressed while the Infinity Visor is worn —
	# the true core is the only legal target during a visor run.
	if GameManager.visor_active:
		return
	var wp := WEAK_POINT_SCENE.instantiate()
	# Place away from boss center, biased toward current "up" direction
	# but within the arena bounds (arena is ~30 tiles = 960px across)
	var up := GravityManager.get_up_direction()
	var lateral := Vector2(-up.y, up.x)  # perpendicular to up
	var offset := up * 180.0 + lateral * randf_range(-120, 120)
	wp.global_position = global_position + offset
	wp.hit.connect(func() -> void:
		take_damage(3.0 if current_phase == 1 else 4.0 if current_phase == 2 else 5.0)
	)
	_weak_points.append(wp)
	get_tree().current_scene.add_child(wp)
	# activate AFTER add_child so _ready() doesn't override visible/monitoring
	wp.activate(duration, era)


func _clear_weak_points() -> void:
	for wp in _weak_points:
		if is_instance_valid(wp):
			wp.queue_free()
	_weak_points.clear()


func _defeat() -> void:
	_defeated = true
	_clear_weak_points()
	_clear_true_core()
	# Kill all projectiles
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()

	# Collapse animation — shrink + tessellate spiral
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.01, 0.01), 2.0).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(self, "rotation", TAU * 8, 2.0)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func() -> void:
		boss_defeated.emit()
	)


func _draw() -> void:
	if _defeated and modulate.a < 0.05:
		return

	var hp_ratio := hp / MAX_HP
	var color := BODY_COLOR.lerp(DAMAGED_COLOR, 1.0 - hp_ratio)
	var pulse := sin(_phase_timer * 2.0) * 0.1 + 0.9

	# Outer rotating geometric form — impossible polyhedron silhouette
	var sides := 6 + current_phase  # More complex each phase
	var points := PackedVector2Array()
	for i in range(sides):
		var angle := _rotation_angle + (TAU / sides) * i
		var r := BODY_SIZE * pulse
		points.append(Vector2(cos(angle) * r, sin(angle) * r))
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), color.lightened(0.3), 2.0)

	# Inner rotating form (counter-rotation)
	var inner_points := PackedVector2Array()
	for i in range(sides):
		var angle := -_rotation_angle * 1.5 + (TAU / sides) * i
		var r := BODY_SIZE * 0.5 * pulse
		inner_points.append(Vector2(cos(angle) * r, sin(angle) * r))
	draw_colored_polygon(inner_points, color.darkened(0.3))

	# Phase indicator — glowing eye
	var eye_colors := [
		Color(0.6, 0.8, 1.0),   # Phase 1: blue
		Color(1.0, 0.7, 0.3),   # Phase 2: gold
		Color(0.8, 0.3, 1.0),   # Phase 3: purple
	]
	var eye_color: Color = eye_colors[current_phase - 1]
	eye_color.a = pulse
	draw_circle(Vector2.ZERO, 12.0, eye_color)

	# HP bar above
	var bar_w := 120.0
	var bar_y := -BODY_SIZE - 20.0
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, 6), Color(0.2, 0.2, 0.25, 0.7))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, 6), eye_color * Color(1, 1, 1, 0.8))
