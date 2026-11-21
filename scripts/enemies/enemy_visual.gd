class_name EnemyVisual
extends Node2D

var facing: float = 0.0
var is_ally: bool = false
var emerging: bool = false
var visual_scale: float = 1.0


func _tint(base_color: Color) -> Color:
	if is_ally:
		return Color(0.25, 0.9, 0.38, base_color.a)
	return base_color
