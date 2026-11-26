class_name FactoryData
extends BuildingData

@export var input_type: GameEnums.ResourceType = GameEnums.ResourceType.POLLEN
@export var input_amount: float = 2.0
@export var output_type: GameEnums.ResourceType = GameEnums.ResourceType.WAX
@export var output_amount: float = 1.0
@export var cycle_time: float = 2.0


func can_upgrade_level() -> bool:
	return true


func get_upgrade_summary(cfg: GameBalanceConfig) -> String:
	var hp_pct: int = int(roundf(((cfg.upgrade_hp_mult if cfg != null else 1.35) - 1.0) * 100.0))
	var out_pct: int = int(roundf(((cfg.upgrade_economy_output_mult if cfg != null else 1.45) - 1.0) * 100.0))
	return "+%d%% прочность, +%d%% выпуск" % [hp_pct, out_pct]


func create_behavior() -> BuildingBehavior:
	return FactoryBehavior.new()
