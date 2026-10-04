extends Node2D

## Scenes whose root uses creature.gd (head, body, leg, ...).
@export var part_scenes: Array[PackedScene] = []
## Area (in this node's local coordinates) where parts are spawned.
@export var spawn_area: Rect2 = Rect2(-1000, -1000, 2000, 2000)
@export var selected_color: Color = Color(1.0, 0.9, 0.3)

var _parts: Array[Creature] = []
var _selected: Creature = null


func _ready() -> void:
	randomize()
	SpawnParts()

## Input Handling
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		OnLeftClick(get_global_mouse_position())
	
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
		SpawnParts()


func SpawnParts() -> void:
	if part_scenes.is_empty():
		push_warning("No part_scenes assigned in the inspector.")
		return
	
	var scene: PackedScene = part_scenes.pick_random()
	var part := scene.instantiate() as Creature
	if part == null:
		push_error("A part scene's root does not use creature.gd.")
		return
	
	part.name = "%s_%d" % [scene.resource_path.get_file().get_basename(), _parts.size()]
	
	add_child(part)
	
	part.position = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	_parts.append(part)


func OnLeftClick(mouse_pos: Vector2) -> void:
	var nearest := _get_nearest_part(mouse_pos)
	if nearest == null:
		return

	# First click: select.
	if _selected == null:
		_select(nearest)
		print("Selected: " + nearest.name)
		return

	# Clicking the selected part again just deselects it.
	if nearest == _selected:
		print("Deselected: " + _selected.name)
		_select(null)
		return

	# Second click: stitch the nearest part onto the selected one.
	var target := _selected
	_select(null)

	if target.StitchBodyPart(nearest, 1, 0):
		if target.is_stitched:
			_parts.erase(target)
		else:
			_parts.erase(nearest)
	else:
		print("%s doesn't fit onto %s" % [nearest.name, target.name])


func _get_nearest_part(pos: Vector2) -> Creature:
	var best: Creature = null
	var best_dist := INF
	for part in _parts:
		if not is_instance_valid(part) or part.is_stitched:
			continue
		var d := part.global_position.distance_squared_to(pos)
		if d < best_dist:
			best_dist = d
			best = part
	return best


func _select(part: Creature) -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.modulate = Color.WHITE
	_selected = part
	if _selected != null:
		_selected.modulate = selected_color


func _draw() -> void:
	draw_rect(spawn_area, Color(1, 1, 1, 0.3), false, 2.0)
