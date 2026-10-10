extends Node
class_name GameManager

enum GameState { BUILDING, RAIDING }
var curGameState: GameState = GameState.BUILDING
@export_category("General")
@export var cam: CameraController
@export var tilemap: FlowField
@export var main_tilemap: MainTileMap
@export var soundManager: AudioManager



@export_category("Raiding") 
@export var settlements: Array[PackedScene] 
var curSettlementIndex: int = 0
var curSettlement: Node2D
@export var goo_win_amount:Array[int]  = [20,20,40,100,140,200,200,200,
200,200,200,200,200,200,1000,1000,1000,1000,1000,1000,]

@export_category("Tutorial")
@export var disable_shortcuts:bool = false
@export var level_res:LevelResource 
@export var tutorial_images: Array[Texture2D] = []
@export var start_first_raid_automatic:bool = false
var tutorial 
var _tutorial_layer: CanvasLayer
var _tutorial_picture: TextureRect
var _tutorial_index: int = 0
var _tutorial_was_paused: bool = false


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
@onready var btn_Tutorial: TextureButton = $"../UI/Margin2/Tutorial"
@onready var label_cookie_counter: Label = $"../UI/MarginContainer/TextureRect/Label"
@onready var rotate_output:AudioStreamPlayer =$"../Audiomanager/Rotate"
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
	btn_Tutorial.pressed.connect(func(): ShowTutorial())
	label_cookie_counter.text = str(Global.curGoo)
	for item in level_res.building.keys():
		main_tilemap.spawn_at_place_and_building(item,level_res.building[item])
	if start_first_raid_automatic:
		StartRaid()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("roration"):
		var rotations = Global.TileTransform.values()
		var index = rotations.find(Global.currentrotation)
		Global.currentrotation = rotations[(index + 1) % (rotations.size()-1)]
		rotate_output.play()
	if disable_shortcuts:
		return
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
	


# --- Raids --------------------------------------------------------------------

func StopRaid() -> void:
	# curSettlementIndex += 1 evtl -> would even increase when the raid failed
	cam.locked = true;


var check_amount:float = 1
func check_if_finished() -> void:
	while get_tree().get_node_count_in_group("enemies") >= 1:
		await get_tree().create_timer(check_amount).timeout
	btn_Raid.disabled = false
	Global.curGoo += goo_win_amount[curSettlementIndex]
	label_cookie_counter.text = str(Global.curGoo)
	

func StartRaid() -> void:
	btn_Raid.disabled = true
	if settlements == null:
		return
	if settlements.size() == curSettlementIndex:
		GameWon()
		return
	tilemap.remove_alive_items_flowfied()
	curGameState = GameState.RAIDING
	cam.locked = false;
	var newSettlement := settlements[curSettlementIndex].instantiate()
	self.add_child(newSettlement)
	check_if_finished()
	if curSettlement != null:
		curSettlement.queue_free()
	curSettlement = newSettlement
	curSettlementIndex += 1

func _input(event: InputEvent) -> void:
	if event.is_action_released("build_delete") or event.is_action_released("build_place"):
		label_cookie_counter.text = str(Global.curGoo)

func GameWon() -> void:
	print("You beat the entire game!")
	await soundManager.play_win_sound()
	get_tree().change_scene_to_packed(level_res.next_level)
	
# --- Tutorial -----------------------------------------------------------------
	
func ShowTutorial() -> void:
	if tutorial_images.is_empty() or _tutorial_layer != null:
		return

	_tutorial_index = 0
	_tutorial_was_paused = get_tree().paused
	get_tree().paused = true

	# Top-most layer that keeps running while the game is paused
	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 100
	_tutorial_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_tutorial_layer)

	# Full-screen dim background: blocks everything and acts as the "next page" click area
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_tutorial_gui_input)
	_tutorial_layer.add_child(backdrop)

	# The tutorial image (ignores the mouse so clicks fall through to the backdrop)
	_tutorial_picture = TextureRect.new()
	_tutorial_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tutorial_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tutorial_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(_tutorial_picture)

	# Close button (top right). Buttons consume their own clicks,
	# so pressing X won't also advance the page.
	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(50, 50)
	close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_button.position = Vector2(-70, 20)
	close_button.pressed.connect(_close_tutorial)
	backdrop.add_child(close_button)

	_tutorial_picture.texture = tutorial_images[_tutorial_index]


func _on_tutorial_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_next_tutorial_page()


func _next_tutorial_page() -> void:
	_tutorial_index += 1
	if _tutorial_index >= tutorial_images.size():
		_close_tutorial()
	else:
		_tutorial_picture.texture = tutorial_images[_tutorial_index]


func _close_tutorial() -> void:
	if _tutorial_layer:
		_tutorial_layer.queue_free()
		_tutorial_layer = null
	get_tree().paused = _tutorial_was_paused

func _tutorial_level() -> void:
	await soundManager.play_win_sound()
	get_tree().change_scene_to_packed(level_res.next_level)
