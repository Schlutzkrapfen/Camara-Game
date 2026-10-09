extends Node2D
class_name Enemy

@export var searchDelayFrames: int = 20
@export var hp: int = 20
@export var speed: float = 50
@export var attackDamage: int = 3
@export var attackCooldown: float = 0.1
@export var attackRange: float = 200

@export_category("Spawner")
@export var isSpawner: bool = false
@export var spawn: PackedScene
@export var minSpawnTime: float = 3
@export var maxSpawnTime: float = 5
var target: Creature
var curTimeUntilNextSpawn: float
var curAttackCooldown: float = 0.0
var sprite: Sprite2D
var searchCountDown: int


func _ready() -> void:
	searchCountDown = randi_range(0, searchDelayFrames)
	sprite = find_children("*", "Sprite2D")[0]


func _process(delta: float) -> void:
	#if not raidStarted:
	#	return
	
	if isSpawner:
		curTimeUntilNextSpawn -= delta
		if curTimeUntilNextSpawn <= 0:
			curTimeUntilNextSpawn = randf_range(minSpawnTime, maxSpawnTime)
			var newEnemy = spawn.instantiate() as Enemy
			get_tree().current_scene.add_child(newEnemy)
			newEnemy.global_position = self.global_position
	
	## Confirm target
	
	if speed > 0 and (target == null or not target.is_alive): # speed = 0 means it's a building
		searchCountDown -= 1
		if searchCountDown <= 0: 
			target = SearchForTarget()
			searchCountDown = searchDelayFrames
		return
	
	curAttackCooldown -= delta
	
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
		else:
			## Move towards target
			if speed > 0:
				position += (target.position - self.position).normalized() * delta * speed


func SearchForTarget() -> Node2D:
	var playerUnits := get_tree().get_nodes_in_group("units")
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
