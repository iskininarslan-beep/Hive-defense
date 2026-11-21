class_name KindergartenBehavior
extends BuildingBehavior

var selected_role: GameEnums.BeeRole = GameEnums.BeeRole.GATHERER
var _hatching: bool = false
var _timer: float = 0.0


func set_role(role: GameEnums.BeeRole) -> void:
	if role in [GameEnums.BeeRole.GATHERER, GameEnums.BeeRole.BUILDER, GameEnums.BeeRole.SOLDIER]:
		selected_role = role


func _process(delta: float) -> void:
	if building == null or not building.is_built or _context == null:
		return
	var kd: KindergartenData = building.data as KindergartenData
	if kd == null:
		return
	if not _hatching:
		if _context.colony.get_population() >= _context.colony.get_cap():
			return
		if _context.bank.has(GameEnums.ResourceType.HONEY, kd.honey_cost):
			_context.bank.try_spend(GameEnums.ResourceType.HONEY, kd.honey_cost)
			_hatching = true
			_timer = 0.0
	else:
		var speed_mult: float = _context.modifiers.multiplier(StatModifiers.TRAINING_SPEED)
		_timer += delta * speed_mult
		if _timer >= kd.hatch_time:
			if _context.colony.get_population() < _context.colony.get_cap():
				_context.colony.spawn_bee(selected_role, building.global_position)
				if _context.effects != null:
					_context.effects.spawn_burst(building.global_position, Color(1.0, 0.9, 0.4, 1.0), 6, 65.0)
				_hatching = false
				_timer = 0.0
			else:
				_timer = kd.hatch_time


func get_status_text() -> String:
	if _hatching:
		return "Растит: %s" % GameEnums.role_name(selected_role)
	if _context.colony.get_population() >= _context.colony.get_cap():
		return "Предел пчёл"
	return "Нет сырья"
