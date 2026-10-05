extends Node
@export var main_tile_map: TileMapLayer
@export var speed:int =  1000
var flowfield:Dictionary[Vector2,Global.TileTransform]
var list_items:Array[Sprite2D]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func append_flowfield(vec:Vector2, Rotation:Global.TileTransform):
	flowfield.get_or_add(vec,Rotation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func append_list_items(node:Sprite2D):
	list_items.append(node)
func _process(delta: float) -> void:
	for item in list_items:
		var grid_pos: Vector2 = main_tile_map.local_to_map(item.global_position)
		if flowfield.has(grid_pos):
			var transform_data:Global.TileTransform = flowfield[grid_pos]
			move_item(item,delta,transform_data,main_tile_map.to_global(main_tile_map.map_to_local(grid_pos)))


func move_item(node:Sprite2D,delta:float,transform_data:Global.TileTransform,flowfield_global_pos:Vector2):
	match transform_data:
		Global.TileTransform.ROTATE_0:
			
			var target_y := flowfield_global_pos.y 

			node.global_position.y = move_toward(node.position.y, target_y, speed * delta)
			node.position.x += speed * delta
		Global.TileTransform.ROTATE_90:
			var target_x := flowfield_global_pos.x 
			node.position.x = move_toward(node.position.x, target_x, speed * delta)
			node.position.y += speed * delta 
		Global.TileTransform.ROTATE_180:
			var target_y := flowfield_global_pos.y 
			node.position.y = move_toward(node.position.y, target_y, speed * delta)
			node.position.x -= speed * delta 
		Global.TileTransform.ROTATE_270:
			var target_x := flowfield_global_pos.x 
			node.position.x = move_toward(node.position.x, target_x, speed * delta)
			node.position.y -= speed * delta 
		_:
			pass
