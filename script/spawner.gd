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
	var black_list:Dictionary[Node2D,bool]
	var output_position:Array[Vector2i]
	var can_get_input:bool
	func _init( p_buildingresource: BuildingResource ,p_outputpostion:Array[Vector2i],p_transform: Global.TileTransform = Global.TileTransform.None) -> void:
		rotation = p_transform
		resource_refrence = p_buildingresource
		output_position = p_outputpostion


## Sets processing priority so this runs before other nodes each frame.
func _ready() -> void:
	process_priority = -1
	pass

## Stores an item inside the building at the given tile if it has room, returns whether it was accepted.
func add_item_input(item:Node2D,positon:Vector2i)->bool:
	var factory = current_builds[positon]
	if len(factory.cur_items) < factory.resource_refrence.input_size and not factory.black_list.has(item):
		if not needs_item(factory,item):
			factory.black_list[item] = true
			return false
		factory.cur_items.append(item)
		item.visible = false
		flowfield.delete_item(item)
		item.process_mode = Node.PROCESS_MODE_DISABLED
		return true
	return false

## Returns true if the building still needs an item of this item's type.
func needs_item(factory: BuildData, item: Node2D) -> bool:
	if len(factory.resource_refrence.input) == 0:
		return true
	var still_needed: Array = factory.resource_refrence.input.duplicate()
	# Cross off requirements already covered by stored items.
	for stored in factory.cur_items:
		for type in still_needed:
			if is_instance_of(stored, type):
				still_needed.erase(type)
				break
	# Does the new item fit one of the remaining requirements?
	for type in still_needed:
		if is_instance_of(item, type):
			return true
	return false

## Enables or disables building placement.
func check_building(is_okay:bool):
	is_okay_to_build = is_okay

## Each frame, runs every building: passes items through, crafts, and outputs results.
func _process(delta: float) -> void:
	for key in current_builds: # or current_builds.items()
		var factory:BuildData = current_builds[key]
		if factory.resource_refrence.factory_type == Global.factory_type.No_builder:
			output_input(factory)
			continue
		if check_input(factory):
			factory.can_get_input = false
			factory.cur_time +=delta
			if factory.cur_time > factory.resource_refrence.craft_time: 
				if factory.resource_refrence.factory_type == Global.factory_type.Combine:
					if combine_items(factory):
						factory.cur_time = 0
						factory.can_get_input = true
					return
				if factory.resource_refrence.factory_type == Global.factory_type.Upgrader:
					if upgrade_items(factory):
						factory.cur_time = 0
						factory.can_get_input = true
					return
				if output_items(factory):
					factory.cur_time = 0
					factory.can_get_input = true

func upgrade_items(factory:BuildData)-> bool:
	var result: Creature = null
	for item in factory.cur_items:
		var creature := item as Creature
		if creature == null:
			continue
		creature.UpgradeCreature()
		result = creature
	factory.cur_items.clear()
	if result:
		factory.cur_items.append(result)
	return output_input(factory)
## Stitches two stored Creature items together and sends the result out.
func combine_items(factory:BuildData)-> bool:
	var two_creaturs:Array[Creature]
	for item in factory.cur_items:
		var typed_item := item as Creature
		if typed_item:
			two_creaturs.append(typed_item)
			if two_creaturs.size() == 2:
				break
	two_creaturs[1].StitchBodyPart(two_creaturs[0])
	two_creaturs[0].visible= true
	return output_input(factory)
	
## Moves stored items out of the building onto a free output cell and re-enables them.
func output_input(factory)->bool:
	var full_output:int = 0
	for i in range(factory.cur_items.size() - 1, -1, -1):
		var item = factory.cur_items[i]
		factory.last_output = (factory.last_output +1)% len(factory.output_position) 
		if not flowfield.is_cell_free(factory.output_position[factory.last_output]):
			full_output+=1
			continue
		
		item.process_mode = Node.AUTO_TRANSLATE_MODE_INHERIT
		item.global_position = tilemap.to_global(
		tilemap.map_to_local(factory.output_position[factory.last_output])
)
		item.visible = true
		flowfield.append_list_items(item)
		factory.cur_items.clear()
		if factory.cur_items.size() == 0:
			return true
		factory.cur_items.remove_at(i)
	if full_output == factory.cur_items.size():
		return false
	return true

## Returns true if the building holds items matching all its required input types.
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


## Spawns the building's output items on a free output cell and clears the inputs, returns whether it succeeded.
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

## Left click places a building, right click deletes one.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_okay_to_build:
			spawn()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			delete()

## Removes the building under the mouse and frees all the tiles it covered.
func delete():
	var mouse_position = get_global_mouse_position()
	var local_position:Vector2 = tilemap.to_local(mouse_position)
	var tile:Vector2i = tilemap.local_to_map(local_position)
	if not occupied_tiles.has(tile):
		print("nothing to delte")
		return
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

## Places the selected building at the mouse tile, registers its tiles, flowfield, and output cells.
func spawn():
	var mouse_position = get_global_mouse_position()
	var tile = tilemap.local_to_map(tilemap.to_local(mouse_position))
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
