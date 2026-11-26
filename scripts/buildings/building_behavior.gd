class_name BuildingBehavior
extends Node2D

var building: Building
var _context: GameContext


func setup(p_building: Building, p_context: GameContext) -> void:
	building = p_building
	_context = p_context


func on_construction_completed() -> void:
	pass


func on_removed() -> void:
	pass


func get_status_text() -> String:
	return "Работает"


func is_work_stalled() -> bool:
	return false
