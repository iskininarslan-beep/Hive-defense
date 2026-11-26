class_name SwarmFuryAbility
extends Ability

var _applied_bonus: float = 0.0


func _init() -> void:
	display_name = "Ярость роя"
	description = "Удваивает скорострельность всех башен на 15 секунд."
	icon = preload("res://assets/icons/ability_swarm_fury.svg")
	required_research = &"elite_regiment"
	cooldown = 90.0
	duration = 15.0
	effect_value = 1.0


func _on_activate() -> bool:
	if _context == null:
		return false
	_applied_bonus = effect_value if effect_value > 0.0 else 1.0
	_context.modifiers.add(StatModifiers.TOWER_FIRE_RATE, _applied_bonus)
	return true


func _on_deactivate() -> void:
	if _context == null:
		return
	_context.modifiers.add(StatModifiers.TOWER_FIRE_RATE, -_applied_bonus)
	_applied_bonus = 0.0
