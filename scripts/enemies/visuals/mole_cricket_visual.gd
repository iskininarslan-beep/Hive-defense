class_name MoleCricketVisual
extends EnemyVisual


func _draw() -> void:
	if emerging:
		var pulse: float = 1.0 + 0.08 * sin(anim_time * 16.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual_scale * pulse, visual_scale * pulse))
		draw_circle(Vector2.ZERO, 13.5, Color(0.38, 0.24, 0.14, 0.92))
		draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, Color(0.75, 0.48, 0.22, 0.75), 1.8)
		draw_circle(Vector2(-4.0, -3.0), 4.0, Color(0.28, 0.17, 0.1, 0.95))
		draw_circle(Vector2(5.0, 2.0), 3.5, Color(0.48, 0.32, 0.18, 0.95))
		return
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var body_col: Color = _tint(Color(0.56, 0.36, 0.18, 1.0))
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(10.5, 5.5), 0.0, body_col, Color(0.32, 0.2, 0.1, 1.0), 3)
	var dig: float = sin(anim_time * 14.0) * 1.4
	for side: float in [-1.0, 1.0]:
		var claw: PackedVector2Array = PackedVector2Array([
			Vector2(8.0, side * 3.0),
			Vector2(14.0 + dig * side, side * 7.2),
			Vector2(11.0, side * 1.5),
		])
		draw_colored_polygon(claw, Color(0.78, 0.68, 0.52, 1.0))
