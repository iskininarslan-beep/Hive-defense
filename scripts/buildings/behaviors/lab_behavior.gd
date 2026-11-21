class_name LabBehavior
extends BuildingBehavior


func _process(_delta: float) -> void:
	if building != null and building.is_built and _context != null and _context.research != null:
		if _context.research.get_current() != null:
			queue_redraw()


func get_status_text() -> String:
	if _context != null and _context.research != null and _context.research.get_current() != null:
		return "Исследует"
	return "Работает"


func _draw() -> void:
	if building == null or not building.is_built or _context == null or _context.research == null:
		return
	if _context.research.get_current() != null:
		var ratio: float = _context.research.get_progress_ratio()
		var r: float = 2.4 * building.get_hex_size()
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.2, 0.55, 0.95, 0.25), 3.0)
		draw_arc(Vector2.ZERO, r, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, Color(0.45, 0.88, 1.0, 0.95), 4.0)
