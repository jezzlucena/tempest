extends Node

## Manages player states. Each child node is a state.
## Delegates _physics_process and _unhandled_input to the active state.

var current_state: Node = null
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child.has_method("enter"):
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.player = get_parent()
	# Start in idle
	transition_to("idle")


func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("physics_process"):
		current_state.physics_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("handle_input"):
		current_state.handle_input(event)


func transition_to(state_name: String) -> void:
	var new_state = states.get(state_name)
	if new_state == null:
		push_warning("State not found: " + state_name)
		return
	if current_state == new_state:
		return
	if current_state and current_state.has_method("exit"):
		current_state.exit()
	current_state = new_state
	current_state.enter()
