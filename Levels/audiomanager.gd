class_name AudioManager
extends Node
@export var buildstream:Dictionary[Global.factory_type,AudioStreamPlayer]
var build: bool = false

# Called when the node enters the scene tree for the first time.
func stop_build():
	await get_tree().create_timer(0.5).timeout 
	build = false

func _ready() -> void:
	pass # Replace with function body.
func _play_build(factory_type:Global.factory_type):
	buildstream[factory_type].play()
	build = true
	stop_build()
	
func play_failed_build():
	pass
	#if build == false:
	#	$no_Build.play()
	#	stop_build()
	#build = true
