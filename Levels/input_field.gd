extends Node
var input_field:Dictionary[Vector2,Global.TileTransform]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func append_Inputfield(vec:Vector2, Rotation:Global.TileTransform):
	input_field.get_or_add(vec,Rotation)
