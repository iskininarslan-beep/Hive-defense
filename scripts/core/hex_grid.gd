class_name HexGrid
extends Object

const SQRT3: float = 1.7320508075688772
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


static func axial_to_pixel(cell: Vector2i, size: float) -> Vector2:
	var x: float = size * SQRT3 * (float(cell.x) + float(cell.y) * 0.5)
	var y: float = size * 1.5 * float(cell.y)
	return Vector2(x, y)


static func pixel_to_axial(pos: Vector2, size: float) -> Vector2i:
	var q: float = (SQRT3 / 3.0 * pos.x - pos.y / 3.0) / size
	var r: float = (2.0 / 3.0 * pos.y) / size
	return _cube_round(q, r)


static func _cube_round(qf: float, rf: float) -> Vector2i:
	var sf: float = -qf - rf
	var rq: float = roundf(qf)
	var rr: float = roundf(rf)
	var rs: float = roundf(sf)
	var q_diff: float = absf(rq - qf)
	var r_diff: float = absf(rr - rf)
	var s_diff: float = absf(rs - sf)
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	return Vector2i(int(rq), int(rr))


static func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir: Vector2i in NEIGHBORS:
		result.append(cell + dir)
	return result


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = a.x - b.x
	var dr: int = a.y - b.y
	var ds: int = (-a.x - a.y) - (-b.x - b.y)
	return maxi(absi(dq), maxi(absi(dr), absi(ds)))


static func get_footprint(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for q: int in range(-radius, radius + 1):
		for r: int in range(-radius, radius + 1):
			if absi(q + r) <= radius:
				result.append(center + Vector2i(q, r))
	return result


static func hex_corners(center: Vector2, size: float) -> PackedVector2Array:
	var corners: PackedVector2Array = PackedVector2Array()
	for i: int in range(6):
		var angle_rad: float = deg_to_rad(60.0 * float(i) - 30.0)
		corners.append(center + Vector2(cos(angle_rad), sin(angle_rad)) * size)
	return corners
