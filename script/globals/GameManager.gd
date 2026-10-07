extends Node
class_name GameManager

enum GameState { BUILDING, RAIDING }
var curGameState: GameState = GameState.BUILDING
@export_category("General")
@export var cam: CameraController
@export var curGoo: int = 50
@export_category("Raiding") 
@export var settlements: Array[PackedScene] 
var curSettlementIndex: int = 0


# --- Inputs -------------------------------------------------------------------

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
	btn_Torso.pressed.connect(func(): print("MISSING PROPPER MAPPING! Fallback to conveyor belt!"); Global.current_house = 0) # MISSING!
	btn_Spike.pressed.connect(func(): print("MISSING PROPPER MAPPING! Fallback to conveyor belt!"); Global.current_house = 0) # MISSING!
	btn_Leg.pressed.connect(func(): print("MISSING PROPPER MAPPING! Fallback to conveyor belt!"); Global.current_house = 0) # MISSING!
	btn_Combiner.pressed.connect(func(): Global.current_house = 4)
	btn_Upgrader.pressed.connect(func(): Global.current_house = 5)
	btn_Aliver.pressed.connect(func(): print("MISSING PROPPER MAPPING! Fallback to conveyor belt!"); Global.current_house = 0) # MISSING!
	btn_Raid.pressed.connect(func(): StartRaid())

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
	if event.is_action_released("Upgrader"):
		Global.current_house = 5
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
	if settlements.size() < curSettlementIndex:
		GameWon()
		return
	
	curGameState = GameState.RAIDING
	cam.locked = false;
	var newSettlement = settlements[curSettlementIndex]
	get_tree().current_scene.add_child(newSettlement)
	curSettlementIndex += 1
	# MISSING -> Set Producing Goo to ON!

func GameWon() -> void:
	print("You beat the entire game!")
