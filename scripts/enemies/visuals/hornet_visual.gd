class_name HornetVisual
extends EnemyVisual


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var body_col: Color = _tint(Color(1.0, 0.56, 0.12, 1.0))
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-1.0, 6.0), Vector2(4.5, 2.5), 0.0, Color(0.95, 0.92, 0.85, 0.55))
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(8.5, 4.5), 0.0, body_col, Color(0.12, 0.08, 0.05, 1.0), 3)
	var stinger: PackedVector2Array = PackedVector2Array([
		Vector2(-8.0, -2.0),
		Vector2(-12.5, 0.0),
		Vector2(-8.0, 2.0),
	])
	draw_colored_polygon(stinger, Color(0.15, 0.1, 0.08, 1.0))
