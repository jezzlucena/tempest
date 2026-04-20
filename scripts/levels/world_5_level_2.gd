extends Node2D

## W5-2 — The Shifting Halls
##
## Horizontal corridor with three hazard zones, each zone lethal in a
## specific era and safe in another. Era triggers placed before every
## hazard author the player's safe era.
##
## Hazard layout (tile x ranges):
##   5..7   — spikes in Present, safe in Past      (Past trigger at x=3)
##   12..14 — spikes in Past,    safe in Future    (Future trigger at x=10)
##   20..22 — spikes in Future,  safe in Present   (Present trigger at x=18)
## Exit at x=28.

@onready var tilemap_past: TileMapLayer = $TileMapPast
@onready var tilemap_present: TileMapLayer = $TileMapPresent
@onready var tilemap_future: TileMapLayer = $TileMapFuture
@onready var player: CharacterBody2D = $Player

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const TRIGGER_SCENE := preload("res://scenes/objects/era_trigger.tscn")
const SPIKE_SCENE := preload("res://scenes/objects/hazard_spike.tscn")

const ERA_COLOR_PAST := Color(0.45, 0.38, 0.25)
const ERA_COLOR_PRESENT := Color(0.28, 0.28, 0.33)
const ERA_COLOR_FUTURE := Color(0.2, 0.25, 0.42)

const FLOOR_ROW: int = 14
const CEILING_ROW: int = 8
const CORRIDOR_RIGHT_WALL: int = 31


func _ready() -> void:
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()

	tilemap_past.tile_set = LevelBuilder.create_tileset(ERA_COLOR_PAST)
	tilemap_present.tile_set = LevelBuilder.create_tileset(ERA_COLOR_PRESENT)
	tilemap_future.tile_set = LevelBuilder.create_tileset(ERA_COLOR_FUTURE)

	LevelStateManager.clear_layers()
	LevelStateManager.register_era_layer(TimeManager.Era.PAST, tilemap_past)
	LevelStateManager.register_era_layer(TimeManager.Era.PRESENT, tilemap_present)
	LevelStateManager.register_era_layer(TimeManager.Era.FUTURE, tilemap_future)

	TimeManager.current_era = TimeManager.Era.PRESENT
	LevelStateManager.swap_era(TimeManager.Era.PRESENT)

	_build_common()
	_place_spikes()
	_place_triggers()
	_place_exit()
	_add_kill_zone()
	add_child(HUD_SCENE.instantiate())


func _all_tilemaps() -> Array:
	return [tilemap_past, tilemap_present, tilemap_future]


func _build_common() -> void:
	for tm in _all_tilemaps():
		LevelBuilder.build_hline(tm, FLOOR_ROW, 0, 30)
		LevelBuilder.build_hline(tm, CEILING_ROW, 0, 30)
		LevelBuilder.build_vline(tm, -1, CEILING_ROW, FLOOR_ROW)
		LevelBuilder.build_vline(tm, CORRIDOR_RIGHT_WALL, CEILING_ROW, FLOOR_ROW)


## Era-locked spike clusters. Each entry is [tile_x, count, active_era].
const SPIKE_DATA: Array = [
	[5, 3, int(TimeManager.Era.PRESENT)],  # hazard in Present; Past = safe
	[12, 3, int(TimeManager.Era.PAST)],    # hazard in Past; Future = safe
	[20, 3, int(TimeManager.Era.FUTURE)],  # hazard in Future; Present = safe
]


func _place_spikes() -> void:
	for data in SPIKE_DATA:
		var spike := SPIKE_SCENE.instantiate()
		spike.position = Vector2(int(data[0]) * 32 + 16, FLOOR_ROW * 32)
		spike.spike_count = int(data[1])
		spike.active_era = int(data[2])
		add_child(spike)


func _place_triggers() -> void:
	# Past trigger before the Present-hazard zone.
	_add_trigger(Vector2(3 * 32 + 16, 13 * 32), int(TimeManager.Era.PAST))
	# Future trigger before the Past-hazard zone.
	_add_trigger(Vector2(10 * 32 + 16, 13 * 32), int(TimeManager.Era.FUTURE))
	# Present trigger before the Future-hazard zone.
	_add_trigger(Vector2(18 * 32 + 16, 13 * 32), int(TimeManager.Era.PRESENT))


func _add_trigger(pos: Vector2, target_era: int) -> void:
	var trigger := TRIGGER_SCENE.instantiate()
	trigger.position = pos
	trigger.target_era = target_era
	trigger.size = Vector2(32, 192)
	add_child(trigger)


func _place_exit() -> void:
	var exit_portal := EXIT_SCENE.instantiate()
	exit_portal.position = Vector2(28 * 32 + 16, FLOOR_ROW * 32 - 40)
	add_child(exit_portal)


func _add_kill_zone() -> void:
	LevelBuilder.add_kill_zones(
		self, player, -3, CORRIDOR_RIGHT_WALL + 2, CEILING_ROW - 4, FLOOR_ROW + 4,
	)
