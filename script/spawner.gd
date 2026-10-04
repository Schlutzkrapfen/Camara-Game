extends TileMapLayer


@onready var tilemap:TileMapLayer =  self

var is_okay_to_build:bool = true

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
	print(tile)
	tilemap.set_cell(tile)
	
func spawn(mouse_position):
	var local_position = tilemap.to_local(mouse_position)
	var tile = tilemap.local_to_map(local_position)
	print(tile,Global.factory_list[Global.current_house].tilemap_id,Global.factory_list[Global.current_house].position_tilemap)
	for x in Global.factory_list[Global.current_house].size.x:
		for y in Global.factory_list[Global.current_house].size.y:
			var local_tile =  Vector2i(x,y)
			var tiles =tile+ Global.get_rotation_out_of_size(x ,y)
			tilemap.set_cell(tiles,Global.factory_list[Global.current_house].tilemap_id,Global.factory_list[Global.current_house].position_tilemap+local_tile,Global.currentrotation)
