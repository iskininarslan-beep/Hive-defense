class_name GatherBehavior
extends BuildingBehavior


func _process(_delta: float) -> void:
	if building == null or not building.is_built or _context == null:
		return
	var gd: GatherData = building.data as GatherData
	if gd == null:
		return
	for bee: Bee in building.operators:
		if not is_instance_valid(bee):
			continue
		if not bee.trip_completed.is_connected(_on_bee_trip_completed):
			bee.trip_completed.connect(_on_bee_trip_completed)
		if bee.state == Bee.State.WORKING and _context.bank.has_space(gd.resource_type, 0.1):
			var flower_pos: Vector2 = _context.flower_field.get_nearest_flower(building.global_position, gd.resource_type)
			bee.start_trip(flower_pos, gd.collect_time)


func _on_bee_trip_completed(bee: Bee) -> void:
	if building == null or not building.is_built or _context == null:
		return
	if not building.operators.has(bee):
		return
	var gd: GatherData = building.data as GatherData
	if gd == null:
		return
	var lvl_mult: float = 1.45 if building.level >= 2 else 1.0
	var amount: float = gd.amount_per_trip * _context.modifiers.multiplier(StatModifiers.GATHER_AMOUNT) * lvl_mult
	var added: float = _context.bank.add(gd.resource_type, amount)
	if added > 0.5 and _context.effects != null:
		var col: Color = Color(1.0, 0.9, 0.3) if gd.resource_type == GameEnums.ResourceType.POLLEN else Color(1.0, 0.5, 0.8)
		_context.effects.spawn_floating_text(building.global_position + Vector2(0.0, -14.0), "+%d" % int(roundf(added)), col)


func get_status_text() -> String:
	var gd: GatherData = building.data as GatherData
	if building.operators.is_empty():
		return "Нет рабочих"
	if not _context.bank.has_space(gd.resource_type, 0.1):
		return "Склад полон"
	return "Работает"
