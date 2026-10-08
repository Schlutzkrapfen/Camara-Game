extends TileMapLayer

@export var main_tileset:TileMapLayer
@onready var tilemap:TileMapLayer = self
@onready var rotation_tilemap= $Rotationbuild

signal is_okay_to_build(bool)
func _ready() -> void:
		process_priority = -2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func check_if_okay_to_build(tile)-> bool:
	for x in Global.factory_list[Global.current_house].size.x:
		for y in Global.factory_list[Global.current_house].size.y:
			var tiles = Global.get_rotation_out_of_size(x,y)
			var end_tile: Vector2i = tile + tiles
			if tile.x < Global.build_zone_size_top_left.x or tile.y < Global.build_zone_size_top_left.y or end_tile.x > Global.build_zone_size_buttom_right.x or end_tile.y > Global.build_zone_size_buttom_right.y or main_tileset.get_cell_tile_data(end_tile) != null:
				emit_signal("is_okay_to_build",false)
				return false
	emit_signal("is_okay_to_build",true)
	return true
func _process(_delta: float) -> void:#
	tilemap.clear()
	rotation_tilemap.clear()
	var current_house = Global.factory_list[Global.current_house]
	var mouse_pos = get_global_mouse_position()
	var tile = tilemap.local_to_map(tilemap.to_local(mouse_pos))
	var is_okay= check_if_okay_to_build(tile)
	for x in Global.factory_list[Global.current_house].size.x:
		for y in Global.factory_list[Global.current_house].size.y:
			var tiles = tile +Global.get_rotation_out_of_size(x, y)
			var local_tile = Vector2i(x,y)
			if is_okay:
				tilemap.set_cell(tiles,0,Vector2i(0,0))
			else:
				tilemap.set_cell(tiles,1,Vector2i(0,0))
			rotation_tilemap.set_cell(tiles,current_house.tilemap_id,current_house.position_tilemap+local_tile,Global.currentrotation)
