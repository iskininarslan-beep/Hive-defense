class_name EnemyData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var layer: GameEnums.TargetLayer = GameEnums.TargetLayer.AIR
@export var max_hp: float = 40.0
@export var speed: float = 75.0
@export var damage: float = 6.0
@export var attack_interval: float = 1.0
@export var target_mode: GameEnums.EnemyTargetMode = GameEnums.EnemyTargetMode.QUEEN
@export var radius: float = 9.0
@export var visual_script: Script
@export var visual_scale: float = 1.0
@export var emerge_time: float = 0.0
@export var steal_amount: float = 0.0
