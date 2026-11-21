class_name Building
extends Node2D

signal completed(b: Building)
signal destroyed(b: Building)
signal upgraded(b: Building)

@onready var health: HealthComponent = $Health

var data: BuildingData
var cell: Vector2i = Vector2i.ZERO
var footprint: Array[Vector2i] = []
var is_built: bool = false
var progress: float = 0.0
var is_selected: bool = false
var level: int = 1
var operators: Array[Bee] = []
var builders: Array[Bee] = []
var behavior: BuildingBehavior

var _context: GameContext
var _hex_size: float = 22.0
var _base_max_hp: float = 100.0


func setup(
	p_data: BuildingData,
	p_cell: Vector2i,
	p_context: GameContext,
	instant: bool = false,
	hex_size: float = 22.0,
	p_footprint: Array[Vector2i] = []
) -> void:
	data = p_data
	cell = p_cell
	footprint = p_footprint.duplicate() if not p_footprint.is_empty() else [p_cell]
	_context = p_context
	_hex_size = hex_size
	_base_max_hp = data.max_hp
	level = 1

	var start_ratio: float = 1.0 if (instant or data.build_time <= 0.0) else 0.25
	var hp_mult: float = _context.modifiers.multiplier(StatModifiers.BUILDING_HP) if (_context != null and _context.modifiers != null) else 1.0
	health.setup(_base_max_hp * hp_mult, start_ratio)
	health.died.connect(_on_health_died)
	health.health_changed.connect(func(_c: float, _m: float) -> void: queue_redraw())
	if _context != null and _context.modifiers != null:
		_context.modifiers.changed.connect(_on_modifier_changed)

	behavior = data.create_behavior()
	if behavior != null:
		add_child(behavior)
		behavior.setup(self, _context)

	if instant or data.build_time <= 0.0:
		is_built = true
		progress = 1.0
		if behavior != null:
			behavior.on_construction_completed()
		completed.emit(self)
	else:
		is_built = false
		progress = 0.0
	queue_redraw()


func _on_modifier_changed(key: StringName) -> void:
	if key == StatModifiers.BUILDING_HP:
		_refresh_max_hp()


func _refresh_max_hp() -> void:
	if _context == null or _context.modifiers == null or health == null:
		return
	var lvl_mult: float = 1.35 if level >= 2 else 1.0
	var target_max: float = _base_max_hp * _context.modifiers.multiplier(StatModifiers.BUILDING_HP) * lvl_mult
	var gain: float = maxf(0.0, target_max - health.max_health)
	health.max_health = target_max
	if gain > 0.0:
		health.heal(gain * (1.0 if is_built else 0.25))
	queue_redraw()


func can_upgrade() -> bool:
	return is_built and level == 1 and (data is TowerData or data is FactoryData or data is GatherData)


func get_upgrade_cost() -> Dictionary[GameEnums.ResourceType, float]:
	var cost: Dictionary[GameEnums.ResourceType, float] = {}
	if data == null:
		return cost
	var base: Dictionary[GameEnums.ResourceType, float] = data.get_cost()
	for t: GameEnums.ResourceType in base.keys():
		var rounded: float = ceilf((base[t] * 0.5) / 5.0) * 5.0
		if rounded > 0.0:
			cost[t] = rounded
	cost[GameEnums.ResourceType.WAX] = maxf(25.0, cost.get(GameEnums.ResourceType.WAX, 0.0))
	cost[GameEnums.ResourceType.HONEY] = cost.get(GameEnums.ResourceType.HONEY, 0.0) + 20.0
	return cost


func upgrade() -> bool:
	if not can_upgrade() or _context == null:
		return false
	if not _context.bank.spend(get_upgrade_cost()):
		return false
	level = 2
	_refresh_max_hp()
	upgraded.emit(self)
	if _context.effects != null:
		_context.effects.spawn_burst(global_position, Color(1.0, 0.9, 0.3, 1.0), 12, 95.0)
	queue_redraw()
	return true


func get_hit_radius() -> float:
	if data == null:
		return _hex_size * 0.9
	return _hex_size * (0.9 + 1.75 * float(data.footprint_radius))


func get_hex_size() -> float:
	return _hex_size


func _process(delta: float) -> void:
	if data == null:
		return
	_prune_workers()
	if not is_built:
		var present: int = get_present_builders()
		if present > 0:
			var prev_p: float = progress
			progress = minf(1.0, progress + delta * float(present) / maxf(0.1, data.build_time))
			health.heal((progress - prev_p) * health.max_health * 0.75)
			queue_redraw()
			if progress >= 1.0:
				is_built = true
				_release_builders()
				if behavior != null:
					behavior.on_construction_completed()
				if _context != null and _context.effects != null:
					_context.effects.spawn_burst(global_position, Color(1.0, 0.85, 0.35, 1.0), 10, 80.0)
				completed.emit(self)
				queue_redraw()
	else:
		if health.current < health.max_health:
			var present_b: int = get_present_builders()
			if present_b > 0:
				health.heal(4.0 * float(present_b) * delta)
				if health.current >= health.max_health:
					_release_builders()
		elif not builders.is_empty():
			_release_builders()


func get_builder_demand() -> int:
	_prune_workers()
	if not is_built or health.current < health.max_health:
		return maxi(0, 3 - builders.size())
	return 0


func get_operator_demand() -> int:
	_prune_workers()
	if not is_built:
		return 0
	return maxi(0, data.worker_slots - operators.size())


func add_operator(bee: Bee) -> void:
	if not operators.has(bee):
		operators.append(bee)
	queue_redraw()


func add_builder(bee: Bee) -> void:
	if not builders.has(bee):
		builders.append(bee)
	queue_redraw()


func remove_worker(bee: Bee) -> void:
	operators.erase(bee)
	builders.erase(bee)
	queue_redraw()


func get_present_operators() -> int:
	_prune_workers()
	var count: int = 0
	for bee: Bee in operators:
		if bee.is_at_work():
			count += 1
	return count


func get_present_builders() -> int:
	_prune_workers()
	var count: int = 0
	for bee: Bee in builders:
		if bee.is_at_work():
			count += 1
	return count


func release_all_workers() -> void:
	for bee: Bee in operators:
		if is_instance_valid(bee):
			bee.release()
	operators.clear()
	_release_builders()
	queue_redraw()


func _release_builders() -> void:
	for bee: Bee in builders:
		if is_instance_valid(bee):
			bee.release()
	builders.clear()
	queue_redraw()


func get_status_text() -> String:
	if not is_built:
		return "Стройка: %d%%" % int(roundf(progress * 100.0))
	if behavior != null:
		return behavior.get_status_text()
	return "Работает"


func set_selected(selected: bool) -> void:
	is_selected = selected
	queue_redraw()
	if behavior != null:
		behavior.queue_redraw()


func remove_from_game() -> void:
	release_all_workers()
	if behavior != null:
		behavior.on_removed()
	queue_free()


func _on_health_died() -> void:
	destroyed.emit(self)


func _prune_workers() -> void:
	for i: int in range(operators.size() - 1, -1, -1):
		if not is_instance_valid(operators[i]) or operators[i].is_queued_for_deletion():
			operators.remove_at(i)
	for i: int in range(builders.size() - 1, -1, -1):
		if not is_instance_valid(builders[i]) or builders[i].is_queued_for_deletion():
			builders.remove_at(i)


func _draw() -> void:
	if data == null:
		return
	var fill_color: Color = data.color if is_built else data.color.darkened(0.45)
	var border_color: Color = Color(1.0, 0.95, 0.5, 1.0) if is_selected else Color(0.18, 0.14, 0.08, 0.9)
	var border_width: float = 2.5 if is_selected else 1.5

	for fc: Vector2i in footprint:
		var offset: Vector2 = HexGrid.axial_to_pixel(fc - cell, _hex_size)
		var poly: PackedVector2Array = HexGrid.hex_corners(offset, _hex_size - 2.0)
		draw_colored_polygon(poly, fill_color)
		var outline_pts: PackedVector2Array = poly.duplicate()
		outline_pts.append(poly[0])
		draw_polyline(outline_pts, border_color, border_width)

	if data.id != &"queen" and data.icon != null:
		var icon_size: float = _hex_size * (3.6 if data.footprint_radius >= 1 else 1.5)
		var icon_mod: Color = Color.WHITE if is_built else Color(0.85, 0.85, 0.85, 0.75)
		draw_texture_rect(data.icon, Rect2(-icon_size * 0.5, -icon_size * 0.5, icon_size, icon_size), false, icon_mod)

	if level >= 2:
		var c: Vector2 = Vector2(_hex_size * 0.48, -_hex_size * 0.48)
		var star: PackedVector2Array = PackedVector2Array([
			c + Vector2(0.0, -5.0),
			c + Vector2(4.0, 0.0),
			c + Vector2(0.0, 5.0),
			c + Vector2(-4.0, 0.0),
		])
		draw_colored_polygon(star, Color(1.0, 0.92, 0.25, 1.0))

	if not is_built:
		var arc_r: float = _hex_size * (1.8 if data.footprint_radius >= 1 else 0.65)
		draw_arc(Vector2.ZERO, arc_r, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color(0.95, 0.98, 0.55, 0.95), 3.0)

	if data.worker_slots > 0 and is_built:
		var present: int = get_present_operators()
		var start_x: float = -float(data.worker_slots - 1) * 4.0
		for i: int in range(data.worker_slots):
			var dot_pos: Vector2 = Vector2(start_x + float(i) * 8.0, _hex_size * 0.62)
			var dot_col: Color = Color(0.2, 0.95, 0.35, 1.0) if i < present else Color(0.2, 0.2, 0.2, 0.75)
			draw_circle(dot_pos, 2.4, dot_col)

	if health != null and health.current < health.max_health:
		var bar_w: float = 54.0 if data.footprint_radius >= 1 else 28.0
		var bar_h: float = 4.0
		var top_y: float = -_hex_size * (1.0 + 1.5 * float(data.footprint_radius)) - 6.0
		var bar_pos: Vector2 = Vector2(-bar_w * 0.5, top_y)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.1, 0.1, 0.1, 0.85))
		draw_rect(Rect2(bar_pos, Vector2(bar_w * health.get_ratio(), bar_h)), Color(0.25, 0.9, 0.3, 0.95))
