extends Node2D
class_name Enemy

@export var hp: int = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func TakeDamage(damage: int) -> void:
	hp -= damage
	print("OUCH")
	if hp <= 0:
		Die()

func Die() -> void:
	self.queue_free()
