extends CharacterBody2D

## The Wanderer — player character.
## Properties are public for states to read. Movement logic is in state scripts.

signal hp_changed(new_hp: int)
signal died

const SPEED: float = 300.0
const JUMP_VELOCITY: float = 500.0
var MAX_HP: int = 3

## Dilation casting
const DILATION_SCENE := preload("res://scenes/objects/dilation_field.tscn")
const DILATION_RANGE: float = 256.0  # ~8 tiles
const DILATION_COOLDOWN: float = 6.0  # 4s duration + 2s after expiry
const AIM_COLOR := Color(0.4, 0.6, 1.0, 0.4)
const AIM_INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.3)

## Visual
const PLAYER_WIDTH: float = 24.0
const PLAYER_HEIGHT: float = 48.0
const PLAYER_COLOR: Color = Color(0.1, 0.1, 0.12, 1.0)
const EYE_COLOR: Color = Color(0.6, 0.8, 1.0, 1.0)
const HURT_FLASH_COLOR: Color = Color(1.0, 0.3, 0.3, 0.7)

enum VisualState { IDLE, RUN, JUMP, FALL, WALL_SLIDE, HURT, LAND }

var hp: int = MAX_HP
var is_invincible: bool = false
var facing_right: bool = true
var visual_state: VisualState = VisualState.IDLE
var _land_timer: float = 0.0
const LAND_DURATION: float = 0.15

## Dilation state
var is_aiming_dilation: bool = false
var dilation_aim_pos: Vector2 = Vector2.ZERO
var _dilation_cooldown: float = 0.0

@onready var state_machine: Node = $StateMachine


func _ready() -> void:
	up_direction = GravityManager.get_up_direction()
	GameManager.register_player(self)


func _physics_process(_delta: float) -> void:
	up_direction = GravityManager.get_up_direction()
	# Rotate collision shape so the player's "tall" axis aligns with gravity
	var grav_rot := -GravityManager.gravity_angle_radians
	$CollisionShape2D.rotation = grav_rot
	$CollisionShape2D.position = Vector2(0, -24).rotated(grav_rot)


func _process(delta: float) -> void:
	# Facing direction
	var input_dir := Input.get_axis("move_left", "move_right")
	if input_dir > 0.1:
		facing_right = true
	elif input_dir < -0.1:
		facing_right = false

	# Landing timer
	if _land_timer > 0:
		_land_timer -= delta
		if _land_timer <= 0:
			visual_state = VisualState.IDLE

	# Dilation cooldown
	if _dilation_cooldown > 0:
		_dilation_cooldown -= delta

	# Dilation aiming (gated on ability)
	if GameManager.has_ability(GameManager.ABILITY_DILATION):
		if Input.is_action_pressed("dilation_cast"):
			is_aiming_dilation = true
			dilation_aim_pos = get_global_mouse_position()
		elif is_aiming_dilation:
			# Released — place the field
			is_aiming_dilation = false
			_try_cast_dilation()
	elif is_aiming_dilation:
		is_aiming_dilation = false

	queue_redraw()


func take_damage(amount: int = 1) -> void:
	if is_invincible:
		return
	if hp <= 0:
		return
	hp = max(hp - amount, 0)
	hp_changed.emit(hp)
	if hp <= 0:
		died.emit()
	state_machine.transition_to("hurt")


func reset_hp() -> void:
	hp = MAX_HP
	is_invincible = true
	hp_changed.emit(hp)
	# Brief post-respawn invincibility
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		is_invincible = false
	)


func trigger_land() -> void:
	visual_state = VisualState.LAND
	_land_timer = LAND_DURATION


func can_cast_dilation() -> bool:
	return _dilation_cooldown <= 0


func get_dilation_cooldown_progress() -> float:
	return clampf(1.0 - _dilation_cooldown / DILATION_COOLDOWN, 0.0, 1.0)


func _try_cast_dilation() -> void:
	if not can_cast_dilation():
		return
	var dist := global_position.distance_to(dilation_aim_pos)
	if dist > DILATION_RANGE:
		return
	var field := DILATION_SCENE.instantiate()
	field.global_position = dilation_aim_pos
	get_tree().current_scene.add_child(field)
	_dilation_cooldown = DILATION_COOLDOWN


func _draw() -> void:
	# Rotate sprite to align with gravity — feet toward gravity, head away.
	# The camera view rotates by +gravity_angle on screen, so drawing at
	# -gravity_angle in local space cancels out → character appears upright.
	var grav_rot := -GravityManager.gravity_angle_radians
	draw_set_transform(Vector2.ZERO, grav_rot)

	var color := HURT_FLASH_COLOR if is_invincible else PLAYER_COLOR
	var f := 1.0 if facing_right else -1.0

	match visual_state:
		VisualState.IDLE:
			_draw_idle(color, f)
		VisualState.RUN:
			_draw_run(color, f)
		VisualState.JUMP:
			_draw_jump(color, f)
		VisualState.FALL:
			_draw_fall(color, f)
		VisualState.WALL_SLIDE:
			_draw_wall_slide(color, f)
		VisualState.HURT:
			_draw_hurt(color, f)
		VisualState.LAND:
			_draw_land(color, f)
		_:
			_draw_idle(color, f)

	# Reset transform for world-space overlays
	draw_set_transform(Vector2.ZERO, 0.0)

	# Dilation aim indicator (drawn in world-local space, not gravity-rotated)
	if is_aiming_dilation:
		var aim_local := to_local(dilation_aim_pos)
		var dist := global_position.distance_to(dilation_aim_pos)
		var in_range := dist <= DILATION_RANGE and can_cast_dilation()
		var aim_col := AIM_COLOR if in_range else AIM_INVALID_COLOR
		draw_circle(aim_local, 96.0, Color(aim_col.r, aim_col.g, aim_col.b, 0.08))
		draw_arc(aim_local, 96.0, 0, TAU, 48, aim_col, 1.5)
		# Line from player center to aim point
		var center_offset := Vector2(0, -PLAYER_HEIGHT / 2).rotated(grav_rot)
		draw_line(center_offset, aim_local, aim_col, 1.0)


## ── Visual state drawing functions ──────────────────────────────────────────
## f = facing multiplier: 1.0 for right, -1.0 for left
## All drawing happens in gravity-rotated space (draw_set_transform already applied)

const LEG_COLOR := Color(0.08, 0.08, 0.1, 1.0)
const ARM_COLOR := Color(0.13, 0.13, 0.15, 1.0)
const OUTLINE_COLOR := Color(0.9, 0.9, 0.95, 0.8)
const OUTLINE_WIDTH := 1.5
var _run_cycle: float = 0.0


func _draw_body(poly: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(poly, color)
	draw_polyline(poly + PackedVector2Array([poly[0]]), OUTLINE_COLOR, OUTLINE_WIDTH)


func _draw_limb(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(rect, OUTLINE_COLOR, false, OUTLINE_WIDTH)


func _draw_eye(f: float, offset_y: float = 0.0) -> void:
	draw_circle(Vector2(f * 3.0, -PLAYER_HEIGHT * 0.72 + offset_y), 3.0, EYE_COLOR)


func _draw_idle(color: Color, f: float) -> void:
	var hw := PLAYER_WIDTH / 2
	# Body — slight trapezoid (wider at shoulders)
	var body := PackedVector2Array([
		Vector2(-hw * 0.7, 0),           # left foot
		Vector2(hw * 0.7, 0),            # right foot
		Vector2(hw, -PLAYER_HEIGHT * 0.7),  # right shoulder
		Vector2(hw * 0.6, -PLAYER_HEIGHT),  # right head
		Vector2(-hw * 0.6, -PLAYER_HEIGHT), # left head
		Vector2(-hw, -PLAYER_HEIGHT * 0.7), # left shoulder
	])
	_draw_body(body, color)
	# Legs — two thin rectangles
	_draw_limb(Rect2(-hw * 0.45, -4, hw * 0.35, 4), LEG_COLOR)
	_draw_limb(Rect2(hw * 0.1, -4, hw * 0.35, 4), LEG_COLOR)
	_draw_eye(f)


func _draw_run(color: Color, f: float) -> void:
	_run_cycle += 0.25  # Advances each redraw
	var hw := PLAYER_WIDTH / 2
	var lean := f * 3.0  # Lean forward
	# Body — leaning forward
	var body := PackedVector2Array([
		Vector2(-hw * 0.7, 0),
		Vector2(hw * 0.7, 0),
		Vector2(hw + lean, -PLAYER_HEIGHT * 0.7),
		Vector2(hw * 0.6 + lean, -PLAYER_HEIGHT),
		Vector2(-hw * 0.6 + lean, -PLAYER_HEIGHT),
		Vector2(-hw + lean, -PLAYER_HEIGHT * 0.7),
	])
	_draw_body(body, color)
	# Legs — alternating stride
	var stride := sin(_run_cycle) * 5.0
	_draw_limb(Rect2(-hw * 0.3 + stride, -4, hw * 0.3, 4), LEG_COLOR)
	_draw_limb(Rect2(hw * 0.0 - stride, -4, hw * 0.3, 4), LEG_COLOR)
	# Arm swing
	var arm_swing := sin(_run_cycle) * 6.0
	_draw_limb(Rect2(f * hw * 0.8 + lean, -PLAYER_HEIGHT * 0.55 + arm_swing, f * 4, 12), ARM_COLOR)
	_draw_eye(f)


func _draw_jump(color: Color, f: float) -> void:
	var hw := PLAYER_WIDTH / 2
	# Body — stretched upward
	var body := PackedVector2Array([
		Vector2(-hw * 0.5, 0),
		Vector2(hw * 0.5, 0),
		Vector2(hw * 0.8, -PLAYER_HEIGHT * 0.65),
		Vector2(hw * 0.5, -PLAYER_HEIGHT - 3),
		Vector2(-hw * 0.5, -PLAYER_HEIGHT - 3),
		Vector2(-hw * 0.8, -PLAYER_HEIGHT * 0.65),
	])
	_draw_body(body, color)
	# Legs — tucked together
	_draw_limb(Rect2(-hw * 0.25, -2, hw * 0.5, 4), LEG_COLOR)
	# Arms — raised
	_draw_limb(Rect2(-hw - 3, -PLAYER_HEIGHT * 0.8, 4, -10), ARM_COLOR)
	_draw_limb(Rect2(hw - 1, -PLAYER_HEIGHT * 0.8, 4, -10), ARM_COLOR)
	_draw_eye(f, -3.0)


func _draw_fall(color: Color, f: float) -> void:
	var hw := PLAYER_WIDTH / 2
	# Body — slightly compressed, limbs spread
	var body := PackedVector2Array([
		Vector2(-hw * 0.8, 0),
		Vector2(hw * 0.8, 0),
		Vector2(hw * 0.9, -PLAYER_HEIGHT * 0.7),
		Vector2(hw * 0.5, -PLAYER_HEIGHT + 2),
		Vector2(-hw * 0.5, -PLAYER_HEIGHT + 2),
		Vector2(-hw * 0.9, -PLAYER_HEIGHT * 0.7),
	])
	_draw_body(body, color)
	# Legs — spread apart
	_draw_limb(Rect2(-hw * 0.6, -3, hw * 0.3, 5), LEG_COLOR)
	_draw_limb(Rect2(hw * 0.3, -3, hw * 0.3, 5), LEG_COLOR)
	# Arms — out to sides
	_draw_limb(Rect2(-hw - 5, -PLAYER_HEIGHT * 0.6, 6, 4), ARM_COLOR)
	_draw_limb(Rect2(hw - 1, -PLAYER_HEIGHT * 0.6, 6, 4), ARM_COLOR)
	_draw_eye(f, 2.0)


func _draw_wall_slide(color: Color, f: float) -> void:
	var hw := PLAYER_WIDTH / 2
	# Body — pressed against wall, slightly compressed
	var wall_offset := -f * 3.0  # Shift toward the wall
	var body := PackedVector2Array([
		Vector2(-hw * 0.6 + wall_offset, 0),
		Vector2(hw * 0.6 + wall_offset, 0),
		Vector2(hw * 0.7 + wall_offset, -PLAYER_HEIGHT * 0.7),
		Vector2(hw * 0.5 + wall_offset, -PLAYER_HEIGHT + 3),
		Vector2(-hw * 0.5 + wall_offset, -PLAYER_HEIGHT + 3),
		Vector2(-hw * 0.7 + wall_offset, -PLAYER_HEIGHT * 0.7),
	])
	_draw_body(body, color)
	# Hand gripping wall
	_draw_limb(Rect2(-f * hw + wall_offset, -PLAYER_HEIGHT * 0.65, -f * 5, 6), ARM_COLOR)
	# Legs — bent
	_draw_limb(Rect2(-hw * 0.3 + wall_offset, -3, hw * 0.6, 4), LEG_COLOR)
	_draw_eye(f, 3.0)


func _draw_hurt(color: Color, f: float) -> void:
	var hw := PLAYER_WIDTH / 2
	# Body — recoiling backward
	var lean := -f * 5.0
	var body := PackedVector2Array([
		Vector2(-hw * 0.8, 0),
		Vector2(hw * 0.6, 0),
		Vector2(hw * 0.7 + lean, -PLAYER_HEIGHT * 0.65),
		Vector2(hw * 0.4 + lean, -PLAYER_HEIGHT + 4),
		Vector2(-hw * 0.4 + lean, -PLAYER_HEIGHT + 4),
		Vector2(-hw * 0.7 + lean, -PLAYER_HEIGHT * 0.65),
	])
	_draw_body(body, color)
	# Eye — squinting (smaller)
	draw_circle(Vector2(f * 3.0 + lean, -PLAYER_HEIGHT * 0.7 + 4), 2.0, EYE_COLOR)


func _draw_land(color: Color, f: float) -> void:
	var hw := PLAYER_WIDTH / 2
	# Body — squashed on landing
	var squash := 1.0 - (_land_timer / LAND_DURATION) * 0.3  # 0.7 to 1.0
	var w_stretch := 1.0 + (1.0 - squash) * 0.5  # Wider when squashed
	var body := PackedVector2Array([
		Vector2(-hw * w_stretch, 0),
		Vector2(hw * w_stretch, 0),
		Vector2(hw * w_stretch * 0.9, -PLAYER_HEIGHT * 0.7 * squash),
		Vector2(hw * 0.5, -PLAYER_HEIGHT * squash),
		Vector2(-hw * 0.5, -PLAYER_HEIGHT * squash),
		Vector2(-hw * w_stretch * 0.9, -PLAYER_HEIGHT * 0.7 * squash),
	])
	_draw_body(body, color)
	# Legs — wide bent
	_draw_limb(Rect2(-hw * w_stretch * 0.6, -4, hw * 0.35, 5), LEG_COLOR)
	_draw_limb(Rect2(hw * w_stretch * 0.25, -4, hw * 0.35, 5), LEG_COLOR)
	_draw_eye(f, (1.0 - squash) * 8.0)
