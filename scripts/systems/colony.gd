class_name Colony
extends Node

signal population_changed(total: int, cap: int)
signal balance_changed(status: GameEnums.BalanceStatus)

const DEFAULT_BASE_CAP: int = 14
const ASSIGN_INTERVAL: float = 0.4

@export var bee_scene: PackedScene

var _context: GameContext
var _bees: Array[Bee] = []
var _assign_timer: float = 0.0


func setup(context: GameContext) -> void:
	_context = context
	_context.arena.building_completed.connect(_on_building_changed)
	_context.arena.building_removed.connect(_on_building_changed)
	_context.modifiers.changed.connect(_on_modifier_changed)
	_emit_population_and_balance()


func spawn_initial_bees() -> void:
	var queen_pos: Vector2 = _get_queen_pos()
	var g_count: int = _context.balance.initial_gatherers if _context.balance != null else 6
	var b_count: int = _context.balance.initial_builders if _context.balance != null else 3
	var s_count: int = _context.balance.initial_soldiers if _context.balance != null else 3
	for i: int in range(g_count):
		spawn_bee(GameEnums.BeeRole.GATHERER, queen_pos + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)))
	for i: int in range(b_count):
		spawn_bee(GameEnums.BeeRole.BUILDER, queen_pos + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)))
	for i: int in range(s_count):
		spawn_bee(GameEnums.BeeRole.SOLDIER, queen_pos + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)))


func spawn_bee(role: GameEnums.BeeRole, pos: Vector2) -> Bee:
	if bee_scene == null:
		push_error("Colony: bee_scene is not assigned")
		return null
	var bee: Bee = bee_scene.instantiate() as Bee
	_context.bees_root.add_child(bee)
	bee.global_position = pos
	bee.setup(role, _get_queen_pos(), _context)
	_bees.append(bee)
	_emit_population_and_balance()
	return bee


func get_cap() -> int:
	var base_cap: int = _context.balance.base_bee_cap if (_context != null and _context.balance != null) else DEFAULT_BASE_CAP
	if _context == null or _context.arena == null:
		return base_cap
	var apt_count: int = _context.arena.count_completed(&"apartments")
	var apt_base: int = _context.balance.apartments_base_cap_bonus if _context.balance != null else 6
	var bonus_each: int = int(roundf(_context.modifiers.get_value(StatModifiers.APARTMENTS_CAP_BONUS)))
	return maxi(1, base_cap + apt_count * (apt_base + bonus_each))


func get_count(role: GameEnums.BeeRole) -> int:
	_prune_bees()
	var count: int = 0
	for bee: Bee in _bees:
		if bee.get_effective_role() == role:
			count += 1
	return count


func get_retrainable_count(role: GameEnums.BeeRole) -> int:
	_prune_bees()
	var count: int = 0
	for bee: Bee in _bees:
		if bee.role == role and bee.state != Bee.State.RETRAINING:
			count += 1
	return count


func get_population() -> int:
	_prune_bees()
	return _bees.size()


func get_balance_status() -> GameEnums.BalanceStatus:
	var g: int = get_count(GameEnums.BeeRole.GATHERER)
	var s: int = get_count(GameEnums.BeeRole.SOLDIER)
	if g + s < 4:
		return GameEnums.BalanceStatus.BALANCED
	if (g == 0 and s >= 2) or (float(s) >= float(g) * 1.5 and (s - g) >= 3):
		return GameEnums.BalanceStatus.TOO_MANY_SOLDIERS
	if (s == 0 and g >= 3) or (float(g) >= float(s) * 2.0 and (g - s) >= 4):
		return GameEnums.BalanceStatus.TOO_MANY_GATHERERS
	return GameEnums.BalanceStatus.BALANCED


func retrain_bee(from_role: GameEnums.BeeRole, to_role: GameEnums.BeeRole) -> bool:
	if from_role == to_role or from_role == GameEnums.BeeRole.NONE or to_role == GameEnums.BeeRole.NONE:
		return false
	_prune_bees()
	var chosen: Bee = _pick_bee_to_retrain(from_role)
	if chosen == null:
		return false
	if is_instance_valid(chosen.assigned_building):
		chosen.assigned_building.remove_worker(chosen)
	if not chosen.retrained.is_connected(_on_bee_retrained):
		chosen.retrained.connect(_on_bee_retrained)
	var base_dur: float = _context.balance.retrain_duration if _context.balance != null else 2.0
	var dur: float = base_dur / _context.modifiers.multiplier(StatModifiers.TRAINING_SPEED)
	chosen.start_retrain(to_role, _get_queen_pos(), dur)
	_emit_population_and_balance()
	return true


func _pick_bee_to_retrain(from_role: GameEnums.BeeRole) -> Bee:
	for bee: Bee in _bees:
		if bee.role == from_role and bee.state == Bee.State.IDLE:
			return bee
	for bee: Bee in _bees:
		if bee.role == from_role and bee.state != Bee.State.RETRAINING and is_instance_valid(bee.assigned_building) and bee.assigned_building.is_work_stalled():
			return bee
	for bee: Bee in _bees:
		if bee.role == from_role and bee.state != Bee.State.RETRAINING and is_instance_valid(bee.assigned_building) and not (bee.assigned_building.data is TowerData):
			return bee
	for bee: Bee in _bees:
		if bee.role == from_role and bee.state != Bee.State.RETRAINING:
			return bee
	return null


func _on_bee_retrained(_bee: Bee, _new_role: GameEnums.BeeRole) -> void:
	_emit_population_and_balance()


func _on_building_changed(b: Building) -> void:
	if b != null and b.data != null and b.data.id == &"apartments":
		_emit_population_and_balance()


func _on_modifier_changed(key: StringName) -> void:
	if key == StatModifiers.APARTMENTS_CAP_BONUS:
		_emit_population_and_balance()


func _emit_population_and_balance() -> void:
	population_changed.emit(get_population(), get_cap())
	balance_changed.emit(get_balance_status())


func _process(delta: float) -> void:
	if _context == null:
		return
	_assign_timer -= delta
	if _assign_timer <= 0.0:
		_assign_timer = ASSIGN_INTERVAL
		_assign_idle_bees()


func trigger_assign_now() -> void:
	if _context == null:
		return
	_assign_timer = ASSIGN_INTERVAL
	_assign_idle_bees()


func _assign_idle_bees() -> void:
	_prune_bees()
	var buildings: Array[Building] = _context.arena.get_buildings()
	_assign_builders(buildings)
	_assign_operators(buildings)


func _assign_builders(buildings: Array[Building]) -> void:
	var unbuilt: Array[Building] = []
	var damaged: Array[Building] = []
	for b: Building in buildings:
		if not b.is_built:
			unbuilt.append(b)
		elif b.health.current < b.health.max_health:
			damaged.append(b)

	# 1. Construction blueprints take strict priority over routine repair
	for b: Building in unbuilt:
		var demand: int = b.get_builder_demand()
		while demand > 0:
			var builder: Bee = _find_closest_idle_bee(GameEnums.BeeRole.BUILDER, b.global_position)
			if builder == null and b.builders.size() < 2:
				builder = _reclaim_repair_builder(damaged)
			if builder == null:
				break
			b.add_builder(builder)
			builder.assign_to(b)
			demand -= 1

	# 2. Repair damaged buildings (Queen > Defense > Others)
	damaged.sort_custom(func(a: Building, b: Building) -> bool:
		return _repair_priority(a) < _repair_priority(b)
	)
	for b: Building in damaged:
		var demand: int = b.get_builder_demand()
		while demand > 0:
			var builder: Bee = _find_closest_idle_bee(GameEnums.BeeRole.BUILDER, b.global_position)
			if builder == null:
				break
			b.add_builder(builder)
			builder.assign_to(b)
			demand -= 1


func _reclaim_repair_builder(damaged: Array[Building]) -> Bee:
	var candidates: Array[Building] = damaged.duplicate()
	candidates.sort_custom(func(a: Building, b: Building) -> bool:
		return _repair_priority(a) > _repair_priority(b)
	)
	for donor: Building in candidates:
		if donor.data != null and donor.data.id == &"queen" and donor.builders.size() <= 1:
			continue
		if not donor.builders.is_empty():
			return donor.release_one_builder()
	return null


func _repair_priority(b: Building) -> int:
	if b.data != null and b.data.id == &"queen":
		return 0
	if b.data is TowerData:
		return 1
	return 2


func _assign_operators(buildings: Array[Building]) -> void:
	var active_need: Array[Building] = []
	var stalled_with_workers: Array[Building] = []
	for b: Building in buildings:
		if not b.is_built or b.data == null or b.data.worker_role == GameEnums.BeeRole.NONE:
			continue
		if b.is_work_stalled():
			if not b.operators.is_empty():
				stalled_with_workers.append(b)
		elif b.get_operator_demand() > 0:
			active_need.append(b)

	# Fairly fill active buildings with fewest current operators first
	while not active_need.is_empty():
		active_need.sort_custom(func(a: Building, b: Building) -> bool:
			return a.operators.size() < b.operators.size()
		)
		var assigned_any: bool = false
		for i: int in range(active_need.size() - 1, -1, -1):
			var b: Building = active_need[i]
			if b.get_operator_demand() <= 0:
				active_need.remove_at(i)
				continue
			var worker: Bee = _find_closest_idle_bee(b.data.worker_role, b.global_position)
			if worker == null:
				worker = _pull_stalled_operator(stalled_with_workers, b.data.worker_role)
			if worker != null:
				b.add_operator(worker)
				worker.assign_to(b)
				assigned_any = true
			if b.get_operator_demand() <= 0:
				active_need.remove_at(i)
		if not assigned_any:
			break


func _pull_stalled_operator(stalled_list: Array[Building], role: GameEnums.BeeRole) -> Bee:
	for donor: Building in stalled_list:
		if donor.data != null and donor.data.worker_role == role and not donor.operators.is_empty():
			return donor.release_one_operator()
	return null


func _find_closest_idle_bee(role: GameEnums.BeeRole, target_pos: Vector2) -> Bee:
	var best: Bee = null
	var best_dist: float = INF
	for bee: Bee in _bees:
		if bee.role != role:
			continue
		if bee.state != Bee.State.IDLE:
			continue
		if is_instance_valid(bee.assigned_building):
			continue
		var d: float = bee.global_position.distance_squared_to(target_pos)
		if d < best_dist:
			best_dist = d
			best = bee
	return best


func _prune_bees() -> void:
	for i: int in range(_bees.size() - 1, -1, -1):
		var bee: Bee = _bees[i]
		if not is_instance_valid(bee) or bee.is_queued_for_deletion():
			_bees.remove_at(i)


func _get_queen_pos() -> Vector2:
	if is_instance_valid(_context.queen):
		return _context.queen.global_position
	if is_instance_valid(_context.arena):
		return _context.arena.global_position
	return Vector2.ZERO
