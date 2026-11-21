class_name StripedDrawer
extends Object


static func draw_striped_body(
	canvas: CanvasItem,
	center: Vector2,
	half_size: Vector2,
	angle: float,
	body_color: Color,
	stripe_color: Color,
	stripes: int = 3
) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 16
	var cos_a: float = cos(angle)
	var sin_a: float = sin(angle)
	for i: int in range(segs):
		var t: float = TAU * float(i) / float(segs)
		var lx: float = cos(t) * half_size.x
		var ly: float = sin(t) * half_size.y
		var rx: float = lx * cos_a - ly * sin_a
		var ry: float = lx * sin_a + ly * cos_a
		pts.append(center + Vector2(rx, ry))
	canvas.draw_colored_polygon(pts, body_color)
	if stripes > 0 and half_size.x > 0.0:
		var line_w: float = maxf(1.2, (half_size.x * 2.0) / float(stripes * 2 + 2))
		for s: int in range(stripes):
			var frac: float = (float(s) + 1.0) / float(stripes + 1)
			var lx: float = lerpf(-half_size.x * 0.75, half_size.x * 0.75, frac)
			var ratio: float = clampf(lx / half_size.x, -0.99, 0.99)
			var ly: float = half_size.y * sqrt(maxf(0.0, 1.0 - ratio * ratio))
			var p1: Vector2 = center + Vector2(lx * cos_a - (-ly) * sin_a, lx * sin_a + (-ly) * cos_a)
			var p2: Vector2 = center + Vector2(lx * cos_a - ly * sin_a, lx * sin_a + ly * cos_a)
			canvas.draw_line(p1, p2, stripe_color, line_w)


static func draw_wings(
	canvas: CanvasItem,
	center: Vector2,
	wing_offset: Vector2,
	wing_size: Vector2,
	angle: float,
	wing_color: Color = Color(0.88, 0.95, 1.0, 0.6)
) -> void:
	var cos_a: float = cos(angle)
	var sin_a: float = sin(angle)
	for side: float in [-1.0, 1.0]:
		var local_c: Vector2 = Vector2(wing_offset.x, wing_offset.y * side)
		var world_c: Vector2 = center + Vector2(
			local_c.x * cos_a - local_c.y * sin_a,
			local_c.x * sin_a + local_c.y * cos_a
		)
		var pts: PackedVector2Array = PackedVector2Array()
		var segs: int = 10
		var wing_angle: float = angle + side * 0.35
		var wcos: float = cos(wing_angle)
		var wsin: float = sin(wing_angle)
		for i: int in range(segs):
			var t: float = TAU * float(i) / float(segs)
			var lx: float = cos(t) * wing_size.x
			var ly: float = sin(t) * wing_size.y
			pts.append(world_c + Vector2(lx * wcos - ly * wsin, lx * wsin + ly * wcos))
		canvas.draw_colored_polygon(pts, wing_color)
