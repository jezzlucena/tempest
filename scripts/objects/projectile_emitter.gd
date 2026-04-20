extends Node2D

## Projectile emitter — a simple stationary turret that fires projectiles
## in a fixed direction at a fixed interval. Used in W4-1 to create the
## bullet-storm gallery.
##
## The emitter respects time dilation: if it sits inside a dilation field,
## its fire interval slows along with the rest of the world.

const PROJECTILE_SCENE := preload("res://scenes/objects/projectile.tscn")

## Direction the turret fires. Does not need to be normalized; the script
## normalises internally.
@export var direction: Vector2 = Vector2.DOWN
@export var projectile_speed: float = 220.0
@export var fire_interval: float = 1.8
## Seconds to wait before the first shot. Use this to desynchronise
## adjacent turrets.
@export var start_delay: float = 0.0
## Visual orientation of the turret chassis. If negative, the script
## derives it from `direction` on ready.
@export var muzzle_angle: float = -TAU

const CHASSIS_SIZE: float = 18.0
const MUZZLE_LENGTH: float = 12.0
const CHASSIS_COLOR := Color(0.25, 0.25, 0.32, 1.0)
const CHASSIS_ACCENT := Color(0.45, 0.45, 0.55, 1.0)
const MUZZLE_COLOR := Color(0.85, 0.35, 0.25, 1.0)

var _timer: float = 0.0


func _ready() -> void:
	if muzzle_angle < -PI:
		muzzle_angle = direction.angle()
	_timer = -start_delay


func _process(delta: float) -> void:
	var scaled: float = TimeManager.get_scaled_delta(self, delta)
	_timer += scaled
	if _timer >= fire_interval:
		_timer -= fire_interval
		_fire()
	queue_redraw()


func _fire() -> void:
	var proj := PROJECTILE_SCENE.instantiate()
	var dir: Vector2 = direction.normalized()
	# Spawn just outside the chassis so it doesn't immediately collide
	# with a turret-adjacent wall tile.
	proj.global_position = global_position + dir * (CHASSIS_SIZE * 0.5 + MUZZLE_LENGTH)
	proj.direction = dir
	proj.speed = projectile_speed
	proj.tracking = false
	get_tree().current_scene.add_child(proj)


func _draw() -> void:
	# Chassis — a squat rectangle perpendicular to the firing direction.
	var perp := Vector2(-sin(muzzle_angle), cos(muzzle_angle))
	var half_w := CHASSIS_SIZE * 0.5
	var corners := PackedVector2Array([
		perp * -half_w + Vector2(cos(muzzle_angle), sin(muzzle_angle)) * -half_w,
		perp *  half_w + Vector2(cos(muzzle_angle), sin(muzzle_angle)) * -half_w,
		perp *  half_w + Vector2(cos(muzzle_angle), sin(muzzle_angle)) *  half_w,
		perp * -half_w + Vector2(cos(muzzle_angle), sin(muzzle_angle)) *  half_w,
	])
	draw_colored_polygon(corners, CHASSIS_COLOR)
	draw_polyline(corners + PackedVector2Array([corners[0]]), CHASSIS_ACCENT, 1.5)

	# Muzzle — a short line in the firing direction, brightening as the
	# next shot nears.
	var charge: float = clampf(_timer / fire_interval, 0.0, 1.0)
	var muzzle_start: Vector2 = Vector2(cos(muzzle_angle), sin(muzzle_angle)) * half_w
	var muzzle_end: Vector2 = muzzle_start + Vector2(cos(muzzle_angle), sin(muzzle_angle)) * MUZZLE_LENGTH
	var muzzle_col := MUZZLE_COLOR
	muzzle_col.a = 0.4 + 0.6 * charge
	draw_line(muzzle_start, muzzle_end, muzzle_col, 3.0)
