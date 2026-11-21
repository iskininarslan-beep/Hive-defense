class_name Arena
extends Node2D

signal building_placed(b: Building)
signal building_completed(b: Building)
signal building_removed(b: Building)
signal combs_changed(count: int, max_count: int)

@export var hex_size: float = 22.0
@export var arena_radius_px: float = 240.0
@export var building_scene: PackedScene

var _context: GameContext
var _valid_cells: Dictionary[Vector2i, bool] = {}
var _combs: Dictionary[Vector2i, bool] = {}
var _buildings: Dictionary[Vector2i, Building] = {}


func setup(context: GameContext) -> void:
	_context = context
	_valid_cells.clear()
	_combs.clear()
	_buildings.clear()
	for q: int in range(-14, 15):
		for r: int in range(-14, 15):
			var cell: Vector2i = Vector2i(q, r)
			if HexGrid.axial_to_pixel(cell, hex_size).length() <= arena_radius_px:
				_valid_cells[cell] = true
	queue_redraw()


func create_initial_base(datas_by_id: Dictionary[StringName, BuildingData]) -> void:
	for cell: Vector2i in _valid_cells.keys():
		if HexGrid.distance(cell, Vector2i.ZERO) <= 3:
			_combs[cell] = true
	combs_changed.emit(_combs.size(), _valid_cells.size())
	queue_redraw()

	if datas_by_id.has(&"queen"):
		_context.queen = place_building(Vector2i(0, 0), datas_by_id[&"queen"], true)
	if datas_by_id.has(&"pollen_post"):
		place_building(Vector2i(-2, 1), datas_by_id[&"pollen_post"], true)
	if datas_by_id.has(&"nectar_post"):
		place_building(Vector2i(2, -1), datas_by_id[&"nectar_post"], true)
	if datas_by_id.has(&"wax_factory"):
		place_building(Vector2i(0, 2), datas_by_id[&"wax_factory"], true)
	if datas_by_id.has(&"anti_air"):
		place_building(Vector2i(0, -2), datas_by_id[&"anti_air"], true)


func cell_to_global(cell: Vector2i) -> Vector2:
	return global_position + HexGrid.axial_to_pixel(cell, hex_size)


func global_to_cell(gpos: Vector2) -> Vector2i:
	return HexGrid.pixel_to_axial(gpos - global_position, hex_size)


func is_valid_cell(cell: Vector2i) -> bool:
	return _valid_cells.has(cell)


func has_comb(cell: Vector2i) -> bool:
	return _combs.has(cell)


func can_place_comb(cell: Vector2i) -> bool:
	if not is_valid_cell(cell) or has_comb(cell):
		return false
	for nb: Vector2i in HexGrid.get_neighbors(cell):
		if has_comb(nb):
			return true
	return false


func place_comb(cell: Vector2i) -> bool:
	if not is_valid_cell(cell) or has_comb(cell):
		return false
	_combs[cell] = true
	combs_changed.emit(_combs.size(), _valid_cells.size())
	queue_redraw()
	return true


func get_comb_count() -> int:
	return _combs.size()


func get_max_combs() -> int:
	return _valid_cells.size()


func get_footprint(cell: Vector2i, data: BuildingData) -> Array[Vector2i]:
	if data == null:
		return [cell]
	return HexGrid.get_footprint(cell, data.footprint_radius)


func get_missing_combs(cell: Vector2i, data: BuildingData) -> Array[Vector2i]:
	var missing: Array[Vector2i] = []
	for fc: Vector2i in get_footprint(cell, data):
		if not has_comb(fc):
			missing.append(fc)
	return missing


func can_place_building(cell: Vector2i, data: BuildingData) -> String:
	if data == null:
		return "Неизвестное здание"
	var fp: Array[Vector2i] = get_footprint(cell, data)
	var touches_comb: bool = false
	for fc: Vector2i in fp:
		if not is_valid_cell(fc):
			return "Вне зоны улья"
		if _buildings.has(fc) and is_instance_valid(_buildings[fc]) and not _buildings[fc].is_queued_for_deletion():
			return "Клетка уже занята"
		if has_comb(fc):
			touches_comb = true
		else:
			for nb: Vector2i in HexGrid.get_neighbors(fc):
				if has_comb(nb):
					touches_comb = true
					break
	if not touches_comb:
		return "Нужно строить рядом с сотами"
	if data.required_research != &"" and not _context.research.is_completed(data.required_research):
		return "Требуется исследование"
	if data.max_count > 0 and count_all(data.id) >= data.max_count:
		return "Достигнут предел: %d" % data.max_count
	return ""


func place_building(cell: Vector2i, data: BuildingData, instant: bool = false) -> Building:
	if building_scene == null:
		push_error("Arena: building_scene is not assigned")
		return null
	var fp: Array[Vector2i] = get_footprint(cell, data)
	for fc: Vector2i in get_missing_combs(cell, data):
		place_comb(fc)
	var b: Building = building_scene.instantiate() as Building
	_context.buildings_root.add_child(b)
	b.global_position = cell_to_global(cell)
	for fc: Vector2i in fp:
		_buildings[fc] = b
	b.completed.connect(_on_building_completed)
	b.destroyed.connect(_on_building_destroyed)
	b.setup(data, cell, _context, instant, hex_size, fp)
	building_placed.emit(b)
	return b


func demolish(b: Building) -> void:
	if not is_instance_valid(b):
		return
	var keys_to_erase: Array[Vector2i] = []
	for k: Vector2i in _buildings.keys():
		if _buildings[k] == b:
			keys_to_erase.append(k)
	for k: Vector2i in keys_to_erase:
		_buildings.erase(k)
	building_removed.emit(b)
	b.remove_from_game()


func get_buildings() -> Array[Building]:
	var result: Array[Building] = []
	var seen: Dictionary[Building, bool] = {}
	for cell: Vector2i in _buildings.keys():
		var b: Building = _buildings[cell]
		if is_instance_valid(b) and not b.is_queued_for_deletion() and not seen.has(b):
			seen[b] = true
			result.append(b)
	return result


func get_building_at(cell: Vector2i) -> Building:
	var b: Building = _buildings.get(cell)
	if is_instance_valid(b) and not b.is_queued_for_deletion():
		return b
	return null


func count_completed(id: StringName) -> int:
	var count: int = 0
	for b: Building in get_buildings():
		if b.is_built and b.data != null and b.data.id == id:
			count += 1
	return count


func count_all(id: StringName) -> int:
	var count: int = 0
	for b: Building in get_buildings():
		if b.data != null and b.data.id == id:
			count += 1
	return count


func _on_building_completed(b: Building) -> void:
	building_completed.emit(b)


func _on_building_destroyed(b: Building) -> void:
	demolish(b)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 255.0, Color(0.16, 0.12, 0.08, 0.92))
	draw_arc(Vector2.ZERO, 255.0, 0.0, TAU, 72, Color(0.42, 0.32, 0.16, 0.9), 3.0)

	for cell: Vector2i in _valid_cells.keys():
		var center: Vector2 = HexGrid.axial_to_pixel(cell, hex_size)
		var poly: PackedVector2Array = HexGrid.hex_corners(center, hex_size - 1.0)
		var line_pts: PackedVector2Array = poly.duplicate()
		line_pts.append(poly[0])
		if _combs.has(cell):
			draw_colored_polygon(poly, Color(0.72, 0.52, 0.18, 0.85))
			draw_polyline(line_pts, Color(0.92, 0.72, 0.28, 0.9), 1.4)
		else:
			draw_polyline(line_pts, Color(0.4, 0.34, 0.22, 0.28), 1.0)
