class_name HealthComponent
extends Node

signal health_changed(current: float, max_hp: float)
signal died

@export var max_health: float = 100.0
var current: float = 100.0
var damage_multiplier: float = 1.0


func _ready() -> void:
	current = max_health


func setup(p_max_health: float, start_ratio: float = 1.0) -> void:
	max_health = maxf(1.0, p_max_health)
	current = clampf(max_health * start_ratio, 0.0, max_health)
	health_changed.emit(current, max_health)


func take_damage(amount: float) -> void:
	if current <= 0.0 or amount <= 0.0:
		return
	current = maxf(0.0, current - amount * damage_multiplier)
	health_changed.emit(current, max_health)
	if current <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if current <= 0.0 or amount <= 0.0 or current >= max_health:
		return
	current = minf(max_health, current + amount)
	health_changed.emit(current, max_health)


func set_ratio(ratio: float) -> void:
	current = clampf(max_health * ratio, 0.0, max_health)
	health_changed.emit(current, max_health)


func is_dead() -> bool:
	return current <= 0.0


func get_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return clampf(current / max_health, 0.0, 1.0)
