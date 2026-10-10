class_name AudioManager
extends Node
@export var buildstream:Dictionary[Global.factory_type,AudioStreamPlayer]
@onready var winscreen:AudioStreamPlayer =$Winsound
var build: bool = false

# Called when the node enters the scene tree for the first time.





func _play_build(factory_type: Global.factory_type) -> void:
	buildstream[factory_type].play()
	$Timer.start()

func play_failed_build() -> void:
	$no_Build.play()

func play_win_sound():
	winscreen.play()
	await winscreen.finished
	return true
