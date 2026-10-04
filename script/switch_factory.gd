extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_released("Belt"):
		Global.current_house = 0
	if event.is_action_released("Splitter"):
		Global.current_house = 1
	if event.is_action_released("Goo_maker"):
		Global.current_house = 2
	if event.is_action_pressed("roration"):
		var rotations = Global.TileTransform.values()
		var index = rotations.find(Global.currentrotation)
		Global.currentrotation = rotations[(index + 1) % (rotations.size()-1)]
