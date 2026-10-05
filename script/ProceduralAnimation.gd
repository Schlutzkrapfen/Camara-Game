extends Node2D

@export_group("Breathing")
@export var isBreathing: bool = false
@export var breathe_speed: float = 2.0
@export var breathe_amount: float = 0.05 # 5% scale expansion

@export_group("Bobbing")
@export var isBobbing: bool = false
@export var bob_speed: float = 3.0
@export var bob_height: float = 8.0 # Pixel offset

@export_group("Rotation")
@export var isRotating: bool = false
@export var rotation_speed: float = 1.5 # Radians per second

var time: float = 0.0
@onready var base_scale: Vector2 = scale
@onready var base_y: float = position.y

@onready var part := self.get_parent() as Creature

func _process(delta: float) -> void:
	if not part or not part.is_alive: 
		return
	time += delta
	
	# 1. Breathing (Scale)
	if isBreathing:
		var breathe_factor = sin(time * breathe_speed) * breathe_amount
		scale = base_scale + Vector2(breathe_factor, breathe_factor)
	
	# 2. Bobbing Up & Down (Oscillate Y position)
	if isBobbing:
		position.y = base_y + sin(time * bob_speed) * bob_height
	
	# 3. Continuous 360° Rotation
	if isRotating:
		rotation += rotation_speed * delta
