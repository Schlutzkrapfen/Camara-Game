extends Node

enum GameState { BUILDING, RAIDING }
var curGameState: GameState = GameState.BUILDING
@export_category("General")
@export var cam: CameraController
@export var tilemap: FlowField
@export var main_tilemap:MainTileMap


@export_category("Raiding") 
@export var settlements: Array[PackedScene] 
var curSettlementIndex: int = 0
var curSettlement: Node2D
@export var goo_win_amount:Array[int]  = [20,20,40,100,140,200,200,200,
200,200,200,200,200,200,1000,1000,1000,1000,1000,1000,]

@export_category("Tutorial")
@export var tutorial_images: Array[Texture2D] = []

 
var _tutorial_layer: CanvasLayer
var _tutorial_picture: TextureRect
var _tutorial_index: int = 0
var _tutorial_was_paused: bool = false


# --- Inputs -------------------------------------------------------------------


@onready var btn_Tutorial: TextureButton = $"../UI/Margin2/Tutorial"
@onready var label_cookie_counter: Label = $"../UI/MarginContainer/TextureRect/Label"
@onready var rotate_output:AudioStreamPlayer =$"../Audiomanager/Rotate"
func _ready() -> void:

	btn_Tutorial.pressed.connect(func(): ShowTutorial())
	label_cookie_counter.text = str(Global.curGoo)

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("roration"):
		var rotations = Global.TileTransform.values()
		var index = rotations.find(Global.currentrotation)
		Global.currentrotation = rotations[(index + 1) % (rotations.size()-1)]
		rotate_output.play()


# --- Raids --------------------------------------------------------------------

func StopRaid() -> void:
	# curSettlementIndex += 1 evtl -> would even increase when the raid failed
	cam.locked = true;


var check_amount:float = 1
func check_if_finished() -> void:
	while get_tree().get_node_count_in_group("enemies") >= 1:
		await get_tree().create_timer(check_amount).timeout
	Global.curGoo += goo_win_amount[curSettlementIndex]
	label_cookie_counter.text = str(Global.curGoo)
	



func _input(event: InputEvent) -> void:
	if event.is_action_released("build_delete") or event.is_action_released("build_place"):
		label_cookie_counter.text = str(Global.curGoo)

func GameWon() -> void:
	print("You beat the entire game!")
	
	
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
