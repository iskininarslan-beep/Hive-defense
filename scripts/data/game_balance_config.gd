class_name GameBalanceConfig
extends Resource

@export_group("Economy")
@export var start_pollen: float = 50.0
@export var start_nectar: float = 50.0
@export var start_wax: float = 120.0
@export var start_honey: float = 50.0
@export var base_storage_capacity: float = 150.0
@export var comb_wax_cost: float = 5.0
@export var demolish_refund_ratio: float = 0.5

@export_group("Colony")
@export var base_bee_cap: int = 14
@export var initial_gatherers: int = 6
@export var initial_builders: int = 3
@export var initial_soldiers: int = 3
@export var bee_speed: float = 110.0
@export var retrain_duration: float = 2.0
@export var repair_hp_per_sec: float = 5.5
@export var combat_repair_hp_per_sec: float = 3.0
@export var apartments_base_cap_bonus: int = 6

@export_group("Upgrades")
@export var upgrade_hp_mult: float = 1.35
@export var upgrade_tower_damage_mult: float = 1.35
@export var upgrade_tower_rate_mult: float = 1.20
@export var upgrade_economy_output_mult: float = 1.45
@export var upgrade_min_wax_cost: float = 25.0
@export var upgrade_honey_surcharge: float = 20.0

@export_group("Waves")
@export var first_wave_delay: float = 55.0
@export var wave_interval: float = 65.0
@export var early_wave_wax_bonus: float = 15.0
@export var early_wave_honey_bonus: float = 10.0
@export var wave_hp_growth: float = 0.06
@export var breakthrough_delay: float = 12.0


func get_initial_resources() -> Dictionary[GameEnums.ResourceType, float]:
	return {
		GameEnums.ResourceType.POLLEN: start_pollen,
		GameEnums.ResourceType.NECTAR: start_nectar,
		GameEnums.ResourceType.WAX: start_wax,
		GameEnums.ResourceType.HONEY: start_honey,
	}
