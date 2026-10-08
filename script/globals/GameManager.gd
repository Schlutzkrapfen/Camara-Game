extends Node
class_name GameManager

enum GameState { BUILDING, RAIDING }
var curGameState: GameState = GameState.BUILDING
@export_category("General")
@export var cam: CameraController

@export_category("Raiding") 
@export var settlements: Array[PackedScene] 
var curSettlementIndex: int = 0
var curSettlement: Node2D

# --- Inputs -------------------------------------------------------------------

@onready var btn_GooFactory: TextureButton = $"../UI/Margin/HBox/GooFactory"
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
	btn_GooFactory.pressed.connect(func(): Global.current_house = 0)
	btn_Conveyor.pressed.connect(func(): Global.current_house = 1)
	btn_Splitter.pressed.connect(func(): Global.current_house = 2)
	btn_Head.pressed.connect(func(): Global.current_house = 3)
	btn_Torso.pressed.connect(func():  Global.current_house = 4) 
	btn_Spike.pressed.connect(func(): Global.current_house = 5) 
	btn_Leg.pressed.connect(func(): Global.current_house = 6) 
	btn_Combiner.pressed.connect(func(): Global.current_house = 7)
	btn_Upgrader.pressed.connect(func(): Global.current_house = 8)
	btn_Aliver.pressed.connect(func(): Global.current_house = 9) 
	btn_Raid.pressed.connect(func(): StartRaid())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Goo_maker"):
		Global.current_house = 0
	if event.is_action_released("Belt"):
		Global.current_house = 1
	if event.is_action_released("Splitter"):
		Global.current_house = 2
	if event.is_action_released("HeadFactory"):
		Global.current_house = 3
	if event.is_action_released("Torso"):
		Global.current_house = 4
	if event.is_action_released("Spike"):
		Global.current_house = 5
	if event.is_action_released("Leg"):
		Global.current_house = 6
	if event.is_action_released("Combiner"):
		Global.current_house = 7
	if event.is_action_released("Upgrader"):
		Global.current_house = 8
	if event.is_action_released("Aliver"):
		Global.current_house = 9
	if event.is_action_pressed("roration"):
		var rotations = Global.TileTransform.values()
		var index = rotations.find(Global.currentrotation)
		Global.currentrotation = rotations[(index + 1) % (rotations.size()-1)]


# --- Raids --------------------------------------------------------------------

func StopRaid() -> void:
	# curSettlementIndex += 1 evtl -> would even increase when the raid failed
	cam.locked = true;

func StartRaid() -> void:
	if settlements == null:
		return
	if settlements.size() == curSettlementIndex:
		GameWon()
		return
	
	curGameState = GameState.RAIDING
	cam.locked = false;
	var newSettlement := settlements[curSettlementIndex].instantiate()
	self.add_child(newSettlement)
	if curSettlement != null:
		curSettlement.queue_free()
	curSettlement = newSettlement
	curSettlementIndex += 1
	# MISSING -> Set Producing Goo to ON!

func GameWon() -> void:
	print("You beat the entire game!")
