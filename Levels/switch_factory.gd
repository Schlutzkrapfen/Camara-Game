extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_released("Belt"):
		Global.current_house = 0
	if event.is_action_released("Splitter"):
		Global.current_house = 1
