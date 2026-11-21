class_name FactoryData
extends BuildingData

@export var input_type: GameEnums.ResourceType = GameEnums.ResourceType.POLLEN
@export var input_amount: float = 2.0
@export var output_type: GameEnums.ResourceType = GameEnums.ResourceType.WAX
@export var output_amount: float = 1.0
@export var cycle_time: float = 2.0


func create_behavior() -> BuildingBehavior:
	return FactoryBehavior.new()
