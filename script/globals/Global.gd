extends Node
@onready var factory_list: Array[BuildingResource] = [
	preload("res://Resourcen/conaer_belt.tres"),
	preload("res://Resourcen/splitter.tres")
]
var current_house: int = 1
