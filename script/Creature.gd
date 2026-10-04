class_name Creature
extends Node2D

var is_alive: bool = false
@export var stitch_priority: int = 0
var attached_parts: Array[Creature] = []

## True once this part has been stitched onto another creature.
var is_stitched: bool = false

var _connection_points: Array[ConnectionPoint] = []


## START
func _ready() -> void:
	
	## Get Connection Points
	_connection_points.clear()
	for child in get_children():
		if child is ConnectionPoint:
			_connection_points.append(child)


## MISSING GAMEPLAY LOGIC
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass


# --- Stitching -------------------------------------------------------------

## Attaches another Creature to this creature. Returns false if it doesn't fit.
func StitchBodyPart(part: Creature) -> bool:
	if part == self or is_stitched or part.is_stitched:
		return false
	
	
	# Higher priority becomes the host. Equal priority: the caller is the host.
	if part.stitch_priority > stitch_priority:
		print("Swapperoooo")
		return part.StitchBodyPart(self)
	
	
	var pair := _find_matching_points(part)
	if pair.is_empty():
		return false
	
	
	var mine: ConnectionPoint = pair[0]
	var theirs: ConnectionPoint = pair[1]
	
	mine.connected_part = part
	theirs.connected_part = self
	attached_parts.append(part)
	
	# Reparent and snap so the two sockets sit on top of each other.
	if part.get_parent():
		part.get_parent().remove_child(part)
	add_child(part)
	part.position = mine.position - theirs.position

	part._on_stitched()
	print("Stitched %s(%s) onto %s(%s)" % [part.name, part.stitch_priority, self.name, self.stitch_priority])
	return true


func _find_matching_points(part: Creature) -> Array:
	if part == self or is_stitched or part.is_stitched:
		return []
	for mine in _connection_points:
		for theirs in part._connection_points:
			if mine.fits(theirs):
				return [mine, theirs]
	return []


## Called on the part that just got attached: it becomes inert.
func _on_stitched() -> void:
	is_stitched = true
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	
	for point in _connection_points:
		if point.is_free():
			point.enabled = false
			point.queue_redraw()
