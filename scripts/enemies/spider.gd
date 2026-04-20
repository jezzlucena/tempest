extends CharacterBody2D

## The Wall Crawler — W2 boss.
## Cycles through CEILING (invulnerable, fires webs) → DROP → FLOOR
## (stompable) → CLIMB. Three stomps defeats it. Any non-stomp contact
## damages the player.

signal boss_defeated

const BODY_COLOR := Color(0.18, 0.1, 0.18, 1.0)
const LEG_COLOR := Color(0.25, 0.18, 0.3, 1.0)
const OUTLINE_COLOR := Color(0.9, 0.7, 0.85, 0.9)
const EYE_COLOR := Color(1.0, 0.3, 0.4, 1.0)
const HURT_COLOR := Color(1.0, 0.95, 0.95, 1.0)
const BODY_RADIUS: float = 22.0
const HEIGHT: float = 44.0
const STOMP_BOUNCE: float = 420.0

const PROJECTILE_SCENE := preload("res://scenes/objects/projectile.tscn")

enum State { CEILING, DROP, FLOOR_PATROL, CLIMB }

const CEILING_DURATION: float = 4.0
const DROP_DURATION: float = 0.35
const FLOOR_DURATION: float = 2.0
const CLIMB_DURATION: float = 0.5
const WEB_INTERVAL: float = 1.5
## Window after a stomp during which the spider takes no damage and deals
## no damage. Also drives the blink animation.
const INVULN_DURATION: float = 2.0
const INVULN_BLINK_HZ: float = 10.0

@export var max_hp: int = 3
@export var ceiling_speed: float = 140.0
@export var floor_speed: float = 80.0

## World-space Y for the spider's center while clinging to the ceiling and
## walking on the floor. Set by the level script after instantiation.
var ceiling_y: float = 0.0
var floor_y: float = 0.0
## Horizontal patrol bounds (spider center x). Set by the level script.
var patrol_left_x: float = -180.0
var patrol_right_x: float = 180.0

var hp: int
var _state: State = State.CEILING
var _state_timer: float = 0.0
var _web_timer: float = 0.0
var _moving_right: bool = true
var _defeated: bool = false
var _hurt_flash: float = 0.0
var _invuln_timer: float = 0.0
var _anim_time: float = 0.0
var _contact_area: Area2D
## Y origin/target pairs for DROP and CLIMB interpolation.
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
	# Start clinging to the ceiling.
	global_position.y = ceiling_y
	_enter_state(State.CEILING)


func _physics_process(delta: float) -> void:
	if _defeated:
		return

	_state_timer -= delta
	_anim_time += delta
	_hurt_flash = max(0.0, _hurt_flash - delta)

	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		# Blink — alternate full alpha with dim alpha at INVULN_BLINK_HZ.
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

	queue_redraw()


## ── State tick handlers ─────────────────────────────────────────────────

func _ceiling_tick(delta: float) -> void:
	_patrol_horizontal(delta, ceiling_speed)
	_web_timer -= delta
	if _web_timer <= 0.0:
		_web_timer = WEB_INTERVAL
		_fire_web()
	if _state_timer <= 0.0:
		_enter_state(State.DROP)


func _drop_tick(delta: float) -> void:
	# Linear descent from ceiling to floor.
	var t: float = 1.0 - (_state_timer / DROP_DURATION)
	t = clampf(t, 0.0, 1.0)
	global_position.y = lerp(_tween_from_y, _tween_to_y, _ease_out(t))
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		_enter_state(State.FLOOR_PATROL)


func _floor_tick(delta: float) -> void:
	_patrol_horizontal(delta, floor_speed)
	# Keep feet planted on the floor regardless of minor drift.
	global_position.y = floor_y
	if _state_timer <= 0.0:
		_enter_state(State.CLIMB)


func _climb_tick(delta: float) -> void:
	var t: float = 1.0 - (_state_timer / CLIMB_DURATION)
	t = clampf(t, 0.0, 1.0)
	global_position.y = lerp(_tween_from_y, _tween_to_y, _ease_out(t))
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		_enter_state(State.CEILING)


## ── State entry ─────────────────────────────────────────────────────────

func _enter_state(new_state: State) -> void:
	_state = new_state
	match new_state:
		State.CEILING:
			_state_timer = CEILING_DURATION
			_web_timer = WEB_INTERVAL * 0.5
			global_position.y = ceiling_y
		State.DROP:
			_state_timer = DROP_DURATION
			_tween_from_y = ceiling_y
			_tween_to_y = floor_y
		State.FLOOR_PATROL:
			_state_timer = FLOOR_DURATION
			global_position.y = floor_y
		State.CLIMB:
			_state_timer = CLIMB_DURATION
			_tween_from_y = global_position.y
			_tween_to_y = ceiling_y


## ── Shared helpers ──────────────────────────────────────────────────────

func _patrol_horizontal(delta: float, speed: float) -> void:
	var dir: float = 1.0 if _moving_right else -1.0
	global_position.x += dir * speed * delta
	if _moving_right and global_position.x >= patrol_right_x:
		global_position.x = patrol_right_x
		_moving_right = false
	elif not _moving_right and global_position.x <= patrol_left_x:
		global_position.x = patrol_left_x
		_moving_right = true


func _fire_web() -> void:
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position + Vector2(0, BODY_RADIUS)
	proj.direction = Vector2.DOWN
	proj.speed = 180.0
	proj.tracking = false
	get_tree().current_scene.add_child(proj)


func _ease_out(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)


## ── Damage ──────────────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if _defeated:
		return
	# After a stomp the spider is briefly untouchable — no damage either way.
	# Guards against the climbing spider re-contacting the bouncing player
	# before the deferred monitoring-disable has taken effect.
	if _invuln_timer > 0.0:
		return
	if body != GameManager.player:
		return
	var player_body: CharacterBody2D = body as CharacterBody2D
	if player_body == null:
		return
	# Stomp is only valid while the spider is grounded (FLOOR_PATROL) and
	# the player is above its midpoint. Any other contact damages player.
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
	_hurt_flash = 0.35
	var up: Vector2 = GravityManager.get_up_direction()
	player_body.velocity = up * STOMP_BOUNCE
	if hp <= 0:
		_defeat()
		return
	# Brief i-frames: the spider is untouchable while it retreats, so the
	# ascending player cannot be caught by its climb tween.
	_invuln_timer = INVULN_DURATION
	_contact_area.set_deferred("monitoring", false)
	# Knock the spider back into CLIMB — closes the stomp window so the
	# player has to survive another full cycle to reach the next hit.
	_enter_state(State.CLIMB)


func _defeat() -> void:
	_defeated = true
	velocity = Vector2.ZERO
	_contact_area.set_deferred("monitoring", false)
	# Drop any in-flight webs so the arena clears.
	for proj in get_tree().get_nodes_in_group("projectiles"):
		if proj is Node:
			proj.queue_free()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 0.3), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void:
		boss_defeated.emit()
	)


## ── Drawing ─────────────────────────────────────────────────────────────

func _draw() -> void:
	var on_ceiling: bool = _state == State.CEILING
	# Flip vertically when on the ceiling so legs point "up" toward it.
	var sign_y: float = -1.0 if on_ceiling else 1.0

	var color: Color = BODY_COLOR if _hurt_flash <= 0 else HURT_COLOR

	# Legs — 8 angled segments, animated by patrol.
	var leg_phase: float = _anim_time * (4.0 if _state == State.CEILING or _state == State.FLOOR_PATROL else 1.5)
	for i in range(8):
		var base_angle: float = PI * 0.25 + (TAU / 8.0) * i
		var swing: float = sin(leg_phase + i * 0.6) * 0.25
		var angle: float = base_angle + swing
		var leg_dir := Vector2(cos(angle), sin(angle) * sign_y)
		var joint: Vector2 = leg_dir * BODY_RADIUS * 1.3
		var tip: Vector2 = joint + Vector2(cos(angle + swing), sin(angle + swing) * sign_y) * BODY_RADIUS * 1.1
		draw_line(Vector2.ZERO, joint, LEG_COLOR, 3.0)
		draw_line(joint, tip, LEG_COLOR, 2.5)

	# Body — circle + highlight outline.
	draw_circle(Vector2.ZERO, BODY_RADIUS, color)
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0.0, TAU, 32, OUTLINE_COLOR, 1.5)

	# Eyes — two on the underside (down when on ceiling, down means toward the player).
	var eye_y_base: float = BODY_RADIUS * 0.3 * sign_y
	var pulse: float = sin(_anim_time * 3.0) * 0.25 + 0.75
	var eye_col := EYE_COLOR
	eye_col.a = pulse
	draw_circle(Vector2(-6.0, eye_y_base), 3.0, eye_col)
	draw_circle(Vector2(6.0, eye_y_base), 3.0, eye_col)
