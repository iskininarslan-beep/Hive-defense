class_name KindergartenData
extends BuildingData

@export var hatch_time: float = 8.0
@export var honey_cost: float = 10.0


func create_behavior() -> BuildingBehavior:
	return KindergartenBehavior.new()
