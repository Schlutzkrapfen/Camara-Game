class_name Creature
extends Node2D

enum BodyType { HEAD, TORSO, LEG }

@export_category("General")
@export var type: BodyType = BodyType.HEAD
@export var stitch_priority: int = 0
@export var randomAttachmentRotationOffset: float = 5
@export var randomAttachmentScaleOffset: float = 0.05
var attached_parts: Array[Creature] = []

@export_category("Gameplay Stats")
var is_alive: bool = false
@export var hp: int = 0
@export var lives: int = 0
@export var speed: float = 0
@export var attack: float = 0

## True once this part has been stitched onto another creature.
var is_stitched: bool = false

var _connection_points: Array[ConnectionPoint] = []


## START
func _ready() -> void:
	_ensure_connection_points()


func _ensure_connection_points() -> void:
	if _connection_points.is_empty():
		for child in get_children():
			if child is ConnectionPoint:
				_connection_points.append(child)


func _find_connection_point_by_id(target_id: int) -> ConnectionPoint:
	if target_id == 0:
		return null
	for point in _connection_points:
		if point.id == target_id:
			return point
	return null


## MISSING GAMEPLAY LOGIC
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass


# --- Stitching -------------------------------------------------------------

## Attaches another Creature to this creature. Returns false if it doesn't fit.
func StitchBodyPart(part: Creature, myExtraPriority: int, otherExtraPriority: int) -> bool:
	if part == self or is_stitched or part.is_stitched:
		return false
	
	# Higher priority becomes the host. Equal priority: the caller is the host.
	if part.stitch_priority + otherExtraPriority > stitch_priority + myExtraPriority:
		print("Swapperoooo")
		return part.StitchBodyPart(self, otherExtraPriority, myExtraPriority)
	
	var pair := _find_matching_points(part)
	if pair.is_empty():
		return false

	var mine: ConnectionPoint = pair[0]
	var theirs: ConnectionPoint = pair[1]

	mine.connected_part = part
	theirs.connected_part = self

	if part.get_parent():
		part.get_parent().remove_child(part)
	add_child(part)
	
	var newScale = mine.attachmentScale + randf_range(-randomAttachmentScaleOffset, randomAttachmentScaleOffset)
	part.scale = Vector2(newScale, newScale)
	part.rotation = deg_to_rad(mine.attachmentRotation + randf_range(-randomAttachmentRotationOffset, randomAttachmentRotationOffset))
	part.position = mine.position - part.transform.basis_xform(theirs.position)
	
	part._on_stitched()
	print("Stitched %s(%s) onto %s(%s)" % [part.name, part.stitch_priority, self.name, self.stitch_priority])
	return true


func _find_matching_points(part: Creature) -> Array:
	if part == self or is_stitched or part.is_stitched:
		return []
	for mine in _connection_points:
		for theirs in part._connection_points:
			if mine.fits(theirs, part.type):
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


# --- Swapping & Reattachment ------------------------------------------------

## Swaps this creature out for a new creature in the chain, matching connection points by ID.
func SwapCreature(new_creature: Creature) -> void:
	if new_creature == null or new_creature == self:
		return

	_ensure_connection_points()
	new_creature._ensure_connection_points()

	var parent_node = get_parent()
	var parent_creature: Creature = parent_node as Creature

	# 1. Handle slot replacement relative to parent creature (if attached to one)
	if parent_creature != null:
		var self_parent_cp: ConnectionPoint = null
		var parent_cp: ConnectionPoint = null

		for cp in _connection_points:
			if cp.connected_part == parent_creature:
				self_parent_cp = cp
				break

		for p_cp in parent_creature._connection_points:
			if p_cp.connected_part == self:
				parent_cp = p_cp
				break

		var new_parent_cp: ConnectionPoint = null
		if self_parent_cp != null:
			new_parent_cp = new_creature._find_connection_point_by_id(self_parent_cp.id)

		if parent_cp != null and new_parent_cp != null:
			parent_node.remove_child(self)
			parent_node.add_child(new_creature)

			self_parent_cp.connected_part = null
			parent_cp.connected_part = new_creature
			new_parent_cp.connected_part = parent_creature

			var newScale = parent_cp.attachmentScale + randf_range(-randomAttachmentScaleOffset, randomAttachmentScaleOffset)
			new_creature.scale = Vector2(newScale, newScale)
			new_creature.rotation = deg_to_rad(parent_cp.attachmentRotation + randf_range(-randomAttachmentRotationOffset, randomAttachmentRotationOffset))
			new_creature.position = parent_cp.position - new_creature.transform.basis_xform(new_parent_cp.position)

			new_creature._on_stitched()
		else:
			OnAttachedFailed(new_creature)
	else:
		# Root creature in scene
		if parent_node != null:
			parent_node.remove_child(self)
			parent_node.add_child(new_creature)
			new_creature.global_transform = self.global_transform
			new_creature.is_stitched = false

	# 2. Reattach child limbs attached to this creature by ConnectionPoint ID
	var children_to_reattach: Array[Dictionary] = []
	for cp in _connection_points:
		if cp.connected_part != null and cp.connected_part != parent_creature:
			var child_limb: Creature = cp.connected_part
			var child_cp: ConnectionPoint = null
			for c_cp in child_limb._connection_points:
				if c_cp.connected_part == self:
					child_cp = c_cp
					break
			children_to_reattach.append({
				"old_cp": cp,
				"cp_id": cp.id,
				"child": child_limb,
				"child_cp": child_cp
			})

	for item in children_to_reattach:
		var old_cp: ConnectionPoint = item["old_cp"]
		var cp_id: int = item["cp_id"]
		var child_limb: Creature = item["child"]
		var child_cp: ConnectionPoint = item["child_cp"]

		old_cp.connected_part = null

		var new_cp: ConnectionPoint = new_creature._find_connection_point_by_id(cp_id)
		if new_cp != null:
			if child_limb.get_parent() == self:
				self.remove_child(child_limb)
			new_creature.add_child(child_limb)

			new_cp.connected_part = child_limb
			if child_cp != null:
				child_cp.connected_part = new_creature

			var newScale = new_cp.attachmentScale + randf_range(-randomAttachmentScaleOffset, randomAttachmentScaleOffset)
			child_limb.scale = Vector2(newScale, newScale)
			child_limb.rotation = deg_to_rad(new_cp.attachmentRotation + randf_range(-randomAttachmentRotationOffset, randomAttachmentRotationOffset))
			child_limb.position = new_cp.position - child_limb.transform.basis_xform(child_cp.position if child_cp else Vector2.ZERO)
		else:
			OnAttachedFailed(child_limb)


func OnAttachedFailed(limb: Creature) -> void:
	print("%s limb failed to reattach" % limb.name)
