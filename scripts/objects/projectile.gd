extends Area2D

## Projectile fired by the boss. Affected by dilation. Damages player on contact.

const PROJECTILE_COLOR := Color(0.9, 0.4, 0.2, 0.9)
const SLOWED_COLOR := Color(0.4, 0.5, 0.9, 0.8)
const TRAIL_COLOR := Color(0.9, 0.3, 0.1, 0.3)
const RADIUS := 8.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var _lifetime: float = 0.0
const MAX_LIFETIME: float = 3.0

## Optional: track toward the player
var tracking: bool = false
var tracking_strength: float = 1.5


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var scaled_delta: float = TimeManager.get_scaled_delta(self, delta)
	_lifetime += scaled_delta

	if _lifetime >= MAX_LIFETIME:
		queue_free()
		return

	# Optional tracking
	if tracking and GameManager.player:
		var to_player := (GameManager.player.global_position - global_position).normalized()
		direction = direction.lerp(to_player, tracking_strength * scaled_delta).normalized()

	global_position += direction * speed * scaled_delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		body.take_damage(1)
		queue_free()


func _draw() -> void:
	var is_slowed := TimeManager.is_position_dilated(global_position)
	var color := SLOWED_COLOR if is_slowed else PROJECTILE_COLOR
	draw_circle(Vector2.ZERO, RADIUS, color)
	# Trail
	var trail_dir := -direction * 16
	var trail_col := TRAIL_COLOR
	trail_col.a *= 0.5 if is_slowed else 1.0
	draw_line(Vector2.ZERO, trail_dir, trail_col, 3.0)
	draw_line(Vector2.ZERO, trail_dir * 0.6, trail_col, 2.0)
