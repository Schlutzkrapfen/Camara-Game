class_name BuildData
extends RefCounted

var rotation: Global.TileTransform
var resource_refrence: BuildingResource
var cur_time: float = 0
var input_tile: Array[Vector2i]
var cur_items: Array[Node2D]
var last_output: int = 0
var black_list: Dictionary[Node2D, bool]
var output_position: Array[Vector2i]
var can_get_input: bool
var already_emited: bool

func _init(p_buildingresource: BuildingResource, p_outputpostion: Array[Vector2i], p_transform: Global.TileTransform = Global.TileTransform.None) -> void:
	rotation = p_transform
	resource_refrence = p_buildingresource
	output_position = p_outputpostion
