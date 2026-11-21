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


func create_behavior() -> BuildingBehavior:
	return TowerBehavior.new()
