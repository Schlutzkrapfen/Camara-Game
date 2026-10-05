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

	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_MIDDLE \
			and event.pressed:
		OnMiddleClick(get_global_mouse_position())


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


func OnMiddleClick(mouse_pos: Vector2) -> void:
	var target := _get_nearest_creature_any(mouse_pos)
	if target == null:
		return

	if part_scenes.is_empty():
		push_warning("No part_scenes available to swap with.")
		return

	var scene: PackedScene = part_scenes.pick_random()
	var new_part := scene.instantiate() as Creature
	if new_part == null:
		return

	new_part.name = "%s_replacement_%d" % [scene.resource_path.get_file().get_basename(), randi() % 1000]

	if _selected == target:
		_select(null)

	# Swap out the target part with the newly instantiated part
	target.SwapCreature(new_part)

	# If the target was a standalone root part in _parts, track the new part instead
	if target in _parts:
		var idx := _parts.find(target)
		_parts[idx] = new_part

	print("Swapped out %s for %s" % [target.name, new_part.name])
	target.queue_free()


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


## Searches for ANY creature node in the hierarchy (including stitched limbs)
func _get_nearest_creature_any(pos: Vector2) -> Creature:
	var all_creatures := _get_all_creatures(self)
	var best: Creature = null
	var best_dist := INF
	for creature in all_creatures:
		if not is_instance_valid(creature):
			continue
		var d := creature.global_position.distance_squared_to(pos)
		if d < best_dist:
			best_dist = d
			best = creature
	return best


func _get_all_creatures(node: Node) -> Array[Creature]:
	var result: Array[Creature] = []
	if node is Creature and is_instance_valid(node):
		result.append(node)
	for child in node.get_children():
		result.append_array(_get_all_creatures(child))
	return result


func _select(part: Creature) -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.modulate = Color.WHITE
	_selected = part
	if _selected != null:
		_selected.modulate = selected_color


func _draw() -> void:
	draw_rect(spawn_area, Color(1, 1, 1, 0.3), false, 2.0)
