class_name ResearchManager
extends Node

enum State {
	LOCKED,
	AVAILABLE,
	IN_PROGRESS,
	DONE,
}

signal research_started(data: ResearchData)
signal research_completed(data: ResearchData)
signal ending_unlocked(ending: GameEnums.Ending)

var _context: GameContext
var _all: Array[ResearchData] = []
var _by_id: Dictionary[StringName, ResearchData] = {}
var _completed: Dictionary[StringName, bool] = {}
var _current: ResearchData = null
var _progress: float = 0.0


func setup(context: GameContext, all_research: Array[ResearchData]) -> void:
	_context = context
	_all = all_research
	_by_id.clear()
	for r: ResearchData in _all:
		_by_id[r.id] = r


func get_all() -> Array[ResearchData]:
	return _all


func is_completed(id: StringName) -> bool:
	if id == &"":
		return true
	return _completed.get(id, false)


func get_current() -> ResearchData:
	return _current


func get_progress_ratio() -> float:
	if _current == null or _current.time <= 0.0:
		return 0.0
	return clampf(_progress / _current.time, 0.0, 1.0)


func _has_prerequisites(data: ResearchData) -> bool:
	if data.prerequisites.is_empty():
		return true
	if data.any_prerequisite:
		for req: String in data.prerequisites:
			if is_completed(StringName(req)):
				return true
		return false
	for req: String in data.prerequisites:
		if not is_completed(StringName(req)):
			return false
	return true


func get_state(data: ResearchData) -> State:
	if is_completed(data.id):
		return State.DONE
	if _current == data:
		return State.IN_PROGRESS
	if not _has_prerequisites(data):
		return State.LOCKED
	return State.AVAILABLE


func get_block_reason(data: ResearchData) -> String:
	if is_completed(data.id):
		return "Уже изучено"
	if _current != null:
		return "Идёт исследование: %s" % _current.display_name
	if _context.arena.count_completed(&"lab") <= 0:
		return "Нужна Лаборатория"
	if not _has_prerequisites(data):
		var names: Array[String] = []
		for req: String in data.prerequisites:
			var req_id: StringName = StringName(req)
			var req_data: ResearchData = _by_id.get(req_id)
			names.append(req_data.display_name if req_data != null else req)
		if data.any_prerequisite:
			return "Нужно одно из: %s" % ", ".join(names)
		return "Требуется: %s" % ", ".join(names)
	if not _context.bank.can_afford(data.get_cost()):
		return "Недостаточно ресурсов"
	return ""


func can_start(data: ResearchData) -> bool:
	return get_block_reason(data).is_empty()


func start(data: ResearchData) -> bool:
	if not can_start(data):
		return false
	if not _context.bank.spend(data.get_cost()):
		return false
	_current = data
	_progress = 0.0
	research_started.emit(data)
	return true


func complete_current_instantly() -> void:
	if _current != null:
		_finish_current()


func _process(delta: float) -> void:
	if _current == null or _context == null:
		return
	if _context.arena.count_completed(&"lab") <= 0:
		return
	_progress += delta
	if _progress >= _current.time:
		_finish_current()


func _finish_current() -> void:
	var finished: ResearchData = _current
	_current = null
	_progress = 0.0
	_completed[finished.id] = true
	var count: int = mini(finished.modifier_keys.size(), finished.modifier_values.size())
	for i: int in range(count):
		_context.modifiers.add(StringName(finished.modifier_keys[i]), finished.modifier_values[i])
	research_completed.emit(finished)
	if finished.ending != GameEnums.Ending.NONE:
		ending_unlocked.emit(finished.ending)
