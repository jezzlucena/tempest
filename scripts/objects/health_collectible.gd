extends Area2D

## Health collectible — increases the player's max HP by 1 when collected.
## Each collectible has a unique ID used to track collection across saves.

const CORE_COLOR := Color(0.3, 0.9, 0.5, 0.9)
const RING_COLOR := Color(0.4, 1.0, 0.6, 0.7)
const GLOW_COLOR := Color(0.3, 0.9, 0.5, 0.08)
const SIZE := 12.0

var collectible_id: String = ""
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	# Auto-generate ID from position if not set
	if collectible_id == "":
		collectible_id = "hp_%d_%d" % [int(global_position.x), int(global_position.y)]

	# If already collected in this save, remove immediately
	if GameManager.is_collectible_collected(collectible_id):
		queue_free()
		return

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = SIZE + 4
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	z_index = 3


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body != GameManager.player:
		return
	_collected = true
	set_deferred("monitoring", false)

	# Increase max HP and heal
	var p: CharacterBody2D = GameManager.player
	p.MAX_HP += 1
	p.hp = p.MAX_HP
	p.hp_changed.emit(p.hp)

	# Track collection
	GameManager.collect_item(collectible_id)

	# Collection effect — expand and fade
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(3, 3), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := sin(_time * 3.0) * 0.2 + 0.8
	var bob := sin(_time * 2.0) * 3.0

	# Glow
	draw_circle(Vector2(0, bob), SIZE * 2.0, GLOW_COLOR)

	# Outer ring
	draw_arc(Vector2(0, bob), SIZE, 0, TAU, 32, RING_COLOR * Color(1, 1, 1, pulse), 2.0)

	# Core — plus/cross shape to indicate health
	var s := SIZE * 0.5 * pulse
	# Vertical bar
	draw_rect(Rect2(-s * 0.35, bob - s, s * 0.7, s * 2), CORE_COLOR)
	# Horizontal bar
	draw_rect(Rect2(-s, bob - s * 0.35, s * 2, s * 0.7), CORE_COLOR)
