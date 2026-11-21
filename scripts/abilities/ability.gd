class_name Ability
extends Node

signal state_changed

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var cooldown: float = 60.0
@export var duration: float = 0.0
@export var required_research: StringName = &""
@export var is_toggle: bool = false

var _context: GameContext
var _cooldown_left: float = 0.0
var _active_left: float = 0.0
var _active: bool = false


func setup(context: GameContext) -> void:
	_context = context


func is_unlocked() -> bool:
	if required_research == &"":
		return true
	return _context != null and _context.research != null and _context.research.is_completed(required_research)


func can_activate() -> bool:
	if not is_unlocked():
		return false
	if is_toggle:
		return true
	return _cooldown_left <= 0.0 and not _active


func activate() -> bool:
	if not can_activate():
		return false
	if is_toggle:
		_active = not _active
		if _active:
			_on_activate()
		else:
			_on_deactivate()
		state_changed.emit()
		return true
	if not _on_activate():
		return false
	_cooldown_left = cooldown
	if duration > 0.0:
		_active = true
		_active_left = duration
	state_changed.emit()
	return true


func get_cooldown_left() -> float:
	return maxf(0.0, _cooldown_left)


func get_active_left() -> float:
	return maxf(0.0, _active_left)


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if _active and not is_toggle and duration > 0.0:
		_active_left -= delta
		if _active_left <= 0.0:
			_active = false
			_active_left = 0.0
			_on_deactivate()
			state_changed.emit()


func _on_activate() -> bool:
	return true


func _on_deactivate() -> void:
	pass
