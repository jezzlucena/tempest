extends Area2D

## Teleport seam — silently repositions the player to a partner seam.
## Used for Penrose stair illusions: the player walks a loop without realizing.

const SEAM_COLOR := Color(0.4, 0.5, 0.7, 0.15)

@export var partner_path: NodePath
@export var seam_height: float = 96.0
@export var seam_width: float = 32.0

var partner: Area2D = null
var _cooldown: float = 0.0
const TELEPORT_COOLDOWN: float = 0.5


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Build collision
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(seam_width, seam_height)
	shape_node.shape = rect
	add_child(shape_node)
	# Resolve partner after tree is ready
	_resolve_partner.call_deferred()


func _resolve_partner() -> void:
	if not partner_path.is_empty():
		partner = get_node(partner_path)


func _process(delta: float) -> void:
	if _cooldown > 0:
		_cooldown -= delta


func _on_body_entered(body: Node2D) -> void:
	if body != GameManager.player:
		return
	if partner == null:
		return
	if _cooldown > 0:
		return

	# Teleport player to partner position, preserving velocity
	var offset := body.global_position - global_position
	body.global_position = partner.global_position + offset
	# Set cooldown on partner to prevent instant back-teleport
	partner._cooldown = TELEPORT_COOLDOWN
	_cooldown = TELEPORT_COOLDOWN


func _draw() -> void:
	# Nearly invisible shimmer — player shouldn't notice the seam
	var rect := Rect2(-seam_width / 2, -seam_height / 2, seam_width, seam_height)
	draw_rect(rect, SEAM_COLOR)
