extends Camera2D

## Follows the player and rotates the view to match gravity direction.
## Rotation is set directly each frame — the gravity tween already provides
## smooth interpolation of gravity_angle_radians.


func _ready() -> void:
	make_current()
	# Ensure the camera applies its rotation to the viewport
	ignore_rotation = false


func _process(_delta: float) -> void:
	rotation = -GravityManager.gravity_angle_radians
