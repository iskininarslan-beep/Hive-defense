class_name WonderBehavior
extends BuildingBehavior

var _anim_time: float = 0.0


func _process(delta: float) -> void:
	_anim_time += delta
	if building != null and building.is_built:
		queue_redraw()


func get_status_text() -> String:
	return "Сияет!"


func _draw() -> void:
	if building == null or not building.is_built:
		return
	var pulse: float = 0.55 + 0.35 * sin(_anim_time * 3.0)
	for i: int in range(8):
		var a: float = _anim_time * 0.6 + float(i) * TAU / 8.0
		var dir: Vector2 = Vector2(cos(a), sin(a))
		draw_line(dir * 32.0, dir * 56.0, Color(1.0, 0.92, 0.38, 0.32 * pulse), 2.5)
	draw_arc(Vector2.ZERO, 42.0 + sin(_anim_time * 2.5) * 2.0, 0.0, TAU, 44, Color(1.0, 0.95, 0.45, 0.72), 2.6)
	draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 44, Color(1.0, 0.85, 0.25, 0.42 * pulse), 2.0)
