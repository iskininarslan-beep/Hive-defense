class_name HornetQueenVisual
extends EnemyVisual


func _draw() -> void:
	var pulse: float = 0.35 + 0.25 * sin(anim_time * 5.0)
	draw_arc(Vector2.ZERO, 16.0 * visual_scale, 0.0, TAU, 32, Color(0.95, 0.2, 0.25, pulse), 1.6)
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var wing_w: float = 5.4 + sin(anim_time * 32.0) * 1.1
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-1.0, 6.5), Vector2(wing_w, 2.8), -0.1, Color(1.0, 0.82, 0.55, 0.62))
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-4.5, 5.2), Vector2(wing_w * 0.78, 2.2), -0.45, Color(1.0, 0.75, 0.45, 0.48))
	var body_col: Color = _tint(Color(0.92, 0.22, 0.18, 1.0))
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(9.2, 5.0), 0.0, body_col, Color(0.14, 0.06, 0.06, 1.0), 3)
	var stinger: PackedVector2Array = PackedVector2Array([
		Vector2(-8.6, -2.2),
		Vector2(-14.2, 0.0),
		Vector2(-8.6, 2.2),
	])
	draw_colored_polygon(stinger, Color(0.15, 0.08, 0.08, 1.0))
	# Crimson-gold spiked boss crown
	var crown: PackedVector2Array = PackedVector2Array([
		Vector2(2.5, -4.5),
		Vector2(4.2, -9.2),
		Vector2(6.5, -5.5),
		Vector2(8.5, -9.8),
		Vector2(9.8, -4.5),
	])
	draw_colored_polygon(crown, Color(1.0, 0.85, 0.22, 1.0))
	draw_circle(Vector2(8.2, -1.8), 1.2, Color(1.0, 0.92, 0.25, 1.0))
	draw_circle(Vector2(8.2, 1.8), 1.2, Color(1.0, 0.92, 0.25, 1.0))
