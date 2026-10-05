extends TileMapLayer


@onready var tilemap:TileMapLayer =  self
signal new_flowmaptile_saved(postion,transform)  
signal item_spawned(Node2d)  
var is_okay_to_build:bool = true
class BuildData:
	var rotation: Global.TileTransform
	var resource_refrence: BuildingResource
	var cur_time: float = 0
	var last_output:int =0
	func _init( p_buildingresource: BuildingResource ,p_transform: Global.TileTransform = Global.TileTransform.None) -> void:
		rotation = p_transform
		resource_refrence = p_buildingresource


var current_builds: Dictionary[Vector2i, BuildData]



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func check_building(is_okay:bool):
	is_okay_to_build = is_okay

func _process(delta: float) -> void:
	for key in current_builds: # or current_builds.items()
		var factory:BuildData = current_builds[key]
		#if factory.input == factory.cur_input:
		factory.cur_time +=delta
		if factory.cur_time > factory.resource_refrence.craft_time: 
			output_items(factory,key)
			factory.cur_time = 0
				

func output_items(factory:BuildData,positon):
	for item_resource in factory.resource_refrence.output:
		var current_size:int = factory.last_output% factory.resource_refrence.output_tile.size()
		var item = item_resource.item_scene.instantiate()
		var keys = factory.resource_refrence.output_tile.keys()
		
		item.global_position = tilemap.to_global(
		tilemap.map_to_local(positon + Global.get_rotation_out_of_size(keys[current_size].x,keys[current_size].y,factory.rotation))
)
		add_child(item)
		emit_signal("item_spawned",item)


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
	print("ERROR DELTE DOES NOT FUNKTION CORRECLTY AT THE MOMENT")
	print(tile)
	tilemap.set_cell(tile)
	
	
func spawn(mouse_position):
	var local_position = tilemap.to_local(mouse_position)
	var tile = tilemap.local_to_map(local_position)
	var current_house = Global.factory_list[Global.current_house]
	for x in current_house.size.x:
		for y in current_house.size.y:
			var local_tile =  Vector2i(x,y)
			var tiles = tile + Global.get_rotation_out_of_size(x ,y)
			emit_signal("new_flowmaptile_saved",tiles,Global.currentrotation)
			tilemap.set_cell(tiles,current_house.tilemap_id,current_house.position_tilemap+local_tile,Global.currentrotation)
	var buildings:BuildData =  BuildData.new(current_house,Global.currentrotation)
	current_builds[tile] =buildings


	
	
