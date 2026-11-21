class_name LadybugVisual
extends EnemyVisual


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, facing, Vector2(visual_scale, visual_scale))
	draw_circle(Vector2.ZERO, 10.5, _tint(Color(0.88, 0.18, 0.16, 1.0)))
	draw_line(Vector2(-10.0, 0.0), Vector2(8.0, 0.0), Color(0.1, 0.08, 0.08, 0.9), 1.5)
	var spots: Array[Vector2] = [
		Vector2(-4.0, -4.5),
		Vector2(2.0, -5.0),
		Vector2(-4.0, 4.5),
		Vector2(2.0, 5.0),
		Vector2(-1.0, -2.0),
		Vector2(-1.0, 2.0),
	]
	for p: Vector2 in spots:
		draw_circle(p, 1.8, Color(0.1, 0.08, 0.08, 0.95))
	draw_circle(Vector2(9.5, 0.0), 4.2, Color(0.12, 0.1, 0.1, 1.0))
