class_name StorageBehavior
extends BuildingBehavior

var _applied: bool = false


func on_construction_completed() -> void:
	if _applied or _context == null:
		return
	var sd: StorageData = building.data as StorageData
	if sd != null:
		for t: GameEnums.ResourceType in [
			GameEnums.ResourceType.POLLEN,
			GameEnums.ResourceType.NECTAR,
			GameEnums.ResourceType.WAX,
			GameEnums.ResourceType.HONEY,
		]:
			_context.bank.add_capacity(t, sd.capacity)
		_applied = true


func on_removed() -> void:
	if not _applied or _context == null:
		return
	var sd: StorageData = building.data as StorageData
	if sd != null:
		for t: GameEnums.ResourceType in [
			GameEnums.ResourceType.POLLEN,
			GameEnums.ResourceType.NECTAR,
			GameEnums.ResourceType.WAX,
			GameEnums.ResourceType.HONEY,
		]:
			_context.bank.add_capacity(t, -sd.capacity)
		_applied = false


func get_status_text() -> String:
	return "Работает"
