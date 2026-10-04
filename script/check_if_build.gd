extends TileMapLayer

@export var main_tileset:TileMapLayer
@onready var tilemap:TileMapLayer = self

signal is_okay_to_build(bool)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func check_if_okay_to_build(tile)-> bool:
	for x in Global.factory_list[Global.current_house].size.x:
		for y in Global.factory_list[Global.current_house].size.y:
			var tiles = Vector2i(tile.x +x, tile.y+y)
			if main_tileset.get_cell_tile_data(tiles) != null:
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
			var tiles = Vector2i(tile.x +x, tile.y+y)
			if is_okay:
				tilemap.set_cell(tiles,0,Vector2i(0,0))
			else:
				tilemap.set_cell(tiles,1,Vector2i(0,0))
