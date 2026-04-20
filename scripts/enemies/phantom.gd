extends Node2D

## The Phantom — W4 boss.
##
## Drifts slowly near the arena centre firing radial projectile bursts.
## Every cycle it marks a random permanent dilation field by spawning a
## weak_point.tscn at its centre. The player must reach that field (its
## interior slows the projectiles to 20%, making the approach feasible)
## and touch the weak-point before it expires. Three hits defeats the
## boss and grants ABILITY_DILATION.

signal boss_defeated

const PROJECTILE_SCENE := preload("res://scenes/objects/projectile.tscn")
const WEAK_POINT_SCENE := preload("res://scenes/boss/weak_point.tscn")

const BODY_RADIUS: float = 28.0
const BODY_COLOR := Color(0.35, 0.2, 0.45, 0.9)
const BODY_CORE := Color(0.9, 0.7, 1.0, 0.9)
const HALO_COLOR := Color(0.7, 0.5, 1.0, 0.35)
const HURT_COLOR := Color(1.0, 0.95, 0.95, 1.0)

const CYCLE_DURATION: float = 4.0
const WEAK_POINT_LIFETIME: float = 3.0
const PROJECTILE_BURST_INTERVAL: float = 1.4
const PROJECTILES_PER_BURST: int = 8
const PROJECTILE_SPEED: float = 240.0
## Pause firing briefly after a hit so the player has a chance to reset.
const POST_HIT_PAUSE: float = 1.0

@export var max_hp: int = 3
## Half-amplitude of the phantom's drift oscillation around arena_center.
@export var drift_radius: float = 48.0
@export var drift_speed: float = 0.7

## Arena centre — world space. Set by the level script.
var arena_center: Vector2 = Vector2.ZERO

var hp: int
var _cycle_timer: float = 0.0
var _burst_timer: float = 0.0
var _post_hit_timer: float = 0.0
var _hurt_flash: float = 0.0
var _anim_time: float = 0.0
var _defeated: bool = false
var _active_weak_point: Node2D = null
var _burst_rotation: float = 0.0


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if _defeated:
		return

	_anim_time += delta
	_hurt_flash = max(0.0, _hurt_flash - delta)
	_post_hit_timer = max(0.0, _post_hit_timer - delta)

	# Drift in a gentle Lissajous pattern around arena_center.
	var t := _anim_time * drift_speed
	global_position = arena_center + Vector2(
		cos(t * 1.3) * drift_radius,
		sin(t * 1.7) * drift_radius * 0.6,
	)

	if _post_hit_timer <= 0.0:
		_burst_timer += delta
		if _burst_timer >= PROJECTILE_BURST_INTERVAL:
			_burst_timer = 0.0
			_fire_radial_burst()

	_cycle_timer += delta
	if _cycle_timer >= CYCLE_DURATION:
		_cycle_timer = 0.0
		_mark_dilation_field()

	queue_redraw()


## ── Attack pattern ──────────────────────────────────────────────────────

func _fire_radial_burst() -> void:
	_burst_rotation += PI * 0.13  # shift angle each burst for interest
	var base_angle: float = _burst_rotation
	for i in range(PROJECTILES_PER_BURST):
		var angle: float = base_angle + (TAU / PROJECTILES_PER_BURST) * i
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var proj := PROJECTILE_SCENE.instantiate()
		proj.global_position = global_position + dir * BODY_RADIUS
		proj.direction = dir
		proj.speed = PROJECTILE_SPEED
		proj.tracking = false
		get_tree().current_scene.add_child(proj)


## ── Dilation-field weak point ───────────────────────────────────────────

func _mark_dilation_field() -> void:
	# Clear any stale weak-point from a previous cycle.
	if _active_weak_point != null and is_instance_valid(_active_weak_point):
		_active_weak_point.deactivate()
		_active_weak_point.queue_free()
		_active_weak_point = null

	var fields: Array = TimeManager.dilation_fields.duplicate()
	# Filter to valid fields only.
	var valid: Array = []
	for f in fields:
		if is_instance_valid(f):
			valid.append(f)
	if valid.is_empty():
		return
	var target: Node2D = valid[randi() % valid.size()]
	var wp := WEAK_POINT_SCENE.instantiate()
	wp.global_position = target.global_position
	wp.hit.connect(_on_weak_point_hit)
	get_tree().current_scene.add_child(wp)
	wp.activate(WEAK_POINT_LIFETIME, -1)
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
	# Clear any in-flight projectiles.
	for proj in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(proj):
			proj.queue_free()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.05, 0.05), 0.8).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func() -> void:
		boss_defeated.emit()
	)


## ── Drawing ─────────────────────────────────────────────────────────────

func _draw() -> void:
	var color: Color = BODY_COLOR if _hurt_flash <= 0 else HURT_COLOR

	# Halo — pulses with burst cadence.
	var halo_scale: float = 1.0 + 0.25 * clampf(1.0 - _burst_timer / PROJECTILE_BURST_INTERVAL, 0.0, 1.0)
	var halo_col := HALO_COLOR
	halo_col.a *= halo_scale
	draw_circle(Vector2.ZERO, BODY_RADIUS * 1.6 * halo_scale, halo_col)

	# Rotating tri-vane silhouette.
	var vanes: int = 3
	for i in range(vanes):
		var angle: float = _anim_time * 1.4 + (TAU / vanes) * i
		var tip: Vector2 = Vector2(cos(angle), sin(angle)) * BODY_RADIUS * 1.2
		var base_a: Vector2 = Vector2(cos(angle + 0.5), sin(angle + 0.5)) * BODY_RADIUS * 0.3
		var base_b: Vector2 = Vector2(cos(angle - 0.5), sin(angle - 0.5)) * BODY_RADIUS * 0.3
		draw_colored_polygon(PackedVector2Array([tip, base_a, base_b]), color)

	# Core orb.
	var pulse: float = sin(_anim_time * 4.0) * 0.2 + 0.8
	draw_circle(Vector2.ZERO, BODY_RADIUS * 0.55, BODY_CORE * Color(1, 1, 1, pulse))

	# HP ticks around the body.
	for i in range(max_hp):
		var angle: float = -PI * 0.5 + (TAU / max_hp) * i
		var at: Vector2 = Vector2(cos(angle), sin(angle)) * BODY_RADIUS * 0.9
		var filled: bool = i < hp
		var tick_col := BODY_CORE if filled else Color(0.2, 0.1, 0.25, 0.7)
		draw_circle(at, 3.0, tick_col)
