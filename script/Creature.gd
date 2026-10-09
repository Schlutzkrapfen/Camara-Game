class_name Creature
extends Node2D

enum BodyType { HEAD, TORSO, LEG, SPIKE }

@export_category("General")
@export var type: BodyType = BodyType.HEAD
@export var stitch_priority: int = 0
@export var randomAttachmentRotationOffset: float = 5
@export var randomAttachmentScaleOffset: float = 0.05
@export var upgrade: PackedScene
var attached_parts: Array[Creature] = []

@export_category("Gameplay Stats")
var is_alive: bool = false:
	set(value):
		if is_alive == value:
			return # stops infinite loop
		is_alive = value
		if is_alive:
			if hp <= 0 and not is_stitched:
				Die()
				return
			self.add_to_group("units")
		else:
			self.remove_from_group("units")

@export var hp: int = 0
@export var lives: int = 0
@export var speed: float = 0
@export var attackDamage: int = 0
@export var attackCooldown: float = 0.1
@export var attackRange: float = 0
@export_category("Global Stats")
@export var minSelfdestructTime: float = 4
@export var maxSelfdestructTime: float = 6
var target: Node2D
var timeUntilSelfDestruct: float
var curAttackCooldown: float = 0.0
var sprite: Sprite2D

## True once this part has been stitched onto another creature.
var is_stitched: bool = false

var _connection_points: Array[ConnectionPoint] = []


# --- Connection Logic -------------------------------------------------------------

func _ready() -> void:
	_ensure_connection_points()
	timeUntilSelfDestruct = randf_range(minSelfdestructTime, maxSelfdestructTime)
	sprite = find_children("*", "Sprite2D")[0]


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


# --- Gameplay -------------------------------------------------------------

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	## Confirm target
	#if target == null:
	#	target = SearchForTarget()
	#	timeUntilSelfDestruct -= delta
	#	if timeUntilSelfDestruct <= 0:
	#		Die()
	#	return
	
	curAttackCooldown -= delta
	
	
	## Attack if possible
	if curAttackCooldown <= 0:
		var someoneInRange: bool = false
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_squared_to(enemy.global_position) <= attackRange * attackRange:
				someoneInRange = true
				enemy.TakeDamage(attackDamage)
		if someoneInRange:
			if attackCooldown < 0.1: # Hard-Coded minimum
				curAttackCooldown = 0.1
			else:
				curAttackCooldown = attackCooldown
			SpawnAttackVisual()
		else:
			## Move towards target
			if target != null:
				position += (target.position - self.position).normalized() * delta * speed
			else:
				target = SearchForTarget()


func SearchForTarget() -> Enemy:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	return enemies.pick_random() as Enemy

func SpawnAttackVisual() -> void:
	var fx := AttackEffect.new()
	fx.radius = attackRange
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position

func TakeDamage(damage: int) -> void:
	hp -= damage
	print(hp)
	DamageFlash()
	print(hp)
	if hp <= 0:
		Die()

func DamageFlash() -> void:
	var tween = create_tween()
	sprite.modulate = Color(2.5, 0.3, 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func Die() -> void:
	self.visible = false
	self.process_mode = Node.PROCESS_MODE_DISABLED
	is_alive = false
	self.position = Vector2(100000,100000)
	self.remove_from_group("units")
	for parts in attached_parts:
		parts.remove_from_group("units")
		parts.is_alive = false
		parts.visible = false
		parts.process_mode = Node.PROCESS_MODE_DISABLED
	#self.queue_free()


# --- Stitching -------------------------------------------------------------

## Attaches another Creature to this creature. Returns false if it doesn't fit.
func StitchBodyPart(part: Creature, myExtraPriority: int=0, otherExtraPriority: int= 0) -> Dictionary:
	if part == self or is_stitched or part.is_stitched:
		return {"success": false, "host": self, "otherPart": part}
	
	# Higher priority becomes the host. Equal priority: the caller is the host.
	if part.stitch_priority + otherExtraPriority > stitch_priority + myExtraPriority:
		print("Swapperoooo")
		return part.StitchBodyPart(self, otherExtraPriority, myExtraPriority)
	
	var pair := _find_matching_points(part)
	if pair.is_empty():
		return {"success": false, "host": self, "otherPart": part}

	var mine: ConnectionPoint = pair[0]
	var theirs: ConnectionPoint = pair[1]

	mine.connected_part = part
	theirs.connected_part = self

	if part.get_parent():
		part.reparent(self)
	else:
		add_child(part)
	
	var newScale = mine.attachmentScale + randf_range(-randomAttachmentScaleOffset, randomAttachmentScaleOffset)
	part.scale = Vector2(newScale, newScale)
	part.rotation = deg_to_rad(mine.attachmentRotation + randf_range(-randomAttachmentRotationOffset, randomAttachmentRotationOffset))
	part.position = mine.position - part.transform.basis_xform(theirs.position)
	
	lives += part.lives
	hp += part.hp
	speed += part.speed
	attackDamage += part.attackDamage
	attackCooldown += part.attackCooldown
	attackRange += part.attackRange
	print("%s new stats: L:%s | Hp:%s | Spd:%s | Atk:%s | Atk_Cd:%s | Atk_Rng:%s" % [self.name, lives, hp, speed, attackDamage, attackCooldown, attackRange])
	
	part._on_stitched()
	print("Stitched %s(%s) onto %s(%s)" % [part.name, part.stitch_priority, self.name, self.stitch_priority])
	return {"success": true, "host": self, "otherPart": part}


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

func UpgradeCreature() -> Creature:
	if upgrade == null:
		return self
	
	var newVersion = upgrade.instantiate()
	SwapCreature(newVersion as Creature)
	return newVersion

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
	
	new_creature.lives += lives
	new_creature.hp += hp
	new_creature.speed += speed
	new_creature.attackCooldown += attackCooldown
	new_creature.attackRange += attackRange
	print("%s new stats: L:%s | Hp:%s | Spd:%s | Atk:%s | Atk_Cd:%s | Atk_Rng:%s" % [new_creature.name, new_creature.lives, new_creature.hp, new_creature.speed, new_creature.attackDamage, new_creature.attackCooldown, new_creature.attackRange])
	
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
