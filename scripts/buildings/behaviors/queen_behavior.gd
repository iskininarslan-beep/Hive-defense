class_name QueenBehavior
extends BuildingBehavior

var _anim_time: float = 0.0


func _process(delta: float) -> void:
	_anim_time += delta
	if building == null or not building.is_built or _context == null:
		return
	var regen: float = _context.modifiers.get_value(StatModifiers.QUEEN_REGEN)
	if regen > 0.0 and building.health.current < building.health.max_health:
		building.health.heal(regen * delta)
	queue_redraw()


func get_status_text() -> String:
	return "Работает"


func _draw() -> void:
	if _context != null and _context.modifiers != null and _context.modifiers.get_value(StatModifiers.QUEEN_REGEN) > 0.0:
		var alpha: float = 0.25 + 0.2 * sin(_anim_time * 3.5)
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 36, Color(0.4, 1.0, 0.5, alpha), 2.5)
	var wing_w: float = 13.0 + sin(_anim_time * 24.0) * 1.8
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-4.0, 18.0), Vector2(wing_w, 7.5), -0.3, Color(0.92, 0.97, 1.0, 0.7))
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(26.0, 16.0), 0.0, Color(1.0, 0.84, 0.18, 1.0), Color(0.15, 0.1, 0.05, 1.0), 3)
	var crown: PackedVector2Array = PackedVector2Array([
		Vector2(4.0, -14.0),
		Vector2(8.0, -27.0),
		Vector2(14.0, -19.0),
		Vector2(19.0, -29.0),
		Vector2(24.0, -19.0),
		Vector2(28.0, -25.0),
		Vector2(28.0, -12.0),
	])
	draw_colored_polygon(crown, Color(1.0, 0.95, 0.35, 1.0))
