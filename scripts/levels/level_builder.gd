extends RefCounted
class_name LevelBuilder

## Utility for programmatically building tile-based level geometry.
## Creates a TileSet with physics and places tiles on a TileMapLayer.

const TILE_SIZE: int = 32
const TILE_SOURCE_ID: int = 0

## Color palette for era-specific tiles
static var ERA_COLORS: Dictionary = {
	"present": Color(0.28, 0.28, 0.33, 1.0),
	"present_accent": Color(0.35, 0.35, 0.4, 1.0),
	"past": Color(0.45, 0.38, 0.25, 1.0),
	"future": Color(0.2, 0.25, 0.42, 1.0),
}


## Create a TileSet with a single colored tile + physics collision
static func create_tileset(color: Color = Color(0.28, 0.28, 0.33, 1.0)) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Add physics layer
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 1)

	# Create a small colored texture for the tile
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# Add subtle edge darkening for visual depth
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			if x == 0 or y == 0 or x == TILE_SIZE - 1 or y == TILE_SIZE - 1:
				img.set_pixel(x, y, color.darkened(0.3))
	var texture := ImageTexture.create_from_image(img)

	# Create atlas source
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_source(source, TILE_SOURCE_ID)

	# Create tile at atlas coords (0,0)
	source.create_tile(Vector2i(0, 0))

	# Set up physics polygon for this tile (full square)
	var physics_polygon := PackedVector2Array([
		Vector2(-TILE_SIZE / 2.0, -TILE_SIZE / 2.0),
		Vector2(TILE_SIZE / 2.0, -TILE_SIZE / 2.0),
		Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0),
		Vector2(-TILE_SIZE / 2.0, TILE_SIZE / 2.0),
	])
	source.get_tile_data(Vector2i(0, 0), 0).add_collision_polygon(0)
	source.get_tile_data(Vector2i(0, 0), 0).set_collision_polygon_points(0, 0, physics_polygon)

	return tileset


## Fill a rectangular region with tiles
static func build_rect(tilemap: TileMapLayer, from: Vector2i, to: Vector2i) -> void:
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			tilemap.set_cell(Vector2i(x, y), TILE_SOURCE_ID, Vector2i(0, 0))


## Build a horizontal line of tiles
static func build_hline(tilemap: TileMapLayer, y: int, from_x: int, to_x: int) -> void:
	for x in range(from_x, to_x + 1):
		tilemap.set_cell(Vector2i(x, y), TILE_SOURCE_ID, Vector2i(0, 0))


## Build a vertical line of tiles
static func build_vline(tilemap: TileMapLayer, x: int, from_y: int, to_y: int) -> void:
	for y in range(from_y, to_y + 1):
		tilemap.set_cell(Vector2i(x, y), TILE_SOURCE_ID, Vector2i(0, 0))


## Clear a rectangular region
static func clear_rect(tilemap: TileMapLayer, from: Vector2i, to: Vector2i) -> void:
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			tilemap.erase_cell(Vector2i(x, y))


## Place a single tile
static func place_tile(tilemap: TileMapLayer, pos: Vector2i) -> void:
	tilemap.set_cell(pos, TILE_SOURCE_ID, Vector2i(0, 0))


## Convert tile coordinates to world position (center of tile)
static func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0, tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0)


## Convert world position to tile coordinates
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x) / TILE_SIZE, int(world_pos.y) / TILE_SIZE)


## Create kill zone boundaries on all 4 sides of the level.
## Bounds are in tile coordinates. margin is extra tiles beyond the bounds.
static func add_kill_zones(parent: Node2D, player: CharacterBody2D,
		left_tile: int, right_tile: int, top_tile: int, bottom_tile: int,
		margin_tiles: int = 10) -> void:
	var m: float = margin_tiles * TILE_SIZE
	var left: float = left_tile * TILE_SIZE - m
	var right: float = (right_tile + 1) * TILE_SIZE + m
	var top: float = top_tile * TILE_SIZE - m
	var bottom: float = (bottom_tile + 1) * TILE_SIZE + m
	var cx: float = (left + right) / 2.0
	var cy: float = (top + bottom) / 2.0
	var width: float = right - left
	var height: float = bottom - top
	var thickness: float = 100.0

	# Bottom
	_add_kill_wall(parent, player, Vector2(cx, bottom + thickness / 2.0), Vector2(width + 200, thickness))
	# Top
	_add_kill_wall(parent, player, Vector2(cx, top - thickness / 2.0), Vector2(width + 200, thickness))
	# Left
	_add_kill_wall(parent, player, Vector2(left - thickness / 2.0, cy), Vector2(thickness, height + 200))
	# Right
	_add_kill_wall(parent, player, Vector2(right + thickness / 2.0, cy), Vector2(thickness, height + 200))


static func _add_kill_wall(parent: Node2D, player: CharacterBody2D,
		pos: Vector2, size: Vector2) -> void:
	var zone := Area2D.new()
	zone.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	zone.add_child(shape)
	zone.body_entered.connect(func(body: Node2D) -> void:
		if body == player:
			player.take_damage(player.MAX_HP)
	)
	parent.add_child(zone)
