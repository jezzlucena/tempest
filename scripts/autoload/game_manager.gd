extends Node

## Manages scene transitions, checkpoints, respawn, and save state.

## Worlds are arrays of level scene paths. Each world ends in a boss at index 2.
## See WORLDS.md for the design.
const WORLDS := [
	[   # World 0 — The Chronolith Arc
		"res://scenes/levels/level_1.tscn",
		"res://scenes/levels/level_2.tscn",
		"res://scenes/levels/level_3.tscn",
	],
	[   # World 1 — The Still Plaza
		"res://scenes/levels/world_1_level_1.tscn",
		"res://scenes/levels/world_1_level_2.tscn",
		"res://scenes/levels/world_1_level_3.tscn",
	],
	[   # World 2 — The Vertical Well
		"res://scenes/levels/world_2_level_1.tscn",
		"res://scenes/levels/world_2_level_2.tscn",
		"res://scenes/levels/world_2_level_3.tscn",
	],
	[   # World 3 — The Inverted Cloister
		"res://scenes/levels/world_3_level_1.tscn",
		"res://scenes/levels/world_3_level_2.tscn",
		"res://scenes/levels/world_3_level_3.tscn",
	],
	[   # World 4 — The Acceleratorium
		"res://scenes/levels/world_4_level_1.tscn",
		"res://scenes/levels/world_4_level_2.tscn",
		"res://scenes/levels/world_4_level_3.tscn",
	],
	[   # World 5 — The Fractured Archive
		"res://scenes/levels/world_5_level_1.tscn",
		"res://scenes/levels/world_5_level_2.tscn",
		"res://scenes/levels/world_5_level_3.tscn",
	],
]

## Ability keys. Persisted to save. Gated by *_manager.gd and player states.
const ABILITY_JUMP := "jump"
const ABILITY_SIDEWAYS := "sideways"
const ABILITY_WALL_JUMP := "wall_jump"
const ABILITY_GRAVITY := "gravity"
const ABILITY_DILATION := "dilation"
const ABILITY_ERA_SHIFT := "era_shift"

## Persistent item IDs — survive `advance_past_chronolith` and any world
## reset. Used for the Infinity Visor shard collection and assembled state.
const ITEM_SHARD_PAST := "shard_past"
const ITEM_SHARD_PRESENT := "shard_present"
const ITEM_SHARD_FUTURE := "shard_future"
const ALL_SHARDS: Array = [ITEM_SHARD_PAST, ITEM_SHARD_PRESENT, ITEM_SHARD_FUTURE]

signal player_respawned
signal checkpoint_activated
signal abilities_changed
signal persistent_items_changed
signal visor_toggled(active: bool)

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SAVE_PATH := "user://save.json"

var current_checkpoint_position: Vector2 = Vector2.ZERO
var current_world_index: int = 0
var current_level_index: int = 0
var player: CharacterBody2D = null
var _carry_hp: int = -1
var _carry_max_hp: int = -1
var _carry_checkpoint: Vector2 = Vector2.ZERO
var _has_carry_checkpoint: bool = false
var _collected_items: Array = []
## Persistent items (shards, visor state) — never cleared by chronolith
## defeat or world reset. Cleared only on final victory (save-file delete).
var _persistent_items: Array = []
## Runtime state for whether the Infinity Visor is currently worn. Only
## togglable once all three shards are in _persistent_items. Saved.
var visor_active: bool = false
var abilities: Dictionary = _all_abilities_unlocked()


static func _all_abilities_unlocked() -> Dictionary:
	return {
		ABILITY_JUMP: true,
		ABILITY_SIDEWAYS: true,
		ABILITY_WALL_JUMP: true,
		ABILITY_GRAVITY: true,
		ABILITY_DILATION: true,
		ABILITY_ERA_SHIFT: true,
	}


static func _jump_only_abilities() -> Dictionary:
	return {
		ABILITY_JUMP: true,
		ABILITY_SIDEWAYS: false,
		ABILITY_WALL_JUMP: false,
		ABILITY_GRAVITY: false,
		ABILITY_DILATION: false,
		ABILITY_ERA_SHIFT: false,
	}


## Abilities the player should hold when first entering world `world_index`,
## before defeating that world's boss. World 0 retains the full kit (the
## prototype). Each subsequent world cumulatively includes the abilities
## returned by prior-world bosses, mirroring the WORLDS.md recovery order.
static func _default_abilities_for_world(world_index: int) -> Dictionary:
	if world_index <= 0:
		return _all_abilities_unlocked()
	var result: Dictionary = _jump_only_abilities()
	var boss_grants: Array = [
		ABILITY_SIDEWAYS,   # W1 boss
		ABILITY_WALL_JUMP,  # W2 boss
		ABILITY_GRAVITY,    # W3 boss
		ABILITY_DILATION,   # W4 boss
		ABILITY_ERA_SHIFT,  # W5 boss
	]
	var grants_available: int = min(world_index - 1, boss_grants.size())
	for i in range(grants_available):
		result[boss_grants[i]] = true
	return result


func has_ability(key: String) -> bool:
	return abilities.get(key, false)


func set_ability(key: String, value: bool) -> void:
	abilities[key] = value
	abilities_changed.emit()
	_save_game()


## Set abilities appropriate for entering the given world (before any boss wins).
## World 0: full kit. World N (>=1): cumulative — jump plus every ability
## granted by the prior (N-1) worlds' bosses.
func set_default_abilities_for_world(world_index: int) -> void:
	abilities = _default_abilities_for_world(world_index)
	abilities_changed.emit()


func register_player(p: CharacterBody2D) -> void:
	player = p
	current_checkpoint_position = p.global_position
	# Restore HP from previous level or save
	if _carry_max_hp > 0:
		p.MAX_HP = _carry_max_hp
		p.hp = _carry_hp
		p.hp_changed.emit(p.hp)
		_carry_hp = -1
		_carry_max_hp = -1
	# Teleport to saved checkpoint position
	if _has_carry_checkpoint:
		p.global_position = _carry_checkpoint
		current_checkpoint_position = _carry_checkpoint
		_has_carry_checkpoint = false


func set_checkpoint(pos: Vector2) -> void:
	current_checkpoint_position = pos
	checkpoint_activated.emit()
	_save_game()


## ── Persistent items (Infinity Visor shards etc.) ───────────────────────

func collect_persistent_item(item_id: String) -> void:
	if item_id in _persistent_items:
		return
	_persistent_items.append(item_id)
	persistent_items_changed.emit()
	_save_game()


func has_persistent_item(item_id: String) -> bool:
	return item_id in _persistent_items


func has_all_visor_shards() -> bool:
	for shard in ALL_SHARDS:
		if shard not in _persistent_items:
			return false
	return true


func set_visor_active(value: bool) -> void:
	if value and not has_all_visor_shards():
		return
	if visor_active == value:
		return
	visor_active = value
	visor_toggled.emit(visor_active)
	_save_game()


func toggle_visor() -> void:
	if not has_all_visor_shards():
		return
	set_visor_active(not visor_active)


func respawn_player() -> void:
	if player == null:
		return
	player.global_position = current_checkpoint_position
	player.velocity = Vector2.ZERO
	player.reset_hp()
	# Respawn = fresh start. Snap nearest handles any in-progress rotation
	# tween, then force angle back to 0 so a death during a forced flip
	# (W3-2 trigger, W3-3 boss) doesn't leave the player in rotated gravity.
	GravityManager.snap_to_nearest()
	GravityManager.gravity_angle = 0.0
	GravityManager._update_vector()
	# Same logic for era: a mid-shift death in W5 should reset to Present
	# so the player's checkpoint returns to a clean baseline.
	TimeManager.current_era = TimeManager.Era.PRESENT
	LevelStateManager.swap_era(int(TimeManager.Era.PRESENT))
	player_respawned.emit()


func go_to_next_level() -> void:
	_save_player_hp()
	current_level_index += 1
	var world_levels: Array = WORLDS[current_world_index]
	if current_level_index >= world_levels.size():
		current_world_index += 1
		current_level_index = 0
		if current_world_index >= WORLDS.size():
			# The W5 boss closes the ability-recovery arc — loop back to
			# W0-L1 without showing a completion screen. Abilities stay
			# as-is (the full kit just earned), regular collectibles reset
			# for a fresh W0 pass, and shard / visor state is preserved
			# so the player can pursue the true ending from here.
			_loop_back_to_world_zero()
			return
		set_default_abilities_for_world(current_world_index)
	_save_game()
	_transition_to_scene(WORLDS[current_world_index][current_level_index])


## Wrap from W5-L3 → W0-L1. Unlike `_show_victory`, this doesn't delete
## the save or drop the player into a menu — the loop closes in-world.
func _loop_back_to_world_zero() -> void:
	current_world_index = 0
	current_level_index = 0
	_carry_hp = -1
	_carry_max_hp = -1
	_collected_items = []
	current_checkpoint_position = Vector2.ZERO
	_has_carry_checkpoint = false
	_save_game()
	_transition_to_scene(WORLDS[current_world_index][current_level_index])


## Called by the Chronolith level when the boss is defeated WITHOUT the
## Infinity Visor — the shockwave strips every ability and drops the
## player into W1-L1.
func advance_past_chronolith() -> void:
	abilities = _jump_only_abilities()
	abilities_changed.emit()
	current_world_index = 1
	current_level_index = 0
	_carry_hp = -1
	_carry_max_hp = -1
	_collected_items = []
	current_checkpoint_position = Vector2.ZERO
	_has_carry_checkpoint = false
	_save_game()
	_transition_to_scene(WORLDS[current_world_index][current_level_index])


## Called by the Chronolith level when the boss is defeated via the
## Infinity Visor's true core. Loads the true-ending scene and wipes the
## save file + in-memory persistent state so a subsequent "Play Again"
## actually starts fresh.
func advance_to_true_ending() -> void:
	player = null
	_persistent_items = []
	visor_active = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_transition_to_scene("res://scenes/ui/true_ending.tscn")


func _save_player_hp() -> void:
	if player:
		_carry_max_hp = player.MAX_HP
		_carry_hp = player.hp


func go_to_level(world_index: int, level_index: int) -> void:
	current_world_index = world_index
	current_level_index = level_index
	_carry_hp = -1
	_carry_max_hp = -1
	_collected_items = []
	set_default_abilities_for_world(world_index)
	_transition_to_scene(WORLDS[world_index][level_index])


func continue_game() -> void:
	var save := _load_save()
	if save.is_empty():
		return
	current_world_index = int(save.get("world", 0))
	current_level_index = int(save.get("level", 0))
	# Clamp to valid range in case save is from an older structure
	current_world_index = clampi(current_world_index, 0, WORLDS.size() - 1)
	current_level_index = clampi(current_level_index, 0, WORLDS[current_world_index].size() - 1)
	_carry_max_hp = int(save.get("max_hp", 3))
	_carry_hp = int(save.get("hp", _carry_max_hp))
	_collected_items = save.get("collected_items", [])
	_persistent_items = save.get("persistent_items", [])
	visor_active = bool(save.get("visor_active", false))
	# Guard: can't be worn without all three shards.
	if visor_active and not has_all_visor_shards():
		visor_active = false
	if save.has("abilities") and save["abilities"] is Dictionary:
		var saved_abilities: Dictionary = save["abilities"]
		# Merge saved abilities onto the default, so new keys added in a later
		# version fall back to their default value.
		var merged := _all_abilities_unlocked()
		for key in merged.keys():
			if saved_abilities.has(key):
				merged[key] = bool(saved_abilities[key])
		abilities = merged
	else:
		set_default_abilities_for_world(current_world_index)
	if save.has("checkpoint_x") and save.has("checkpoint_y"):
		_carry_checkpoint = Vector2(float(save["checkpoint_x"]), float(save["checkpoint_y"]))
		_has_carry_checkpoint = true
	_transition_to_scene(WORLDS[current_world_index][current_level_index])


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_menu") and player != null:
		go_to_menu()
	# Visor toggle only has effect when all three shards are in the player's
	# persistent inventory. Otherwise the press is a no-op.
	if Input.is_action_just_pressed("visor_toggle") and has_all_visor_shards():
		toggle_visor()


func go_to_menu() -> void:
	player = null
	GravityManager.snap_to_nearest()
	_transition_to_scene(MAIN_MENU_SCENE)


func _transition_to_scene(scene_path: String) -> void:
	player = null
	LevelStateManager.clear_layers()
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)

	var tween := canvas.create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.5)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(scene_path)
	)
	tween.tween_interval(0.3)
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)


func _show_victory() -> void:
	player = null
	_persistent_items = []
	visor_active = false
	# Clear save on completion
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_transition_to_scene("res://scenes/ui/completion.tscn")


## ── Save / Load ─────────────────────────────────────────────────────────────

func collect_item(item_id: String) -> void:
	if item_id not in _collected_items:
		_collected_items.append(item_id)
		_save_game()


func is_collectible_collected(item_id: String) -> bool:
	return item_id in _collected_items


func _save_game() -> void:
	var save_data := {
		"world": current_world_index,
		"level": current_level_index,
		"persistent_items": _persistent_items,
		"visor_active": visor_active,
		"max_hp": player.MAX_HP if player else 3,
		"hp": player.hp if player else 3,
		"checkpoint_x": current_checkpoint_position.x,
		"checkpoint_y": current_checkpoint_position.y,
		"collected_items": _collected_items,
		"abilities": abilities,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()


func _load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var data = json.data
	if data is Dictionary:
		return data
	return {}
