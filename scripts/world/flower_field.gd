class_name FlowerField
extends Node2D


class FlowerSpot extends RefCounted:
	var pos: Vector2
	var type: GameEnums.ResourceType

	func _init(p_pos: Vector2, p_type: GameEnums.ResourceType) -> void:
		pos = p_pos
		type = p_type


class DecorPatch extends RefCounted:
	var pos: Vector2
	var radius: float
	var color: Color
	var kind: int # 0 = grass patch, 1 = clover, 2 = pebble
	var rot: float

	func _init(p_pos: Vector2, p_radius: float, p_color: Color, p_kind: int, p_rot: float = 0.0) -> void:
		pos = p_pos
		radius = p_radius
		color = p_color
		kind = p_kind
		rot = p_rot


const FLOWER_COUNT: int = 10
const RING_RADIUS: float = 330.0

var _flowers: Array[FlowerSpot] = []
var _decor: Array[DecorPatch] = []
var _sway_time: float = 0.0
var _redraw_accum: float = 0.0


func _ready() -> void:
	_generate_decor()
	_generate_flowers()
	queue_redraw()


func _generate_decor() -> void:
	_decor.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261126
	# Soft low-contrast grass clearings around the hive
	for i: int in range(18):
		var a: float = float(i) * TAU / 18.0 + rng.randf_range(-0.15, 0.15)
		var r: float = rng.randf_range(295.0, 520.0)
		var pos: Vector2 = Vector2(cos(a), sin(a)) * r
		var col: Color = Color(0.14, 0.27, 0.21, 0.65) if i % 2 == 0 else Color(0.16, 0.30, 0.22, 0.55)
		_decor.append(DecorPatch.new(pos, rng.randf_range(38.0, 74.0), col, 0))
	# Decorative clover clusters (subtle background meadow, no dark stroke)
	for i: int in range(28):
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = rng.randf_range(285.0, 540.0)
		var pos: Vector2 = Vector2(cos(a), sin(a)) * r
		_decor.append(DecorPatch.new(pos, rng.randf_range(5.0, 8.5), Color(0.20, 0.40, 0.25, 0.55), 1, rng.randf() * TAU))
	# Smooth meadow pebbles
	for i: int in range(18):
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = rng.randf_range(275.0, 490.0)
		var pos: Vector2 = Vector2(cos(a), sin(a)) * r
		_decor.append(DecorPatch.new(pos, rng.randf_range(4.0, 7.5), Color(0.32, 0.35, 0.32, 0.42), 2, rng.randf() * TAU))


func _generate_flowers() -> void:
	_flowers.clear()
	var angles_deg: Array[float] = [-54.0, -27.0, 0.0, 27.0, 54.0, 126.0, 153.0, 180.0, 207.0, 234.0]
	for i: int in range(angles_deg.size()):
		var angle: float = deg_to_rad(angles_deg[i])
		var local_pos: Vector2 = Vector2(cos(angle), sin(angle)) * RING_RADIUS
		var rtype: GameEnums.ResourceType = GameEnums.ResourceType.POLLEN if i % 2 == 0 else GameEnums.ResourceType.NECTAR
		_flowers.append(FlowerSpot.new(local_pos, rtype))


func get_nearest_flower(from_pos: Vector2, type: GameEnums.ResourceType) -> Vector2:
	var best_pos: Vector2 = from_pos
	var best_dist: float = INF
	for f: FlowerSpot in _flowers:
		if f.type != type:
			continue
		var gpos: Vector2 = to_global(f.pos)
		var d: float = gpos.distance_squared_to(from_pos)
		if d < best_dist:
			best_dist = d
			best_pos = gpos
	return best_pos


func _process(delta: float) -> void:
	_sway_time += delta
	_redraw_accum += delta
	if _redraw_accum >= 0.033:
		_redraw_accum = 0.0
		queue_redraw()


func _draw() -> void:
	# Ambient meadow glade ring around the hive
	draw_circle(Vector2.ZERO, 430.0, Color(0.13, 0.24, 0.20, 0.45))
	draw_circle(Vector2.ZERO, 315.0, Color(0.15, 0.26, 0.19, 0.40))

	for d: DecorPatch in _decor:
		if d.kind == 0:
			draw_circle(d.pos, d.radius, d.color)
		elif d.kind == 1:
			for k: int in range(3):
				var la: float = d.rot + float(k) * TAU / 3.0
				draw_circle(d.pos + Vector2(cos(la), sin(la)) * (d.radius * 0.55), d.radius * 0.55, d.color)
		else:
			draw_circle(d.pos, d.radius, d.color)

	for idx: int in range(_flowers.size()):
		var f: FlowerSpot = _flowers[idx]
		var base_pos: Vector2 = f.pos
		var sway: Vector2 = Vector2(sin(_sway_time * 1.8 + float(idx)) * 2.2, cos(_sway_time * 1.4 + float(idx)) * 1.2)
		var pos: Vector2 = base_pos + sway
		var is_pollen: bool = (f.type == GameEnums.ResourceType.POLLEN)
		var petal_col: Color = Color(1.0, 0.88, 0.2, 0.96) if is_pollen else Color(0.95, 0.45, 0.72, 0.96)
		var rim_col: Color = Color(0.16, 0.12, 0.07, 0.8)
		# Leaf rosette under interactive flower
		draw_circle(base_pos, 19.5, Color(0.18, 0.39, 0.21, 0.85))
		for leaf_i: int in range(4):
			var la: float = float(leaf_i) * PI * 0.5 + 0.4
			draw_circle(base_pos + Vector2(cos(la), sin(la)) * 14.0, 6.2, Color(0.22, 0.46, 0.24, 0.85))
		for i: int in range(6):
			var a: float = TAU * float(i) / 6.0 + sin(_sway_time * 1.2 + float(idx)) * 0.06
			var p_pos: Vector2 = pos + Vector2(cos(a), sin(a)) * 10.0
			draw_circle(p_pos, 6.0, rim_col)
			draw_circle(p_pos, 5.0, petal_col)
		draw_circle(pos, 5.6, rim_col)
		draw_circle(pos, 4.7, Color(0.96, 0.68, 0.16, 1.0) if not is_pollen else Color(0.58, 0.36, 0.10, 1.0))

	# Gentle sunlit pollen dust motes
	for m: int in range(14):
		var ma: float = float(m) * 0.45 + _sway_time * (0.12 + float(m % 3) * 0.04)
		var mr: float = 280.0 + float((m * 37) % 160)
		var mpos: Vector2 = Vector2(cos(ma), sin(ma)) * mr
		var malpha: float = 0.22 + 0.18 * sin(_sway_time * 2.1 + float(m))
		draw_circle(mpos, 2.0, Color(1.0, 0.92, 0.55, malpha))
