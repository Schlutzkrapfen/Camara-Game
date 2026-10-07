extends TileMapLayer

@export var main_tileset:TileMapLayer
@onready var tilemap:TileMapLayer = self

signal is_okay_to_build(bool)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func check_if_okay_to_build(tile)-> bool:
	for x in Global.factory_list[Global.current_house].size.x:
		for y in Global.factory_list[Global.current_house].size.y:
			var tiles = Global.get_rotation_out_of_size(x,y)
			if main_tileset.get_cell_tile_data(tile +tiles) != null:
				emit_signal("is_okay_to_build",false)
				return false
	emit_signal("is_okay_to_build",true)
	return true
func _process(_delta: float) -> void:#
	tilemap.clear()
	var mouse_pos = get_global_mouse_position()
	var tile = tilemap.local_to_map(tilemap.to_local(mouse_pos))
	var is_okay= check_if_okay_to_build(tile)
	for x in Global.factory_list[Global.current_house].size.x:
		for y in Global.factory_list[Global.current_house].size.y:
			var tiles = tile +Global.get_rotation_out_of_size(x, y)
			if is_okay:
				tilemap.set_cell(tiles,0,Vector2i(0,0))
			else:
				tilemap.set_cell(tiles,1,Vector2i(0,0))
