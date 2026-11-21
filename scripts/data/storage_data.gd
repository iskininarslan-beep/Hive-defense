class_name StorageData
extends BuildingData

@export var capacity: float = 150.0


func create_behavior() -> BuildingBehavior:
	return StorageBehavior.new()
