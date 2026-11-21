class_name MoleCricketVisual
extends EnemyVisual


func _draw() -> void:
	if emerging:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual_scale, visual_scale))
		draw_circle(Vector2.ZERO, 13.0, Color(0.38, 0.24, 0.14, 0.9))
		draw_circle(Vector2(-4.0, -3.0), 4.0, Color(0.28, 0.17, 0.1, 0.95))
		draw_circle(Vector2(5.0, 2.0), 3.5, Color(0.48, 0.32, 0.18, 0.95))
		return
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var body_col: Color = _tint(Color(0.56, 0.36, 0.18, 1.0))
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(10.5, 5.5), 0.0, body_col, Color(0.32, 0.2, 0.1, 1.0), 3)
	for side: float in [-1.0, 1.0]:
		var claw: PackedVector2Array = PackedVector2Array([
			Vector2(8.0, side * 3.0),
			Vector2(14.0, side * 7.0),
			Vector2(11.0, side * 1.5),
		])
		draw_colored_polygon(claw, Color(0.75, 0.65, 0.5, 1.0))
