extends TileMapLayer


@onready var tilemap:TileMapLayer =  self

var is_okay_to_build:bool = true
var current_builds:Array[BuildingResource]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func check_building(is_okay:bool):
	is_okay_to_build = is_okay

func _process(delta: float) -> void:
	for factoy in current_builds:
		if factoy.input == factoy.cur_input:
			factoy.cur_time +=delta
			if factoy.cur_time > factoy.craft_time: 
				output_items()
func output_items():
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_okay_to_build:
			spawn(event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			delete(event.position)

func delete(mouse_position):
	#TODO:delte hole factory
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
	Global.factory_list[Global.current_house].positon = tile
	current_builds.append(Global.factory_list[Global.current_house])
	
