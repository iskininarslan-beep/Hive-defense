class_name StatModifiers
extends RefCounted

signal changed(key: StringName)

const TOWER_DAMAGE: StringName = &"tower_damage"
const TOWER_FIRE_RATE: StringName = &"tower_fire_rate"
const GATHER_AMOUNT: StringName = &"gather_amount"
const FACTORY_SPEED: StringName = &"factory_speed"
const WAVE_SIZE: StringName = &"wave_size"
const BEE_SPEED: StringName = &"bee_speed"
const BUILDING_HP: StringName = &"building_hp"
const APARTMENTS_CAP_BONUS: StringName = &"apartments_cap_bonus"
const TRAINING_SPEED: StringName = &"training_speed"
const ENEMY_POWER: StringName = &"enemy_power"
const ALLIED_HORNETS: StringName = &"allied_hornets_per_wave"
const QUEEN_REGEN: StringName = &"queen_regen"

var _values: Dictionary[StringName, float] = {}


func add(key: StringName, value: float) -> void:
	_values[key] = _values.get(key, 0.0) + value
	changed.emit(key)


func get_value(key: StringName) -> float:
	return _values.get(key, 0.0)


func multiplier(key: StringName) -> float:
	return maxf(0.05, 1.0 + get_value(key))
