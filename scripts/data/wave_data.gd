class_name WaveData
extends Resource

@export var enemy_ids: PackedStringArray = PackedStringArray()
@export var enemy_counts: PackedInt32Array = PackedInt32Array()
@export var pattern: GameEnums.WavePattern = GameEnums.WavePattern.SCATTERED
@export var spawn_interval: float = 0.6
