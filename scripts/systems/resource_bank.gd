class_name ResourceBank
extends Node

signal resources_changed(type: GameEnums.ResourceType, amount: float, capacity: float)

const DEFAULT_BASE_CAPACITY: float = 150.0

var _amounts: Dictionary[GameEnums.ResourceType, float] = {}
var _capacities: Dictionary[GameEnums.ResourceType, float] = {}


func setup(initial: Dictionary[GameEnums.ResourceType, float], base_capacity: float = DEFAULT_BASE_CAPACITY) -> void:
	_amounts.clear()
	_capacities.clear()
	var cap: float = maxf(1.0, base_capacity)
	for type: GameEnums.ResourceType in [
		GameEnums.ResourceType.POLLEN,
		GameEnums.ResourceType.NECTAR,
		GameEnums.ResourceType.WAX,
		GameEnums.ResourceType.HONEY,
	]:
		_capacities[type] = cap
		_amounts[type] = clampf(initial.get(type, 0.0), 0.0, cap)
		resources_changed.emit(type, _amounts[type], cap)


func get_amount(type: GameEnums.ResourceType) -> float:
	return _amounts.get(type, 0.0)


func get_capacity(type: GameEnums.ResourceType) -> float:
	return _capacities.get(type, 0.0)


func has_space(type: GameEnums.ResourceType, amount: float = 0.01) -> bool:
	return get_amount(type) + amount <= get_capacity(type) + 0.0001


func add(type: GameEnums.ResourceType, amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var current: float = get_amount(type)
	var cap: float = get_capacity(type)
	var next: float = minf(cap, current + amount)
	var added: float = next - current
	_amounts[type] = next
	if added > 0.0:
		resources_changed.emit(type, next, cap)
	return added


func remove_up_to(type: GameEnums.ResourceType, amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var current: float = get_amount(type)
	var taken: float = minf(current, amount)
	if taken > 0.0:
		_amounts[type] = current - taken
		resources_changed.emit(type, _amounts[type], get_capacity(type))
	return taken


func has(type: GameEnums.ResourceType, amount: float) -> bool:
	return get_amount(type) + 0.0001 >= amount


func can_afford(cost: Dictionary[GameEnums.ResourceType, float]) -> bool:
	for type: GameEnums.ResourceType in cost.keys():
		if not has(type, cost[type]):
			return false
	return true


func spend(cost: Dictionary[GameEnums.ResourceType, float]) -> bool:
	if not can_afford(cost):
		return false
	for type: GameEnums.ResourceType in cost.keys():
		var amt: float = cost[type]
		if amt > 0.0:
			_amounts[type] = maxf(0.0, get_amount(type) - amt)
			resources_changed.emit(type, _amounts[type], get_capacity(type))
	return true


func try_spend(type: GameEnums.ResourceType, amount: float) -> bool:
	if not has(type, amount):
		return false
	_amounts[type] = maxf(0.0, get_amount(type) - amount)
	resources_changed.emit(type, _amounts[type], get_capacity(type))
	return true


func add_capacity(type: GameEnums.ResourceType, delta: float) -> void:
	var cap: float = maxf(0.0, get_capacity(type) + delta)
	_capacities[type] = cap
	_amounts[type] = minf(get_amount(type), cap)
	resources_changed.emit(type, _amounts[type], cap)
