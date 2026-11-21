class_name GatherData
extends BuildingData

@export var resource_type: GameEnums.ResourceType = GameEnums.ResourceType.POLLEN
@export var amount_per_trip: float = 6.0
@export var collect_time: float = 1.5


func create_behavior() -> BuildingBehavior:
	return GatherBehavior.new()
