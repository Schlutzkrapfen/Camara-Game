extends Node2D
class_name GameManager

enum GameState { BUILDING, RAIDING }
var curGameState: GameState = GameState.BUILDING
@export var cam: CameraController
@export var curGoo: int = 50 
var selectedDestination: PackedScene

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	match curGameState:
#		GameState.BUILDING:
#			pass
#		GameState.RAIDING:
#			pass

func StopRaid() -> void:
	cam.locked = true;

func StartRaid() -> void:
	if selectedDestination == null:
		return
	
	curGameState = GameState.RAIDING
	cam.locked = false;
	var newSettlement = selectedDestination.instantiate()
	get_tree().current_scene.add_child(newSettlement)
	# MISSING -> Set Producing Goo to ON!
