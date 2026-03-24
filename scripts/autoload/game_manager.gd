extends Node

## Manages scene transitions, checkpoints, respawn, and save state.

const LEVEL_SCENES := [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]

signal player_respawned
signal checkpoint_activated

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SAVE_PATH := "user://save.json"

var current_checkpoint_position: Vector2 = Vector2.ZERO
var current_level_index: int = 0
var player: CharacterBody2D = null
var _carry_hp: int = -1
var _carry_max_hp: int = -1
var _carry_checkpoint: Vector2 = Vector2.ZERO
var _has_carry_checkpoint: bool = false
var _collected_items: Array = []


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


func respawn_player() -> void:
	if player == null:
		return
	player.global_position = current_checkpoint_position
	player.velocity = Vector2.ZERO
	player.reset_hp()
	GravityManager.snap_to_nearest()
	player_respawned.emit()


func go_to_next_level() -> void:
	_save_player_hp()
	current_level_index += 1
	if current_level_index >= LEVEL_SCENES.size():
		_show_victory()
		return
	_save_game()
	_transition_to_scene(LEVEL_SCENES[current_level_index])


func _save_player_hp() -> void:
	if player:
		_carry_max_hp = player.MAX_HP
		_carry_hp = player.hp


func go_to_level(index: int) -> void:
	current_level_index = index
	_carry_hp = -1
	_carry_max_hp = -1
	_collected_items = []
	_transition_to_scene(LEVEL_SCENES[index])


func continue_game() -> void:
	var save := _load_save()
	if save.is_empty():
		return
	current_level_index = int(save.get("level", 0))
	_carry_max_hp = int(save.get("max_hp", 3))
	_carry_hp = int(save.get("hp", _carry_max_hp))
	_collected_items = save.get("collected_items", [])
	if save.has("checkpoint_x") and save.has("checkpoint_y"):
		_carry_checkpoint = Vector2(float(save["checkpoint_x"]), float(save["checkpoint_y"]))
		_has_carry_checkpoint = true
	_transition_to_scene(LEVEL_SCENES[current_level_index])


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_menu") and player != null:
		go_to_menu()


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
		"level": current_level_index,
		"max_hp": player.MAX_HP if player else 3,
		"hp": player.hp if player else 3,
		"checkpoint_x": current_checkpoint_position.x,
		"checkpoint_y": current_checkpoint_position.y,
		"collected_items": _collected_items,
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
