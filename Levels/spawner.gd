extends TileMapLayer


@export var factory_list:Array[BuildingResource]
@onready var tilemap:TileMapLayer =  self

var is_okay_to_build:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#var tile = Vector2i(get_global_mouse_position().x+x,get_global_mouse_position().y+y)
	#var currentShowTile = Vector2i(currentStats.tileMapPosition[0].x+x,currentStats.tileMapPosition[0].y+y)
	#tilemap.set_cell(tile,currentStats.tileMapID[0],currentShowTile)
	#var globalTilePosition = tilemap.to_global(@export var size:Array = Array(0,0)tilemap.map_to_local(tile))

func check_building(is_okay:bool):
	is_okay_to_build = is_okay

	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_okay_to_build:
			spawn(event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			delete(event.position)

func delete(mouse_position):
	var local_position = tilemap.to_local(mouse_position)
	var tile = tilemap.local_to_map(local_position)
	print(tile,factory_list[0].tilemap_id,factory_list[0].position_tilemap)
	tilemap.set_cell(tile)
	
func spawn(mouse_position):
	var local_position = tilemap.to_local(mouse_position)
	var tile = tilemap.local_to_map(local_position)
	print(tile,factory_list[0].tilemap_id,factory_list[0].position_tilemap)
	tilemap.set_cell(tile,factory_list[0].tilemap_id,factory_list[0].position_tilemap)
	
	
