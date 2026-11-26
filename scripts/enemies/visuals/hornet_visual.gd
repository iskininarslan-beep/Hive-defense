class_name HornetVisual
extends EnemyVisual


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var body_col: Color = _tint(Color(1.0, 0.56, 0.12, 1.0))
	var wing_w: float = 4.5 + sin(anim_time * 38.0) * 1.1
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-1.0, 6.0), Vector2(wing_w, 2.5), 0.0, Color(0.95, 0.92, 0.85, 0.58))
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(8.5, 4.5), 0.0, body_col, Color(0.12, 0.08, 0.05, 1.0), 3)
	draw_line(Vector2(7.5, -2.0), Vector2(11.0, -4.5), Color(0.15, 0.1, 0.08, 1.0), 1.2)
	draw_line(Vector2(7.5, 2.0), Vector2(11.0, 4.5), Color(0.15, 0.1, 0.08, 1.0), 1.2)
	var stinger: PackedVector2Array = PackedVector2Array([
		Vector2(-8.0, -2.0),
		Vector2(-12.5, 0.0),
		Vector2(-8.0, 2.0),
	])
	draw_colored_polygon(stinger, Color(0.15, 0.1, 0.08, 1.0))
