extends Node
@onready var factory_list: Array[BuildingResource] = [
	preload("res://Resourcen/conaer_belt.tres"),
	preload("res://Resourcen/splitter.tres"),
	preload("res://Resourcen/goo_factory.tres")
]
var current_house: int = 1
enum TileTransform {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
}
var currentrotation:TileTransform= TileTransform.ROTATE_0

func get_rotation_out_of_size(x: int, y: int) -> Vector2i:
	match currentrotation :
		TileTransform.ROTATE_90:
			return Vector2i(
				factory_list[current_house].size.y - 1 - y,
				factory_list[current_house].size.x - 1 - x
		)
		TileTransform.ROTATE_180:
			return Vector2i(
				- x ,
				- y
		)
		TileTransform.ROTATE_270:
			return Vector2i(
				y +1- factory_list[current_house].size.y, x+1 -factory_list[current_house].size.x
			)
		_:
			return Vector2i(x, y)
	
	
