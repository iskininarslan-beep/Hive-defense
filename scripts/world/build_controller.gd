class_name BuildController
extends Node2D

enum Mode {
	NONE,
	COMB,
	BUILD,
	DELETE,
}

const COMB_COST: float = 5.0

signal mode_changed(mode: Mode, data: BuildingData)
signal building_selected(b: Building)
signal message(text: String)
signal pause_toggle_requested

var mode: Mode = Mode.NONE
var build_data: BuildingData = null

var _context: GameContext
var _hover_cell: Vector2i = Vector2i.ZERO
var _selected_building: Building = null
var _painting_combs: bool = false


func setup(context: GameContext) -> void:
	_context = context
	_context.arena.building_removed.connect(_on_building_removed)


func start_build(data: BuildingData) -> void:
	if mode == Mode.BUILD and build_data == data:
		cancel()
		return
	mode = Mode.BUILD
	build_data = data
	_painting_combs = false
	mode_changed.emit(mode, build_data)
	queue_redraw()


func toggle_comb_mode() -> void:
	if mode == Mode.COMB:
		cancel()
	else:
		mode = Mode.COMB
		build_data = null
		_painting_combs = false
		mode_changed.emit(mode, null)
		queue_redraw()


func toggle_delete_mode() -> void:
	if mode == Mode.DELETE:
		cancel()
	else:
		mode = Mode.DELETE
		build_data = null
		_painting_combs = false
		mode_changed.emit(mode, null)
		queue_redraw()


func cancel() -> void:
	mode = Mode.NONE
	build_data = null
	_painting_combs = false
	mode_changed.emit(mode, null)
	queue_redraw()


func select_building(b: Building) -> void:
	if is_instance_valid(_selected_building):
		_selected_building.set_selected(false)
	_selected_building = b
	if is_instance_valid(_selected_building):
		_selected_building.set_selected(true)
	building_selected.emit(_selected_building)


func _process(_delta: float) -> void:
	if _context == null or _context.arena == null:
		return
	var new_cell: Vector2i = _context.arena.global_to_cell(get_global_mouse_position())
	if new_cell != _hover_cell:
		_hover_cell = new_cell
		if mode != Mode.NONE:
			queue_redraw()
	if _painting_combs:
		if mode != Mode.COMB or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_painting_combs = false
		elif _context.arena.can_place_comb(_hover_cell) and _context.bank.try_spend(GameEnums.ResourceType.WAX, _get_comb_cost()):
			_context.arena.place_comb(_hover_cell)
	elif mode != Mode.NONE:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _context == null or _context.arena == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_ev: InputEventKey = event as InputEventKey
		match key_ev.keycode:
			KEY_ESCAPE:
				if mode != Mode.NONE:
					cancel()
				else:
					select_building(null)
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				pause_toggle_requested.emit()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_painting_combs = false
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			if mode != Mode.NONE:
				cancel()
			else:
				select_building(null)
			get_viewport().set_input_as_handled()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_hover_cell = _context.arena.global_to_cell(get_global_mouse_position())
			_handle_left_click()
			get_viewport().set_input_as_handled()


func _handle_left_click() -> void:
	match mode:
		Mode.NONE:
			var b: Building = _context.arena.get_building_at(_hover_cell)
			select_building(b)
		Mode.COMB:
			_painting_combs = true
			if not _context.arena.can_place_comb(_hover_cell):
				if not _context.arena.has_comb(_hover_cell):
					message.emit("Стройте соты рядом с существующими")
				return
			if not _context.bank.try_spend(GameEnums.ResourceType.WAX, _get_comb_cost()):
				message.emit("Недостаточно воска")
				return
			_context.arena.place_comb(_hover_cell)
		Mode.BUILD:
			var err: String = _context.arena.can_place_building(_hover_cell, build_data)
			if not err.is_empty():
				message.emit(err)
				return
			var total_cost: Dictionary[GameEnums.ResourceType, float] = _get_total_build_cost(_hover_cell, build_data)
			if not _context.bank.spend(total_cost):
				message.emit("Недостаточно ресурсов")
				return
			var placed: Building = _context.arena.place_building(_hover_cell, build_data, false)
			select_building(placed)
			if build_data.max_count > 0 and _context.arena.count_all(build_data.id) >= build_data.max_count:
				cancel()
		Mode.DELETE:
			var b: Building = _context.arena.get_building_at(_hover_cell)
			if b == null:
				return
			demolish_building(b)


func demolish_building(b: Building) -> void:
	if not is_instance_valid(b) or b.data == null:
		return
	if b.data.id == &"queen":
		message.emit("Нельзя снести королеву!")
		return
	var refund_ratio: float = _context.balance.demolish_refund_ratio if _context != null and _context.balance != null else 0.5
	var cost: Dictionary[GameEnums.ResourceType, float] = b.data.get_cost()
	for type: GameEnums.ResourceType in cost.keys():
		_context.bank.add(type, cost[type] * refund_ratio)
	_context.arena.demolish(b)


func _get_comb_cost() -> float:
	if _context != null and _context.balance != null:
		return _context.balance.comb_wax_cost
	return COMB_COST


func _get_total_build_cost(_cell: Vector2i, data: BuildingData) -> Dictionary[GameEnums.ResourceType, float]:
	return data.get_cost()


func _on_building_removed(b: Building) -> void:
	if _selected_building == b:
		select_building(null)


func _is_hover_valid() -> bool:
	if not _context.arena.is_valid_cell(_hover_cell):
		return false
	match mode:
		Mode.COMB:
			return _context.arena.can_place_comb(_hover_cell) and _context.bank.has(GameEnums.ResourceType.WAX, _get_comb_cost())
		Mode.BUILD:
			if build_data == null or not _context.arena.can_place_building(_hover_cell, build_data).is_empty():
				return false
			return _context.bank.can_afford(_get_total_build_cost(_hover_cell, build_data))
		Mode.DELETE:
			var b: Building = _context.arena.get_building_at(_hover_cell)
			return b != null and b.data != null and b.data.id != &"queen"
	return false


func _draw() -> void:
	if mode == Mode.NONE or _context == null or _context.arena == null:
		return
	if not _context.arena.is_valid_cell(_hover_cell):
		return
	var valid: bool = _is_hover_valid()
	var col: Color = Color(0.25, 0.95, 0.35, 0.45) if valid else Color(0.95, 0.25, 0.25, 0.45)
	var center: Vector2 = _context.arena.cell_to_global(_hover_cell) - global_position
	if mode == Mode.BUILD and build_data != null:
		var fp: Array[Vector2i] = _context.arena.get_footprint(_hover_cell, build_data)
		var can_afford: bool = _context.bank.can_afford(_get_total_build_cost(_hover_cell, build_data))
		for fc: Vector2i in fp:
			var fc_center: Vector2 = _context.arena.cell_to_global(fc) - global_position
			var poly: PackedVector2Array = HexGrid.hex_corners(fc_center, _context.arena.hex_size - 2.0)
			var cell_ok: bool = _context.arena.is_valid_cell(fc) and _context.arena.has_comb(fc) and _context.arena.get_building_at(fc) == null and can_afford
			var cell_col: Color = Color(0.25, 0.95, 0.35, 0.45) if cell_ok else Color(0.95, 0.25, 0.25, 0.5)
			draw_colored_polygon(poly, cell_col)
			if not _context.arena.has_comb(fc):
				var pts: PackedVector2Array = poly.duplicate()
				pts.append(poly[0])
				draw_polyline(pts, Color(1.0, 0.65, 0.2, 0.9), 1.8)
		if build_data.icon != null:
			var icon_size: float = _context.arena.hex_size * (3.6 if build_data.footprint_radius >= 1 else 1.5)
			var rect: Rect2 = Rect2(center - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size)
			draw_texture_rect(build_data.icon, rect, false, Color(1.0, 1.0, 1.0, 0.6))
		if build_data is TowerData:
			var td: TowerData = build_data as TowerData
			draw_arc(center, td.attack_range, 0.0, TAU, 48, Color(0.45, 0.9, 1.0, 0.45), 1.5)
	else:
		var poly: PackedVector2Array = HexGrid.hex_corners(center, _context.arena.hex_size - 2.0)
		draw_colored_polygon(poly, col)
