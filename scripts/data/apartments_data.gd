class_name ApartmentsData
extends BuildingData

@export var cap_bonus: int = 6


func create_behavior() -> BuildingBehavior:
	return ApartmentsBehavior.new()
