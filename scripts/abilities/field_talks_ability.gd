class_name FieldTalksAbility
extends Ability


func _init() -> void:
	display_name = "Полевые переговоры"
	description = "Половина врагов (кроме босса) покидает поле боя."
	icon = preload("res://assets/icons/ability_field_talks.svg")
	required_research = &"field_talks"
	cooldown = 150.0


func _on_activate() -> bool:
	if _context == null:
		return false
	var candidates: Array[Enemy] = []
	for enemy: Enemy in _context.get_hostile_enemies():
		if enemy.data.id != &"hornet_queen" and not enemy.is_leaving():
			candidates.append(enemy)
	if candidates.is_empty():
		return false
	candidates.shuffle()
	var leave_count: int = maxi(1, floori(float(candidates.size()) * 0.5))
	for i: int in range(leave_count):
		candidates[i].leave_battlefield()
	return true
