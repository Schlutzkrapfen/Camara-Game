class_name AttackEffect
extends Node2D

var radius: float = 100.0
var duration: float = 0.25
var color: Color = Color(1.0, 0.2, 0.2, 0.5)

func _ready() -> void:
	scale = Vector2.ZERO

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 1.0), 2.0)
