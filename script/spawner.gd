class_name MainTileMap
extends TileMapLayer

@onready var tilemap:TileMapLayer =  self
@onready var flowfield:FlowField = $FlowField

var current_builds: Dictionary[Vector2i, BuildData]
var occupied_tiles: Dictionary[Vector2i, Vector2i] = {}

var is_okay_to_build:bool = true
class BuildData:
	var rotation: Global.TileTransform
	var resource_refrence: BuildingResource
	var cur_time: float = 0
	var cur_items: Array[Node2D] 
	var last_output:int =0
	var output_position:Array[Vector2i]
	func _init( p_buildingresource: BuildingResource ,p_outputpostion:Array[Vector2i],p_transform: Global.TileTransform = Global.TileTransform.None) -> void:
		rotation = p_transform
		resource_refrence = p_buildingresource
		output_position = p_outputpostion



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_priority = -1
	pass

func add_item_input(item:Node2D,positon:Vector2i)->bool:
	var factory = current_builds[positon]
	if len(factory.cur_items) < factory.resource_refrence.input_size:
		
		factory.cur_items.append(item)
		item.visible = false
		flowfield.delete_item(item)
		item.process_mode = Node.PROCESS_MODE_DISABLED
		return true
	return false

func check_building(is_okay:bool):
	is_okay_to_build = is_okay

func _process(delta: float) -> void:
	for key in current_builds: # or current_builds.items()
		var factory:BuildData = current_builds[key]
		if len(factory.resource_refrence.output) == 0:
			output_input(factory)
			continue
		if check_input(factory):
			factory.cur_time +=delta
			if factory.cur_time > factory.resource_refrence.craft_time: 
				if output_items(factory):
					factory.cur_time = 0
			

func output_input(factory):
	for i in range(factory.cur_items.size() - 1, -1, -1):
		var item = factory.cur_items[i]
		factory.last_output = (factory.last_output +1)% len(factory.output_position) 
		if not flowfield.is_cell_free(factory.output_position[factory.last_output]):
			continue
		factory.cur_items.clear()
		item.process_mode = Node.AUTO_TRANSLATE_MODE_INHERIT
		item.global_position = tilemap.to_global(
		tilemap.map_to_local(factory.output_position[factory.last_output])
)
		item.visible = true
		flowfield.append_list_items(item)
		factory.cur_items.remove_at(i)


func check_input(factory:BuildData) ->bool:
	var required: Array = factory.resource_refrence.input
	var available: Array = factory.cur_items.duplicate()
	for type in required:
		var found := false
		for item in available:
			if is_instance_of(item, type):
				available.erase(item)  # each item can only satisfy one requirement
				found = true
				break
		if not found:
			return false
	return true

func output_items(factory:BuildData)-> bool:
	for item_resource in factory.resource_refrence.output:
		factory.last_output = (factory.last_output +1)% len(factory.output_position) 
		if not flowfield.is_cell_free(factory.output_position[factory.last_output]):
			return false
		var item = item_resource.instantiate()
		item.global_position = tilemap.to_global(
		tilemap.map_to_local(factory.output_position[factory.last_output])
)
		add_child(item)
		flowfield.append_list_items(item)
		factory.cur_items.clear()
		return true
	return false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_okay_to_build:
			spawn(event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			delete(event.position)

func delete(mouse_position):
	var local_position:Vector2 = tilemap.to_local(mouse_position)
	var tile:Vector2i = tilemap.local_to_map(local_position)
	var factory_start_position:Vector2i = occupied_tiles[tile]
	var build_data:BuildData = current_builds[factory_start_position]
	var size:Vector2i = build_data.resource_refrence.size
	current_builds.erase(factory_start_position)
	for x in size.x:
		for y in size.y:
			var factory_position = factory_start_position + Global.get_rotation_out_of_size(x,y,build_data.rotation)
			tilemap.set_cell(factory_position)
			flowfield.delete_flowfield(factory_position)
			occupied_tiles.erase(factory_position)
	

func spawn(mouse_position):
	var local_position = tilemap.to_local(mouse_position)
	var tile = tilemap.local_to_map(local_position)
	var current_house = Global.factory_list[Global.current_house]
	var output_postion:Array[Vector2i] 
	for x in current_house.size.x:
		for y in current_house.size.y:
			var local_tile =  Vector2i(x,y)
			var tiles = tile + Global.get_rotation_out_of_size(x ,y)
			if current_house.output_tile.has(local_tile):
				flowfield.append_flowfield(tiles,Global.currentrotation)
				output_postion.append(Vector2i(tiles.x+Global.ROTATE_DIRECTION[Global.currentrotation].x,tiles.y+Global.ROTATE_DIRECTION[Global.currentrotation].y))
			else:
				flowfield.append_flowfield(tiles,Global.TileTransform.None)
			occupied_tiles[tiles] = tile
			tilemap.set_cell(tiles,current_house.tilemap_id,current_house.position_tilemap+local_tile,Global.currentrotation)
	var buildings:BuildData = BuildData.new(current_house,output_postion,Global.currentrotation)
	current_builds[tile] =buildings
