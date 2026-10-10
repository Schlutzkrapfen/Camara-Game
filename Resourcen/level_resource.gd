class_name LevelResource
extends Resource

@export var current_level:PackedScene
@export var next_level:PackedScene 
@export var level_top_conrner:Vector2i
@export var level_button_corner:Vector2i =Vector2i( 100,100)
@export var start_goo:int
@export var building:Dictionary[Vector2i,BuildingResource]
