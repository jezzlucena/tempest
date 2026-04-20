extends Node2D

## The Archivist — W5 boss.
##
## Drifts near the arena centre. Each cycle it forces an era shift and
## spawns an era-locked weak_point.tscn at the matching era's pocket. The
## player is now in that era, so the weak-point is strikeable — but the
## boss's projectile bursts still press them. Three hits defeats it and
## grants ABILITY_ERA_SHIFT.
##
## Unlike the Phantom, weak-point position is authored per era (passed in
## by the level) so the player always knows where the next strike point
## will appear once the era flips.

signal boss_defeated

const PROJECTILE_SCENE := preload("res://scenes/objects/projectile.tscn")
const WEAK_POINT_SCENE := preload("res://scenes/boss/weak_point.tscn")

const BODY_RADIUS: float = 30.0
const BODY_COLOR := Color(0.2, 0.22, 0.35, 0.95)
const CORE_COLOR := Color(0.95, 0.9, 0.7, 0.95)
const HALO_COLOR := Color(0.55, 0.6, 0.9, 0.32)
const HURT_COLOR := Color(1.0, 0.95, 0.95, 1.0)

const ERA_TINTS := {
	0: Color(1.0, 0.75, 0.45),
	1: Color(0.95, 0.95, 1.0),
	2: Color(0.6, 0.75, 1.0),
}

const CYCLE_DURATION: float = 5.0
const WEAK_POINT_LIFETIME: float = 3.0
const PROJECTILE_BURST_INTERVAL: float = 1.6
const PROJECTILES_PER_BURST: int = 6
const PROJECTILE_SPEED: float = 220.0
const POST_HIT_PAUSE: float = 1.0

@export var max_hp: int = 3
@export var drift_radius: float = 40.0
@export var drift_speed: float = 0.6

## Arena centre. Set by the level script.
var arena_center: Vector2 = Vector2.ZERO
## One weak-point pocket per era. The level maps
## {0: Vector2, 1: Vector2, 2: Vector2} so the weak-point lands at a
## sensible place on each era's geometry.
var era_pockets: Dictionary = {}

var hp: int
var _cycle_timer: float = 0.0
var _burst_timer: float = 0.0
var _post_hit_timer: float = 0.0
var _hurt_flash: float = 0.0
var _anim_time: float = 0.0
var _defeated: bool = false
var _era_sequence: Array = [0, 1, 2]  # Past → Present → Future → Past…
var _era_index: int = 0
var _active_weak_point: Node2D = null


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	# Kick off with the first forced shift on the next physics tick.
	_cycle_timer = CYCLE_DURATION


func _physics_process(delta: float) -> void:
	if _defeated:
		return

	_anim_time += delta
	_hurt_flash = max(0.0, _hurt_flash - delta)
	_post_hit_timer = max(0.0, _post_hit_timer - delta)

	var t := _anim_time * drift_speed
	global_position = arena_center + Vector2(
		cos(t * 1.1) * drift_radius,
		sin(t * 1.5) * drift_radius * 0.7,
	)

	if _post_hit_timer <= 0.0:
		_burst_timer += delta
		if _burst_timer >= PROJECTILE_BURST_INTERVAL:
			_burst_timer = 0.0
			_fire_burst()

	_cycle_timer += delta
	if _cycle_timer >= CYCLE_DURATION:
		_cycle_timer = 0.0
		_begin_new_era_cycle()

	queue_redraw()


## ── Attack ──────────────────────────────────────────────────────────────

func _fire_burst() -> void:
	var base_angle: float = _anim_time * 0.4
	for i in range(PROJECTILES_PER_BURST):
		var angle: float = base_angle + (TAU / PROJECTILES_PER_BURST) * i
		var dir := Vector2(cos(angle), sin(angle))
		var proj := PROJECTILE_SCENE.instantiate()
		proj.global_position = global_position + dir * BODY_RADIUS
		proj.direction = dir
		proj.speed = PROJECTILE_SPEED
		proj.tracking = false
		get_tree().current_scene.add_child(proj)


## ── Era cycle ───────────────────────────────────────────────────────────

func _begin_new_era_cycle() -> void:
	if _active_weak_point != null and is_instance_valid(_active_weak_point):
		_active_weak_point.deactivate()
		_active_weak_point.queue_free()
		_active_weak_point = null

	# Advance era, force the shift, then spawn the matching weak-point.
	_era_index = (_era_index + 1) % _era_sequence.size()
	var target_era: int = _era_sequence[_era_index]
	TimeManager.current_era = target_era as TimeManager.Era
	LevelStateManager.swap_era(target_era)
	TimeManager.era_changed.emit(TimeManager.current_era)

	var pocket: Vector2 = era_pockets.get(target_era, arena_center)
	var wp := WEAK_POINT_SCENE.instantiate()
	wp.global_position = pocket
	wp.hit.connect(_on_weak_point_hit)
	get_tree().current_scene.add_child(wp)
	wp.activate(WEAK_POINT_LIFETIME, target_era)
	_active_weak_point = wp


func _on_weak_point_hit() -> void:
	if _defeated:
		return
	hp -= 1
	_hurt_flash = 0.4
	_post_hit_timer = POST_HIT_PAUSE
	_active_weak_point = null
	if hp <= 0:
		_defeat()


func _defeat() -> void:
	_defeated = true
	if _active_weak_point != null and is_instance_valid(_active_weak_point):
		_active_weak_point.deactivate()
		_active_weak_point.queue_free()
		_active_weak_point = null
	for proj in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(proj):
			proj.queue_free()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.05, 0.05), 0.9).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.9)
	tween.tween_callback(func() -> void:
		boss_defeated.emit()
	)


## ── Drawing ─────────────────────────────────────────────────────────────

func _draw() -> void:
	var color: Color = BODY_COLOR if _hurt_flash <= 0 else HURT_COLOR
	var current_tint: Color = ERA_TINTS.get(int(TimeManager.current_era), Color.WHITE)

	# Halo — era-tinted.
	var halo := HALO_COLOR
	halo.r *= current_tint.r
	halo.g *= current_tint.g
	halo.b *= current_tint.b
	var halo_pulse: float = 1.0 + 0.2 * sin(_anim_time * 2.5)
	draw_circle(Vector2.ZERO, BODY_RADIUS * 1.7 * halo_pulse, halo)

	# Rotating outer ring of arcs.
	var arcs: int = 3
	for i in range(arcs):
		var base: float = _anim_time * 0.9 + (TAU / arcs) * i
		draw_arc(Vector2.ZERO, BODY_RADIUS * 1.1, base, base + 0.9, 16, color.lightened(0.2), 3.0)

	# Body — ringed disc.
	draw_circle(Vector2.ZERO, BODY_RADIUS, color)
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0.0, TAU, 48, current_tint, 2.0)

	# Core.
	var core_pulse: float = sin(_anim_time * 3.4) * 0.25 + 0.75
	draw_circle(Vector2.ZERO, BODY_RADIUS * 0.5, CORE_COLOR * Color(1, 1, 1, core_pulse))

	# HP ticks.
	for i in range(max_hp):
		var a: float = -PI * 0.5 + (TAU / max_hp) * i
		var at := Vector2(cos(a), sin(a)) * BODY_RADIUS * 0.78
		var tick_col: Color = current_tint if i < hp else Color(0.2, 0.2, 0.25, 0.7)
		draw_circle(at, 3.0, tick_col)
