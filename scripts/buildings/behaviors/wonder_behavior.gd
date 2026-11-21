class_name WonderBehavior
extends BuildingBehavior


func get_status_text() -> String:
	return "Работает"


func _draw() -> void:
	draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.45, 0.65), 2.5)
	draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 40, Color(1.0, 0.85, 0.25, 0.35), 2.0)
