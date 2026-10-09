extends Sprite2D

@export var sprites: Array[Texture2D]

func _ready() -> void:
	if sprites != null:
		self.texture = sprites[randi_range(0, sprites.size() - 1)]
