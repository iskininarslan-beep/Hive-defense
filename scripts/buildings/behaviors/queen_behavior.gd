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
	if building != null and building.is_under_attack():
		return "Под атакой!"
	return "Работает"


func _draw() -> void:
	var under_atk: bool = building != null and building.is_under_attack()
	if under_atk:
		var atk_a: float = 0.38 + 0.35 * sin(_anim_time * 9.0)
		draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 40, Color(1.0, 0.22, 0.18, atk_a), 3.0)
	elif _context != null and _context.modifiers != null and _context.modifiers.get_value(StatModifiers.QUEEN_REGEN) > 0.0:
		var alpha: float = 0.28 + 0.22 * sin(_anim_time * 3.5)
		draw_arc(Vector2.ZERO, 39.0, 0.0, TAU, 36, Color(0.4, 1.0, 0.5, alpha), 2.5)
	else:
		var glow_a: float = 0.18 + 0.1 * sin(_anim_time * 2.4)
		draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 36, Color(1.0, 0.88, 0.35, glow_a), 2.0)

	var wing_w: float = 14.0 + sin(_anim_time * 26.0) * 2.0
	var rear_w: float = 10.5 + sin(_anim_time * 26.0 + 0.5) * 1.4
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-3.0, 19.0), Vector2(wing_w, 7.5), -0.35, Color(0.92, 0.97, 1.0, 0.72))
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-11.0, 14.0), Vector2(rear_w, 5.5), -0.7, Color(0.9, 0.95, 1.0, 0.55))

	# Thorax & Abdomen facing right gently bobbing
	var bob: float = sin(_anim_time * 2.5) * 1.1
	var body_center: Vector2 = Vector2(0.0, bob)
	StripedDrawer.draw_striped_body(self, body_center, Vector2(25.0, 15.5), 0.0, Color(1.0, 0.84, 0.18, 1.0), Color(0.14, 0.09, 0.04, 1.0), 3)

	# Cute dark eyes & golden-brown antennae
	draw_circle(body_center + Vector2(18.0, -5.0), 2.6, Color(0.12, 0.08, 0.04, 1.0))
	draw_circle(body_center + Vector2(18.0, 5.0), 2.6, Color(0.12, 0.08, 0.04, 1.0))
	draw_line(body_center + Vector2(22.0, -4.0), body_center + Vector2(29.0, -9.0), Color(0.14, 0.09, 0.04, 1.0), 1.8)
	draw_line(body_center + Vector2(22.0, 4.0), body_center + Vector2(29.0, 9.0), Color(0.14, 0.09, 0.04, 1.0), 1.8)

	# Royal Crown centered over queen's head/thorax
	var crown: PackedVector2Array = PackedVector2Array([
		body_center + Vector2(-4.0, -14.0),
		body_center + Vector2(-1.0, -27.0),
		body_center + Vector2(5.0, -19.0),
		body_center + Vector2(10.0, -30.0),
		body_center + Vector2(15.0, -19.0),
		body_center + Vector2(20.0, -27.0),
		body_center + Vector2(22.0, -13.0),
	])
	draw_colored_polygon(crown, Color(1.0, 0.94, 0.28, 1.0))
	var crown_line: PackedVector2Array = crown.duplicate()
	crown_line.append(crown[0])
	draw_polyline(crown_line, Color(0.18, 0.12, 0.05, 0.9), 1.6)
	draw_circle(body_center + Vector2(10.0, -20.0), 2.2, Color(0.95, 0.25, 0.2, 1.0))
