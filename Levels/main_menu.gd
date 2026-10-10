extends Control

@export var game:PackedScene
@export var tutorail:PackedScene

func _on_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Levels/Tutorial0.tscn")



func _on_start_button_up() -> void:
	get_tree().change_scene_to_file("res://Levels/main_scene_RobertTesting.tscn")
