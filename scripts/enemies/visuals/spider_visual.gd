class_name SpiderVisual
extends EnemyVisual


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var leg_col: Color = _tint(Color(0.28, 0.16, 0.36, 1.0))
	for side: float in [-1.0, 1.0]:
		for i: int in range(4):
			var base_x: float = lerpf(-5.0, 5.0, float(i) / 3.0)
			var swing: float = sin(anim_time * 12.0 + float(i) * 1.4 + (0.0 if side > 0.0 else PI)) * 2.4
			var mid: Vector2 = Vector2(base_x * 1.4 + swing * 0.4, side * 10.0)
			var tip: Vector2 = Vector2(base_x * 2.0 + swing, side * 14.5)
			draw_line(Vector2(base_x, side * 4.0), mid, leg_col, 2.0)
			draw_line(mid, tip, leg_col, 1.5)
	draw_circle(Vector2(-2.5, 0.0), 8.5, _tint(Color(0.35, 0.18, 0.45, 1.0)))
	draw_circle(Vector2(-4.0, -2.0), 3.0, _tint(Color(0.48, 0.26, 0.60, 0.65)))
	draw_circle(Vector2(6.5, 0.0), 4.8, _tint(Color(0.24, 0.12, 0.32, 1.0)))
	draw_circle(Vector2(9.5, -2.0), 1.4, Color(1.0, 0.25, 0.25, 1.0))
	draw_circle(Vector2(9.5, 2.0), 1.4, Color(1.0, 0.25, 0.25, 1.0))
