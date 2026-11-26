class_name ResearchData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var branch: GameEnums.ResearchBranch = GameEnums.ResearchBranch.MILITARY
@export var tier: int = 0
@export var prerequisites: PackedStringArray = PackedStringArray()
@export var any_prerequisite: bool = false
@export var icon: Texture2D
@export var sort_order: int = 100

@export_group("Cost")
@export var cost_pollen: float = 0.0
@export var cost_nectar: float = 0.0
@export var cost_wax: float = 0.0
@export var cost_honey: float = 0.0
@export var time: float = 20.0

@export_group("Effects")
@export var modifier_keys: PackedStringArray = PackedStringArray()
@export var modifier_values: PackedFloat32Array = PackedFloat32Array()
@export var ending: GameEnums.Ending = GameEnums.Ending.NONE


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
