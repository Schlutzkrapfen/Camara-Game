@tool
class_name ConnectionPoint
extends Marker2D

enum Direction { UP, DOWN, LEFT, RIGHT }
var directionInxed: int = 0
@export var allowedBodyTypes: Array[Creature.BodyType]

@export var direction: Direction = Direction.UP:
	set(value):
		direction = value
		queue_redraw()
@export var attachmentScale: float = 1 ## Uniscale
@export var attachmentRotation: float = 0:
	
	set(value):
		attachmentRotation = value
		queue_redraw()


## Set to false to disable this socket without removing it.
@export var enabled: bool = true

var connected_part: Creature = null


func is_free() -> bool:
	return enabled and connected_part == null


func fits(other: ConnectionPoint, type: Creature.BodyType) -> bool:
	return is_free() and other.is_free() and type in allowedBodyTypes and direction == _opposite(other.direction)


func get_direction_vector() -> Vector2:
	match direction:
		Direction.UP: return Vector2.UP
		Direction.DOWN: return Vector2.DOWN
		Direction.LEFT: return Vector2.LEFT
		_: return Vector2.RIGHT


static func _opposite(dir: Direction) -> Direction:
	match dir:
		Direction.UP: return Direction.DOWN
		Direction.DOWN: return Direction.UP
		Direction.LEFT: return Direction.RIGHT
		_: return Direction.LEFT

func rotate_around_point(point: Vector2, pivot: Vector2, angle_rad: float) -> Vector2:
	return pivot + (point - pivot).rotated(angle_rad)

# Editor visualisation: a dot plus an arrow showing which way the socket faces.
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	
	var color
	match direction:
		Direction.UP:
			color = Color.LIME
		Direction.RIGHT:
			color = Color.RED
		Direction.DOWN:
			color = Color.AQUA
		Direction.LEFT:
			color = Color.LIGHT_CORAL
	if !enabled: color = Color.GRAY
	
	var tip := get_direction_vector() * 100.0
	draw_circle(Vector2.ZERO, 7.0, color)
	draw_line(Vector2.ZERO, tip, color, 2.0)
	
	draw_line(Vector2.ZERO, tip.rotated(deg_to_rad(attachmentRotation)), color, 1.0)
