class_name BuildingResource
extends Resource


@export var size:Vector2i = Vector2i(1,1)
@export var position_tilemap:Vector2i = Vector2i(0,0)
@export var tilemap_id:int = 0
@export var craft_time:float = 0.1
@export var input:Array[Script]
@export var output:Array[PackedScene]
#Which tile has the output and which direction
@export var output_tile:Dictionary[Vector2i,Global.TileTransform]
@export var input_size:int = 1
@export var output_everything:bool = true
