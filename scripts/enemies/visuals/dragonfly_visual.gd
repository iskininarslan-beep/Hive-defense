class_name DragonflyVisual
extends EnemyVisual


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var body_col: Color = _tint(Color(0.22, 0.85, 0.95, 1.0))
	var w1: float = 5.5 + sin(anim_time * 42.0) * 1.4
	var w2: float = 5.0 + sin(anim_time * 42.0 + 1.2) * 1.2
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(2.0, 6.5), Vector2(w1, 2.0), 0.15, Color(0.75, 0.95, 1.0, 0.58))
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-3.0, 6.0), Vector2(w2, 1.8), -0.25, Color(0.75, 0.95, 1.0, 0.58))
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(11.0, 2.4), 0.0, body_col, Color(0.1, 0.35, 0.45, 1.0), 3)
	draw_circle(Vector2(10.0, 0.0), 2.8, _tint(Color(0.15, 0.65, 0.8, 1.0)))
	draw_circle(Vector2(11.5, -1.5), 1.1, Color(0.95, 0.95, 1.0, 0.9))
	draw_circle(Vector2(11.5, 1.5), 1.1, Color(0.95, 0.95, 1.0, 0.9))
