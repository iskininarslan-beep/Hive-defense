class_name AbilityManager
extends Node

signal abilities_changed

var _context: GameContext
var _abilities: Array[Ability] = []


func setup(context: GameContext) -> void:
	_context = context
	_abilities.clear()
	for child: Node in get_children():
		if child is Ability:
			var ability: Ability = child as Ability
			ability.setup(_context)
			ability.state_changed.connect(func() -> void: abilities_changed.emit())
			_abilities.append(ability)
	_context.research.research_completed.connect(func(_d: ResearchData) -> void: abilities_changed.emit())
	abilities_changed.emit()


func get_available() -> Array[Ability]:
	var result: Array[Ability] = []
	for ability: Ability in _abilities:
		if ability.is_unlocked():
			result.append(ability)
	return result


func activate(ability: Ability) -> bool:
	if ability == null:
		return false
	var ok: bool = ability.activate()
	if ok:
		abilities_changed.emit()
	return ok
