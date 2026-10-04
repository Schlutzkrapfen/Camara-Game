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
	None
}
var currentrotation:TileTransform= TileTransform.ROTATE_0

func get_rotation_out_of_size(x: int, y: int, rotation =TileTransform.None) -> Vector2i:
	if rotation == TileTransform.None:
		rotation = currentrotation
	match rotation :
		TileTransform.ROTATE_90:
			
			return Vector2i(
			-y ,
			 x )
		TileTransform.ROTATE_180:
			return Vector2i(
				- x ,
				- y
		)
		TileTransform.ROTATE_270:
			return Vector2i(
				y ,
				-x )
		_:
			return Vector2i(x, y)
	
	
