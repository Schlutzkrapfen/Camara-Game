extends Node
var build_zone_size_buttom_right:Vector2i = Vector2i(64,69)
var build_zone_size_top_left:Vector2i = Vector2i(-62,-3)
var curGoo: int = 150
@onready var factory_list: Array[BuildingResource] = [
	preload("res://Resourcen/goo_factory.tres"),
	preload("res://Resourcen/conaer_belt.tres"),
	preload("res://Resourcen/splitter.tres"),
	preload("res://Resourcen/head_maker.tres"),
	preload("res://Resourcen/torso_maker.tres"),
	preload("res://Resourcen/horn_maker.tres"),
	preload("res://Resourcen/foot_maker.tres"),
	preload("res://Resourcen/combiner.tres"),
	preload("res://Resourcen/upgrader.tres"),
	preload("res://Resourcen/aliver.tres"),
]
var current_house: int = 1
enum TileTransform {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	None
}
enum  factory_type{
		Normal =0,
		Combine= 1,
		Upgrader= 2,
		Aliver= 3,
		No_builder = 4,
		Emit_Signal = 5
	}
var ROTATE_DIRECTION:Dictionary[TileTransform,Vector2] = {
	TileTransform.ROTATE_0: Vector2(1,0),
	TileTransform.ROTATE_90: Vector2(0,1),
	TileTransform.ROTATE_180: Vector2(-1,0),
	TileTransform.ROTATE_270: Vector2(0,-1),
	TileTransform.None:Vector2(0,0)
	
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
	
	
