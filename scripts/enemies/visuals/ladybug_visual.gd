class_name LadybugVisual
extends EnemyVisual


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	var leg_col: Color = Color(0.12, 0.1, 0.1, 0.95)
	for side: float in [-1.0, 1.0]:
		for i: int in range(3):
			var bx: float = lerpf(-5.0, 4.0, float(i) / 2.0)
			var swing: float = sin(anim_time * 9.0 + float(i) * 1.8 + (0.0 if side > 0.0 else PI)) * 1.8
			draw_line(Vector2(bx, side * 8.0), Vector2(bx + swing, side * 12.2), leg_col, 1.7)
	draw_circle(Vector2.ZERO, 10.8, Color(0.1, 0.08, 0.08, 0.95))
	draw_circle(Vector2.ZERO, 9.8, _tint(Color(0.88, 0.18, 0.16, 1.0)))
	draw_line(Vector2(-9.5, 0.0), Vector2(7.5, 0.0), Color(0.1, 0.08, 0.08, 0.9), 1.6)
	var spots: Array[Vector2] = [
		Vector2(-4.0, -4.5),
		Vector2(2.0, -5.0),
		Vector2(-4.0, 4.5),
		Vector2(2.0, 5.0),
		Vector2(-1.0, -2.0),
		Vector2(-1.0, 2.0),
	]
	for p: Vector2 in spots:
		draw_circle(p, 1.7, Color(0.1, 0.08, 0.08, 0.95))
	draw_circle(Vector2(9.2, 0.0), 4.2, Color(0.12, 0.1, 0.1, 1.0))
	draw_line(Vector2(12.0, -2.0), Vector2(15.0, -4.2), leg_col, 1.2)
	draw_line(Vector2(12.0, 2.0), Vector2(15.0, 4.2), leg_col, 1.2)
