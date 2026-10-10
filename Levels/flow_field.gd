class_name FlowField
extends Node
@export var main_tile_map: MainTileMap
@export var speed:int =  1000
var flowfield:Dictionary[Vector2,Global.TileTransform]
var list_items:Array[Node2D]
var grid_pos_array:Dictionary[Vector2i,bool]
var item_used:Dictionary[Node2D,Vector2]
var item_moved:Dictionary[Vector2,bool]



func append_flowfield(vec:Vector2, Rotation:Global.TileTransform):
	var test = flowfield.get_or_add(vec,Rotation)
	if (test != Rotation):
		print("Something wrong with spawning the flowfield")
func delete_flowfield(vec:Vector2):
	flowfield.erase(vec)
func append_list_items(node:Node2D):
	list_items.append(node)
func delete_item(node:Node2D):
	list_items.erase(node)

func remove_alive_items_flowfied():
	for i in range(list_items.size() - 1, -1, -1):
		var creature := list_items[i] as Creature
		if creature ==null:
			continue
		if creature.is_alive:
			list_items.erase(creature) 
func delete_items_from_tile(tile_pos):
	for item in list_items:
		if item == null:
			continue
		var grid_pos =main_tile_map.local_to_map(item.global_position)
		if grid_pos == tile_pos:
			list_items.erase(item)
			item.queue_free()


		
func _process(delta: float) -> void:
	item_moved.clear()
	grid_pos_array.clear()
	item_used.clear()
	for item in list_items:
		if item == null:
			continue
		var grid_pos =main_tile_map.local_to_map(item.global_position)
		grid_pos_array[grid_pos] = true
		if main_tile_map.occupied_tiles.has(grid_pos)and main_tile_map.add_item_input(item, grid_pos):
			continue
		if flowfield.has(grid_pos):
			item_used[item]=grid_pos
	for item in item_used.keys():
		move_item(item,delta,flowfield[item_used[item]],main_tile_map.to_global(main_tile_map.map_to_local(item_used[item])),item_used[item])

func is_cell_free(grid_pos: Vector2i) -> bool:
	return not grid_pos_array.has(grid_pos)

func move_item(node:Node2D,delta:float,transform_data:Global.TileTransform,flowfield_global_pos:Vector2,flowfield_pos:Vector2i):
	match transform_data:
		Global.TileTransform.ROTATE_0:
			var target_y := flowfield_global_pos.y 
			node.global_position.y = move_toward(node.position.y, target_y, speed * delta)
			if not grid_pos_array.has(Vector2(flowfield_pos.x+1,flowfield_pos.y)) and not item_moved.has(Vector2(flowfield_pos.x+1,flowfield_pos.y)) :
				item_moved[Vector2(flowfield_pos.x+1,flowfield_pos.y)] = true
				node.position.x += speed * delta
			else:
				node.position.x = move_toward(node.position.x, flowfield_global_pos.x, speed * delta)
		Global.TileTransform.ROTATE_90:
			var target_x := flowfield_global_pos.x 
			node.position.x = move_toward(node.position.x, target_x, speed * delta)
			if not grid_pos_array.has(Vector2(flowfield_pos.x,flowfield_pos.y+1)) and not item_moved.has(Vector2(flowfield_pos.x,flowfield_pos.y+1)) :
				item_moved[Vector2(flowfield_pos.x,flowfield_pos.y+1)] = true
				node.position.y += speed * delta 
			else:
				node.global_position.y = move_toward(node.position.y, flowfield_global_pos.y , speed * delta)
		Global.TileTransform.ROTATE_180:
			var target_y := flowfield_global_pos.y 
			node.position.y = move_toward(node.position.y, target_y, speed * delta)
			if not grid_pos_array.has(Vector2(flowfield_pos.x-1,flowfield_pos.y)) and not item_moved.has(Vector2(flowfield_pos.x-1,flowfield_pos.y)) :
				item_moved[Vector2(flowfield_pos.x-1,flowfield_pos.y)]= true
				node.position.x -= speed * delta
			else:
				node.position.x = move_toward(node.position.x, flowfield_global_pos.x, speed * delta)
		Global.TileTransform.ROTATE_270:
			var target_x := flowfield_global_pos.x 
			node.position.x = move_toward(node.position.x, target_x, speed * delta)
			if not grid_pos_array.has(Vector2(flowfield_pos.x,flowfield_pos.y-1)) and not item_moved.has(Vector2(flowfield_pos.x,flowfield_pos.y-1)) :
				item_moved[Vector2(flowfield_pos.x,flowfield_pos.y-1)]= true
				node.position.y -= speed * delta 
			else:
				node.global_position.y = move_toward(node.position.y, flowfield_global_pos.y , speed * delta)
		_:
			pass
