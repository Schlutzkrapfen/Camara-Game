class_name BuildingResource
extends Resource


@export var size:Vector2i = Vector2i(1,1)
@export var position_tilemap:Vector2i = Vector2i(0,0)
@export var tilemap_id:int = 0
@export var craft_time:float = 0.1
@export var input:Array[itemResouce]
@export var output:Array[itemResouce]
#Which tile has the output and which direction
@export var output_tile:Dictionary[Vector2i,Global.TileTransform]
var position:Vector2i = Vector2i(0,0)
var cur_input:Array[itemResouce]
var cur_time:float = 0
var last_output:int = 0
var build_rotation:Global.TileTransform 
