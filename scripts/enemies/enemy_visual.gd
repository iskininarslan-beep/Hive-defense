class_name EnemyVisual
extends Node2D

var facing: float = 0.0
var is_ally: bool = false
var emerging: bool = false
var visual_scale: float = 1.0
var anim_time: float = 0.0


func step_anim(delta: float) -> void:
	anim_time += delta
	queue_redraw()


func _tint(base_color: Color) -> Color:
	if is_ally:
		return Color(0.25, 0.9, 0.38, base_color.a)
	return base_color
