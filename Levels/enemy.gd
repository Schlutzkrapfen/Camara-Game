extends Node2D
class_name Enemy

@export var hp: int = 20
@export var speed: float = 50
@export var attackDamage: int = 3
@export var attackCooldown: float = 0.1
@export var attackRange: float = 200
@export var minSelfdestructTime: float = 4
@export var maxSelfdestructTime: float = 6
var target: Node2D
var timeUntilSelfDestruct: float
var curAttackCooldown: float = 0.0
var sprite: Sprite2D


func _ready() -> void:
	timeUntilSelfDestruct = randf_range(minSelfdestructTime, maxSelfdestructTime)
	sprite = find_children("*", "Sprite2D")[0]


func _process(delta: float) -> void:
	#if not raidStarted:
	#	return
	
	## Confirm target
	if target == null:
		target = SearchForTarget()
		timeUntilSelfDestruct -= delta
		if timeUntilSelfDestruct <= 0:
			Die()
		return
	
	curAttackCooldown -= delta
	
	## Move towards target
	if curAttackCooldown <= 0:
		position += (target.position - self.position).normalized() * delta * speed
	
	## Attack if possible
	if curAttackCooldown <= 0:
		var someoneInRange: bool = false
		for playerUnits in get_tree().get_nodes_in_group("units"):
			if global_position.distance_squared_to(playerUnits.global_position) <= attackRange * attackRange:
				someoneInRange = true
				playerUnits.TakeDamage(attackDamage)
		if someoneInRange:
			if attackCooldown < 0.1: # Hard-Coded minimum
				curAttackCooldown = 0.1
			else:
				curAttackCooldown = attackCooldown
			SpawnAttackVisual()


func SearchForTarget() -> Node2D:
	var playerUnits := get_tree().get_nodes_in_group("units")
	print(playerUnits)
	if playerUnits.is_empty():
		return null
	return playerUnits.pick_random() as Node2D

func SpawnAttackVisual() -> void:
	var fx := AttackEffect.new()
	fx.radius = attackRange
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position

func TakeDamage(damage: int) -> void:
	hp -= damage
	DamageFlash()
	
	if hp <= 0:
		Die()

func DamageFlash() -> void:
	var tween = create_tween()
	sprite.modulate = Color(2.5, 0.3, 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func Die() -> void:
	print("Owowowow")
	self.queue_free()
