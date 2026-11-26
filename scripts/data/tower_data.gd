class_name TowerData
extends BuildingData

@export var target_layer: GameEnums.TargetLayer = GameEnums.TargetLayer.GROUND
@export var attack_range: float = 210.0
@export var damage: float = 22.0
@export var fire_interval: float = 1.1
@export var projectile_speed: float = 500.0
@export var splash_radius: float = 0.0
@export var slow_factor: float = 1.0
@export var slow_duration: float = 0.0
@export var chain_count: int = 1
@export var chain_range: float = 105.0
@export var projectile_color: Color = Color(1.0, 0.9, 0.4, 1.0)


func can_upgrade_level() -> bool:
	return true


func get_upgrade_summary(cfg: GameBalanceConfig) -> String:
	var hp_pct: int = int(roundf(((cfg.upgrade_hp_mult if cfg != null else 1.35) - 1.0) * 100.0))
	var dmg_pct: int = int(roundf(((cfg.upgrade_tower_damage_mult if cfg != null else 1.35) - 1.0) * 100.0))
	var rate_pct: int = int(roundf(((cfg.upgrade_tower_rate_mult if cfg != null else 1.20) - 1.0) * 100.0))
	return "+%d%% прочность, +%d%% урон, +%d%% скорость" % [hp_pct, dmg_pct, rate_pct]


func create_behavior() -> BuildingBehavior:
	return TowerBehavior.new()
