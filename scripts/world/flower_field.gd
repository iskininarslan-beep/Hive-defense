class_name FlowerField
extends Node2D

const FLOWER_COUNT: int = 10
const RING_RADIUS: float = 330.0

var _flowers: Array[Dictionary] = []
var _sway_time: float = 0.0
var _redraw_accum: float = 0.0


func _ready() -> void:
	_generate_flowers()
	queue_redraw()


func _generate_flowers() -> void:
	_flowers.clear()
	var angles_deg: Array[float] = [-54.0, -27.0, 0.0, 27.0, 54.0, 126.0, 153.0, 180.0, 207.0, 234.0]
	for i: int in range(angles_deg.size()):
		var angle: float = deg_to_rad(angles_deg[i])
		var local_pos: Vector2 = Vector2(cos(angle), sin(angle)) * RING_RADIUS
		var rtype: GameEnums.ResourceType = GameEnums.ResourceType.POLLEN if i % 2 == 0 else GameEnums.ResourceType.NECTAR
		_flowers.append({"pos": local_pos, "type": rtype})


func get_nearest_flower(from_pos: Vector2, type: GameEnums.ResourceType) -> Vector2:
	var best_pos: Vector2 = from_pos
	var best_dist: float = INF
	for f: Dictionary in _flowers:
		if int(f["type"]) != int(type):
			continue
		var gpos: Vector2 = to_global(f["pos"] as Vector2)
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
	for idx: int in range(_flowers.size()):
		var f: Dictionary = _flowers[idx]
		var base_pos: Vector2 = f["pos"] as Vector2
		var sway: Vector2 = Vector2(sin(_sway_time * 1.8 + float(idx)) * 2.2, cos(_sway_time * 1.4 + float(idx)) * 1.2)
		var pos: Vector2 = base_pos + sway
		var type: int = int(f["type"])
		var petal_col: Color = Color(1.0, 0.88, 0.2, 0.95) if type == int(GameEnums.ResourceType.POLLEN) else Color(0.95, 0.45, 0.72, 0.95)
		draw_circle(base_pos, 18.0, Color(0.18, 0.36, 0.2, 0.75))
		for i: int in range(5):
			var a: float = TAU * float(i) / 5.0 + sin(_sway_time * 1.2 + float(idx)) * 0.06
			draw_circle(pos + Vector2(cos(a), sin(a)) * 9.5, 5.8, petal_col)
		draw_circle(pos, 5.2, Color(0.95, 0.65, 0.15, 1.0) if type == int(GameEnums.ResourceType.NECTAR) else Color(0.55, 0.35, 0.1, 1.0))
