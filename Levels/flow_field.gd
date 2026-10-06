class_name FlowField
extends Node
@export var main_tile_map: TileMapLayer
@export var speed:int =  1000
var flowfield:Dictionary[Vector2,Global.TileTransform]
var list_items:Array[Sprite2D]
var grid_pos_array:Dictionary[Vector2i,bool]
var item_used:Dictionary[Sprite2D,Vector2]
var item_moved:Dictionary[Vector2,bool]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func append_flowfield(vec:Vector2, Rotation:Global.TileTransform):
	flowfield.get_or_add(vec,Rotation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func append_list_items(node:Sprite2D):
	list_items.append(node)

func _process(delta: float) -> void:
	item_moved.clear()
	grid_pos_array.clear()
	item_used.clear()
	for item in list_items:
		var grid_pos =main_tile_map.local_to_map(item.global_position)
		grid_pos_array[grid_pos] = true
		if flowfield.has(grid_pos):
			item_used[item]=grid_pos
	for item in item_used.keys():
		move_item(item,delta,flowfield[item_used[item]],main_tile_map.to_global(main_tile_map.map_to_local(item_used[item])),item_used[item])

func is_cell_free(grid_pos: Vector2i) -> bool:
	return not grid_pos_array.has(grid_pos)

func move_item(node:Sprite2D,delta:float,transform_data:Global.TileTransform,flowfield_global_pos:Vector2,flowfield_pos:Vector2i):
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
