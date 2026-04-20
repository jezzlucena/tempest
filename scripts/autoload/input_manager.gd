extends Node

## Registers all input actions programmatically at startup.
## This avoids hand-authoring the verbose [input] section in project.godot.

func _ready() -> void:
	_register_action("move_left", KEY_A)
	_register_action("move_left", KEY_LEFT)
	_register_action("move_right", KEY_D)
	_register_action("move_right", KEY_RIGHT)
	_register_action("jump", KEY_SPACE)
	_register_action("jump", KEY_UP)
	_register_action("jump", KEY_W)
	_register_action("gravity_left", KEY_Q)
	_register_action("gravity_right", KEY_E)
	_register_action("era_shift_earlier", KEY_LEFT, KEY_MASK_SHIFT)
	_register_action("era_shift_later", KEY_RIGHT, KEY_MASK_SHIFT)
	_register_mouse_action("dilation_cast", MOUSE_BUTTON_RIGHT)
	_register_action("ui_menu", KEY_ESCAPE)
	_register_action("visor_toggle", KEY_V)


func _register_action(action_name: String, key: Key, modifiers: int = 0) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.keycode = key
	if modifiers & KEY_MASK_SHIFT:
		event.shift_pressed = true
	InputMap.action_add_event(action_name, event)


func _register_mouse_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)
