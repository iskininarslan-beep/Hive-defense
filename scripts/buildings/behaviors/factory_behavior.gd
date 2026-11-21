class_name FactoryBehavior
extends BuildingBehavior

var _progress: float = 0.0


func _process(delta: float) -> void:
	if building == null or not building.is_built or _context == null:
		return
	var present: int = building.get_present_operators()
	if present <= 0:
		return
	var fd: FactoryData = building.data as FactoryData
	if fd == null:
		return
	if not _context.bank.has_space(fd.output_type, fd.output_amount):
		return
	if not _context.bank.has(fd.input_type, fd.input_amount):
		return
	var lvl_mult: float = 1.45 if building.level >= 2 else 1.0
	var speed_mult: float = _context.modifiers.multiplier(StatModifiers.FACTORY_SPEED) * lvl_mult
	_progress += delta * float(present) * speed_mult / maxf(0.1, fd.cycle_time)
	if _progress >= 1.0:
		if _context.bank.try_spend(fd.input_type, fd.input_amount):
			var added: float = _context.bank.add(fd.output_type, fd.output_amount)
			if added > 0.5 and _context.effects != null:
				var col: Color = Color(0.95, 0.72, 0.25) if fd.output_type == GameEnums.ResourceType.WAX else Color(1.0, 0.62, 0.15)
				_context.effects.spawn_floating_text(building.global_position + Vector2(0.0, -14.0), "+%d" % int(roundf(added)), col)
			_progress -= 1.0
		else:
			_progress = 1.0


func get_status_text() -> String:
	var fd: FactoryData = building.data as FactoryData
	if building.get_present_operators() <= 0:
		return "Нет рабочих"
	if not _context.bank.has_space(fd.output_type, fd.output_amount):
		return "Склад полон"
	if not _context.bank.has(fd.input_type, fd.input_amount):
		return "Нет сырья"
	return "Работает"
