extends Node

@onready var btn_Conveyor: TextureButton = $"../UI/Margin/HBox/ConveyorBelt"
@onready var btn_Splitter: TextureButton = $"../UI/Margin/HBox/Splitter"
@onready var btn_Head: TextureButton = $"../UI/Margin/HBox/HeadFactory"
@onready var btn_Torso: TextureButton = $"../UI/Margin/HBox/TorsoFactory"
@onready var btn_Spike: TextureButton = $"../UI/Margin/HBox/SpikeFactory"
@onready var btn_Leg: TextureButton = $"../UI/Margin/HBox/LegFactory"
@onready var btn_Combiner: TextureButton = $"../UI/Margin/HBox/Combiner"
@onready var btn_Upgrader: TextureButton = $"../UI/Margin/HBox/Upgrader"
@onready var btn_Aliver: TextureButton = $"../UI/Margin/HBox/Aliver"
@onready var btn_Raid: TextureButton = $"../UI/Margin/HBox/RAID"

func _ready() -> void:
	btn_Conveyor.pressed.connect(func(): Global.current_house = 0)
	btn_Splitter.pressed.connect(func(): Global.current_house = 1)
	btn_Head.pressed.connect(func(): Global.current_house = 3)
	btn_Torso.pressed.connect(func(): Global.current_house = 0) # MISSING!
	btn_Spike.pressed.connect(func(): Global.current_house = 0) # MISSING!
	btn_Leg.pressed.connect(func(): Global.current_house = 0) # MISSING!
	btn_Combiner.pressed.connect(func(): Global.current_house = 4)
	btn_Upgrader.pressed.connect(func(): Global.current_house = 0) # MISSING!
	btn_Aliver.pressed.connect(func(): Global.current_house = 0) # MISSING!
	btn_Raid.pressed.connect(func(): print("RAAAAAAAAID"))
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Belt"):
		Global.current_house = 0
	if event.is_action_released("Splitter"):
		Global.current_house = 1
	if event.is_action_released("Goo_maker"):
		Global.current_house = 2
	if event.is_action_released("HeadFactory"):
		Global.current_house = 3
	if event.is_action_released("Combiner"):
		Global.current_house = 4
	if event.is_action_pressed("roration"):
		var rotations = Global.TileTransform.values()
		var index = rotations.find(Global.currentrotation)
		Global.currentrotation = rotations[(index + 1) % (rotations.size()-1)]
