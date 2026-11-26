class_name GatherData
extends BuildingData

@export var resource_type: GameEnums.ResourceType = GameEnums.ResourceType.POLLEN
@export var amount_per_trip: float = 6.0
@export var collect_time: float = 1.5


func can_upgrade_level() -> bool:
	return true


func get_upgrade_summary(cfg: GameBalanceConfig) -> String:
	var hp_pct: int = int(roundf(((cfg.upgrade_hp_mult if cfg != null else 1.35) - 1.0) * 100.0))
	var out_pct: int = int(roundf(((cfg.upgrade_economy_output_mult if cfg != null else 1.45) - 1.0) * 100.0))
	return "+%d%% прочность, +%d%% сбор" % [hp_pct, out_pct]


func create_behavior() -> BuildingBehavior:
	return GatherBehavior.new()
