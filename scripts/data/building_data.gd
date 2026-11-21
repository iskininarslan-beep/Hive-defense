class_name BuildingData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: GameEnums.BuildCategory = GameEnums.BuildCategory.ECONOMY
@export var icon: Texture2D
@export_range(0, 1) var footprint_radius: int = 0

@export_group("Cost")
@export var cost_pollen: float = 0.0
@export var cost_nectar: float = 0.0
@export var cost_wax: float = 0.0
@export var cost_honey: float = 0.0

@export_group("Stats")
@export var build_time: float = 8.0
@export var max_hp: float = 100.0
@export var color: Color = Color(0.85, 0.72, 0.25, 1.0)
@export var worker_role: GameEnums.BeeRole = GameEnums.BeeRole.NONE
@export var worker_slots: int = 0
@export var required_research: StringName = &""
@export var max_count: int = 0


func get_cost() -> Dictionary[GameEnums.ResourceType, float]:
	var cost: Dictionary[GameEnums.ResourceType, float] = {}
	if cost_pollen > 0.0:
		cost[GameEnums.ResourceType.POLLEN] = cost_pollen
	if cost_nectar > 0.0:
		cost[GameEnums.ResourceType.NECTAR] = cost_nectar
	if cost_wax > 0.0:
		cost[GameEnums.ResourceType.WAX] = cost_wax
	if cost_honey > 0.0:
		cost[GameEnums.ResourceType.HONEY] = cost_honey
	return cost


func create_behavior() -> BuildingBehavior:
	return null
