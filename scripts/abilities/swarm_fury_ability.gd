class_name SwarmFuryAbility
extends Ability


func _init() -> void:
	display_name = "Ярость роя"
	description = "Удваивает скорострельность всех башен на 15 секунд."
	icon = preload("res://assets/icons/ability_swarm_fury.svg")
	required_research = &"elite_regiment"
	cooldown = 90.0
	duration = 15.0


func _on_activate() -> bool:
	if _context == null:
		return false
	_context.modifiers.add(StatModifiers.TOWER_FIRE_RATE, 1.0)
	return true


func _on_deactivate() -> void:
	if _context == null:
		return
	_context.modifiers.add(StatModifiers.TOWER_FIRE_RATE, -1.0)
