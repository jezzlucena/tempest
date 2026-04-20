extends Area2D

## Infinity Shard — one of three hidden fragments of the Infinity Visor.
## Each shard is one era's echo (Past / Present / Future). Collecting all
## three assembles the visor in the player's persistent inventory.
##
## Visual: a bright one-third slice of a trefoil knot, tinted to its era.

@export var shard_id: String = GameManager.ITEM_SHARD_PAST
@export var era_tint: Color = Color(1.0, 0.8, 0.4, 1.0)
## Era in which this shard is real. -1 = any era (useful for W0-L1 before
## era layers were retrofitted, but the retrofit made it era-locked).
@export var required_era: int = -1

const GLOW_COLOR := Color(1.0, 0.9, 0.7, 0.12)
const OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.85)
const SIZE := 16.0

var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	# Already picked up in a prior session — don't re-spawn.
	if GameManager.has_persistent_item(shard_id):
		queue_free()
		return

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = SIZE + 6.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	z_index = 4

	if required_era >= 0:
		TimeManager.era_changed.connect(_on_era_changed)
		_refresh_era_state()


func _on_era_changed(_era: int) -> void:
	_refresh_era_state()


func _refresh_era_state() -> void:
	if _collected or required_era < 0:
		return
	var matches: bool = int(TimeManager.current_era) == required_era
	visible = matches
	set_deferred("monitoring", matches)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body != GameManager.player:
		return
	_collected = true
	set_deferred("monitoring", false)

	GameManager.collect_persistent_item(shard_id)

	# Collection flourish — expand and fade.
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(3.5, 3.5), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = sin(_time * 3.2) * 0.25 + 0.75
	var bob: float = sin(_time * 2.1) * 2.5
	var spin: float = _time * 1.1

	# Soft halo.
	draw_circle(Vector2(0, bob), SIZE * 2.2, GLOW_COLOR * Color(1, 1, 1, pulse))

	# Trefoil-knot slice — a 3-lobed rose traced with a line, tinted by era.
	# The "slice" is the full parametric curve scaled down: this shard is
	# visually one-third of the full visor but reads as a knot fragment.
	var seg_count: int = 60
	var prev: Vector2 = Vector2.ZERO
	var col: Color = era_tint
	col.a = 0.9 * pulse
	for i in range(seg_count + 1):
		var t: float = (float(i) / seg_count) * TAU
		var r: float = SIZE * (0.85 + 0.25 * cos(3.0 * t))
		var pt: Vector2 = Vector2(cos(t + spin), sin(t + spin)) * r + Vector2(0, bob)
		if i > 0:
			draw_line(prev, pt, col, 2.2)
		prev = pt

	# Central dot to anchor the eye.
	draw_circle(Vector2(0, bob), 2.5 * pulse, OUTLINE_COLOR)
