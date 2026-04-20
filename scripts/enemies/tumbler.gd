extends CharacterBody2D

## The Tumbler — W3 boss.
##
## Same cycle shape as the spider (CEILING → DROP → FLOOR → CLIMB) but
## expressed in gravity-local coordinates around a fixed arena center, so
## every reference to "ceiling" and "floor" automatically follows whichever
## wall gravity currently points toward. Each successful stomp forces a
## 90° CW gravity rotation, giving the player three re-orientations across
## the fight. Defeat grants ABILITY_GRAVITY.

signal boss_defeated

const BODY_COLOR := Color(0.14, 0.16, 0.28, 1.0)
const PANEL_COLOR := Color(0.25, 0.3, 0.45, 1.0)
const OUTLINE_COLOR := Color(0.85, 0.9, 1.0, 0.9)
const EYE_COLOR := Color(0.95, 0.75, 0.35, 1.0)
const HURT_COLOR := Color(1.0, 0.95, 0.95, 1.0)
const BODY_RADIUS: float = 26.0
const HEIGHT: float = 52.0
const STOMP_BOUNCE: float = 420.0

enum State { CEILING, DROP, FLOOR_PATROL, CLIMB }

const CEILING_DURATION: float = 3.5
const DROP_DURATION: float = 0.35
const FLOOR_DURATION: float = 2.0
const CLIMB_DURATION: float = 0.6
const INVULN_DURATION: float = 2.0
const INVULN_BLINK_HZ: float = 10.0

@export var max_hp: int = 3
@export var ceiling_speed: float = 140.0
@export var floor_speed: float = 80.0

## World center of the arena. Tumbler position is always derived by
## rotating a gravity-local offset around this point.
var arena_center: Vector2 = Vector2.ZERO
## Distance from the arena center to the ceiling (positive — along up)
## and to the floor (also positive — along -up).
var ceiling_offset: float = 170.0
var floor_offset: float = 170.0
## Half-range of the Tumbler's patrol along the lateral axis.
var patrol_range: float = 170.0

var hp: int
var _state: State = State.CEILING
var _state_timer: float = 0.0
var _moving_forward: bool = true
var _defeated: bool = false
var _hurt_flash: float = 0.0
var _invuln_timer: float = 0.0
var _anim_time: float = 0.0
var _contact_area: Area2D

## Gravity-local position: x is lateral (perpendicular to up), y is
## signed distance along up (+ = toward ceiling, - = toward floor).
## World position is recomputed every physics tick from current gravity.
var _rel_x: float = 0.0
var _rel_y: float = 0.0
## Tween endpoints for DROP and CLIMB along the up-axis.
var _tween_from_y: float = 0.0
var _tween_to_y: float = 0.0


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_contact_area = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BODY_RADIUS + 2.0
	shape.shape = circle
	_contact_area.add_child(shape)
	_contact_area.body_entered.connect(_on_body_entered)
	_contact_area.collision_layer = 0
	_contact_area.collision_mask = 1
	add_child(_contact_area)

	_rel_y = ceiling_offset
	_rel_x = 0.0
	_apply_world_position()
	_enter_state(State.CEILING)


func _physics_process(delta: float) -> void:
	if _defeated:
		return

	_state_timer -= delta
	_anim_time += delta
	_hurt_flash = max(0.0, _hurt_flash - delta)

	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		var phase: int = int(_invuln_timer * INVULN_BLINK_HZ)
		modulate.a = 1.0 if (phase % 2) == 0 else 0.3
		if _invuln_timer <= 0.0:
			_invuln_timer = 0.0
			modulate.a = 1.0
			_contact_area.monitoring = true

	match _state:
		State.CEILING: _ceiling_tick(delta)
		State.DROP: _drop_tick(delta)
		State.FLOOR_PATROL: _floor_tick(delta)
		State.CLIMB: _climb_tick(delta)

	_apply_world_position()
	queue_redraw()


## ── State tick handlers ─────────────────────────────────────────────────

func _ceiling_tick(delta: float) -> void:
	_patrol_lateral(delta, ceiling_speed)
	if _state_timer <= 0.0:
		_enter_state(State.DROP)


func _drop_tick(delta: float) -> void:
	var t: float = 1.0 - (_state_timer / DROP_DURATION)
	t = clampf(t, 0.0, 1.0)
	_rel_y = lerp(_tween_from_y, _tween_to_y, _ease_out(t))
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		_enter_state(State.FLOOR_PATROL)


func _floor_tick(delta: float) -> void:
	_patrol_lateral(delta, floor_speed)
	_rel_y = -floor_offset
	if _state_timer <= 0.0:
		_enter_state(State.CLIMB)


func _climb_tick(delta: float) -> void:
	var t: float = 1.0 - (_state_timer / CLIMB_DURATION)
	t = clampf(t, 0.0, 1.0)
	_rel_y = lerp(_tween_from_y, _tween_to_y, _ease_out(t))
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		_enter_state(State.CEILING)


## ── State entry ─────────────────────────────────────────────────────────

func _enter_state(new_state: State) -> void:
	_state = new_state
	match new_state:
		State.CEILING:
			_state_timer = CEILING_DURATION
			_rel_y = ceiling_offset
		State.DROP:
			_state_timer = DROP_DURATION
			_tween_from_y = ceiling_offset
			_tween_to_y = -floor_offset
		State.FLOOR_PATROL:
			_state_timer = FLOOR_DURATION
			_rel_y = -floor_offset
		State.CLIMB:
			_state_timer = CLIMB_DURATION
			_tween_from_y = _rel_y
			_tween_to_y = ceiling_offset


## ── Shared helpers ──────────────────────────────────────────────────────

func _patrol_lateral(delta: float, speed: float) -> void:
	var dir: float = 1.0 if _moving_forward else -1.0
	_rel_x += dir * speed * delta
	if _moving_forward and _rel_x >= patrol_range:
		_rel_x = patrol_range
		_moving_forward = false
	elif not _moving_forward and _rel_x <= -patrol_range:
		_rel_x = -patrol_range
		_moving_forward = true


func _apply_world_position() -> void:
	var up: Vector2 = GravityManager.get_up_direction()
	# 90° CCW from up = right-handed lateral axis in gravity-local space.
	var lateral: Vector2 = Vector2(-up.y, up.x)
	global_position = arena_center + lateral * _rel_x + up * _rel_y


func _ease_out(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)


## ── Damage ──────────────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if _defeated:
		return
	if _invuln_timer > 0.0:
		return
	if body != GameManager.player:
		return
	var player_body: CharacterBody2D = body as CharacterBody2D
	if player_body == null:
		return

	var up: Vector2 = GravityManager.get_up_direction()
	var rel: Vector2 = player_body.global_position - global_position
	var above_amount: float = rel.dot(up)
	var is_above: bool = above_amount > HEIGHT * 0.3

	if _state == State.FLOOR_PATROL and is_above:
		_take_stomp(player_body)
	else:
		player_body.take_damage(1)


func _take_stomp(player_body: CharacterBody2D) -> void:
	hp -= 1
	_hurt_flash = 0.4
	var up: Vector2 = GravityManager.get_up_direction()
	player_body.velocity = up * STOMP_BOUNCE
	if hp <= 0:
		_defeat()
		return
	_invuln_timer = INVULN_DURATION
	_contact_area.set_deferred("monitoring", false)
	# Force a 90° CW rotation — the arena tumbles around the player.
	GravityManager.rotate_gravity(1, true)
	_enter_state(State.CLIMB)


func _defeat() -> void:
	_defeated = true
	velocity = Vector2.ZERO
	_contact_area.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 0.3), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void:
		boss_defeated.emit()
	)


## ── Drawing ─────────────────────────────────────────────────────────────

func _draw() -> void:
	# Rotate local drawing so the body's "top" always faces the current up
	# direction — reads correctly across gravity orientations.
	draw_set_transform(Vector2.ZERO, -GravityManager.gravity_angle_radians)

	var color: Color = BODY_COLOR if _hurt_flash <= 0 else HURT_COLOR

	# Outer hex — angular, rotating with anim_time.
	var sides: int = 6
	var rotation_offset: float = _anim_time * 0.8
	var outer := PackedVector2Array()
	for i in range(sides):
		var angle: float = rotation_offset + (TAU / sides) * i
		outer.append(Vector2(cos(angle), sin(angle)) * BODY_RADIUS)
	draw_colored_polygon(outer, color)
	draw_polyline(outer + PackedVector2Array([outer[0]]), OUTLINE_COLOR, 1.5)

	# Inner counter-rotating diamond for visual layering.
	var inner := PackedVector2Array()
	for i in range(4):
		var angle: float = -rotation_offset * 1.4 + (TAU / 4.0) * i
		inner.append(Vector2(cos(angle), sin(angle)) * BODY_RADIUS * 0.55)
	draw_colored_polygon(inner, PANEL_COLOR)

	# A single "eye" pointing in the direction of motion / toward the floor
	# while patrolling. Points toward -y in local gravity-space (down).
	var eye_pulse: float = sin(_anim_time * 3.2) * 0.25 + 0.75
	var eye_col := EYE_COLOR
	eye_col.a = eye_pulse
	var facing_x: float = 1.0 if _moving_forward else -1.0
	# When on the floor, the eye peers down-forward; on the ceiling, up.
	var eye_y: float = BODY_RADIUS * 0.35 if _state == State.FLOOR_PATROL else -BODY_RADIUS * 0.35
	draw_circle(Vector2(facing_x * 4.0, eye_y), 4.0, eye_col)
