class_name AgitationAbility
extends Ability


func _init() -> void:
	display_name = "Агитация"
	description = "До 5 вражеских шершней переходят на нашу сторону."
	icon = preload("res://assets/icons/ability_agitation.svg")
	required_research = &"agitation"
	cooldown = 90.0


func _on_activate() -> bool:
	if _context == null:
		return false
	var converted: int = 0
	for enemy: Enemy in _context.get_hostile_enemies():
		if enemy.data.id == &"hornet":
			enemy.convert_to_ally()
			converted += 1
			if converted >= 5:
				break
	return converted > 0
