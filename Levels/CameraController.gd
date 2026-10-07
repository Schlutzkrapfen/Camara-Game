extends Camera2D
class_name CameraController

## Master switch: when true, edge scrolling is disabled and the camera
## smoothly glides to `locked_y`.
@export var locked: bool = false
@export var locked_y: float = 0.0
@export var lock_smoothing: float = 6.0 # higher = snappier return

@export_group("Edge Scrolling")
@export var max_speed: float = 700.0 # pixels/sec at the very screen edge
@export_range(0.02, 0.5) var edge_size: float = 0.15 # fraction of screen height that scrolls
@export var speed_smoothing: float = 10.0 # higher = faster speed changes

@export_group("Limits")
@export var min_y: float = -2000.0
@export var max_y: float = 2000.0

var _velocity: float = 0.0


func _process(delta: float) -> void:
	if locked:
		_velocity = 0.0
		# Frame-rate independent smooth move to the locked position
		global_position.y = lerpf(global_position.y, locked_y, 1.0 - exp(-lock_smoothing * delta))
		return

	var viewport := get_viewport()
	var height := viewport.get_visible_rect().size.y
	var mouse_y := viewport.get_mouse_position().y
	var zone := height * edge_size

	# -1 (top edge) .. 0 (middle) .. +1 (bottom edge)
	var strength := 0.0
	if mouse_y < zone:
		strength = -(1.0 - mouse_y / zone)
	elif mouse_y > height - zone:
		strength = (mouse_y - (height - zone)) / zone
	strength = clampf(strength, -1.0, 1.0)

	# Smooth the speed so starting/stopping isn't abrupt
	var target_speed := strength * max_speed
	_velocity = lerpf(_velocity, target_speed, 1.0 - exp(-speed_smoothing * delta))

	global_position.y = clampf(global_position.y + _velocity * delta, min_y, max_y)
