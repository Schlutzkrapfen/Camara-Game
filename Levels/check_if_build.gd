extends TileMapLayer

@export var main_tileset:TileMapLayer
@onready var tilemap:TileMapLayer = self

signal is_okay_to_build(bool)


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(_delta: float) -> void:#
	tilemap.clear()
	
	var mouse_pos = get_global_mouse_position()
	var tile = tilemap.local_to_map(tilemap.to_local(mouse_pos))
	if main_tileset.get_cell_tile_data(tile) == null:
		tilemap.set_cell(tile,0,Vector2i(0,0))
		emit_signal("is_okay_to_build",true)
	else:
		tilemap.set_cell(tile,1,Vector2i(0,0))
		emit_signal("is_okay_to_build",false)
