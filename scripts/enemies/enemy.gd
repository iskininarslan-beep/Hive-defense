class_name Enemy
extends Node2D

signal died(enemy: Enemy)
signal removed(enemy: Enemy)

@onready var health: HealthComponent = $Health

var data: EnemyData
var faction: GameEnums.Faction = GameEnums.Faction.HOSTILE
var is_breakthrough: bool = false

var _context: GameContext
var _visual: EnemyVisual
var _target_building: Building
var _target_enemy: Enemy
var _atk_timer: float = 0.0
var _slow_factor: float = 1.0
var _slow_timer: float = 0.0
var _emerging: bool = false
var _emerge_timer: float = 0.0
var _leaving: bool = false
var _leave_dir: Vector2 = Vector2.RIGHT
var _no_storage_steals: int = 0
var _facing: float = 0.0
var _ally_orbit_angle: float = 0.0
var _slot_angle_offset: float = 0.0
var _speed_mult: float = 1.0
var _dmg_mult: float = 1.0
var _hit_flash: float = 0.0
var _pulse_time: float = 0.0
var _last_hp: float = 0.0


func setup(p_data: EnemyData, p_context: GameContext, p_faction: GameEnums.Faction, hp_mult: float = 1.0) -> void:
	data = p_data
	_context = p_context
	faction = p_faction
	_ally_orbit_angle = randf() * TAU
	_slot_angle_offset = randf_range(-0.65, 0.65)
	health.setup(p_data.max_hp * hp_mult, 1.0)
	_last_hp = health.current
	health.died.connect(_on_health_died)
	health.health_changed.connect(_on_health_changed)

	if p_data.visual_script != null:
		var v: Node = p_data.visual_script.new()
		if v is EnemyVisual:
			_visual = v as EnemyVisual
			_visual.show_behind_parent = true
			_visual.visual_scale = p_data.visual_scale
			_visual.is_ally = (faction == GameEnums.Faction.ALLY)
			add_child(_visual)

	if p_data.emerge_time > 0.0 and faction == GameEnums.Faction.HOSTILE:
		_emerging = true
		_emerge_timer = p_data.emerge_time
		if _visual != null:
			_visual.emerging = true
			_visual.queue_redraw()


func setup_breakthrough() -> void:
	is_breakthrough = true
	health.damage_multiplier = 0.08
	_speed_mult = 2.2
	_dmg_mult = 5.0
	queue_redraw()


func is_targetable() -> bool:
	return not _emerging and not _leaving and not health.is_dead()


func is_leaving() -> bool:
	return _leaving


func get_layer() -> GameEnums.TargetLayer:
	return data.layer


func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, clampf(factor, 0.1, 1.0))
	_slow_timer = maxf(_slow_timer, duration)


func convert_to_ally() -> void:
	faction = GameEnums.Faction.ALLY
	_target_building = null
	_target_enemy = null
	if _visual != null:
		_visual.is_ally = true
		_visual.queue_redraw()


func leave_battlefield() -> void:
	if _leaving:
		return
	_leaving = true
	_leave_dir = (global_position - _get_queen_pos()).normalized()
	if _leave_dir.length_squared() < 0.01:
		_leave_dir = Vector2.RIGHT.rotated(randf() * TAU)


func _on_health_changed(current: float, _max_hp: float) -> void:
	if current < _last_hp:
		_hit_flash = 0.1
		if _context != null and _context.effects != null:
			_context.effects.spawn_burst(global_position, Color(1.0, 0.9, 0.6, 1.0), 3, 55.0)
	_last_hp = current
	queue_redraw()


func _process(delta: float) -> void:
	if data == null or _context == null:
		return
	_pulse_time += delta
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
		modulate = Color(1.8, 1.8, 1.8, modulate.a) if _hit_flash > 0.0 else Color(1.0, 1.0, 1.0, modulate.a)
	if is_breakthrough:
		queue_redraw()

	if _leaving:
		var leave_speed: float = maxf(data.speed * 2.2, 160.0)
		global_position += _leave_dir * leave_speed * delta
		_set_facing(_leave_dir.angle())
		modulate.a = maxf(0.0, modulate.a - delta * 0.9)
		if modulate.a <= 0.0 or global_position.distance_to(_get_queen_pos()) > 900.0:
			removed.emit(self)
			queue_free()
		return

	if _emerging:
		_emerge_timer -= delta
		if _emerge_timer <= 0.0:
			_emerging = false
			if _visual != null:
				_visual.emerging = false
				_visual.queue_redraw()
		return

	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

	_atk_timer = maxf(0.0, _atk_timer - delta)

	if faction == GameEnums.Faction.ALLY:
		_process_ally(delta)
	else:
		_process_hostile(delta)
		_apply_separation(delta)
	if _visual != null:
		_visual.step_anim(delta)


func _process_hostile(delta: float) -> void:
	if data.target_mode == GameEnums.EnemyTargetMode.STORAGE:
		_process_mole_cricket(delta)
		return

	var target: Building = _pick_building_target()
	if not is_instance_valid(target):
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	var atk_range: float = data.radius + target.get_hit_radius()
	var spd: float = data.speed * _speed_mult * _slow_factor
	if dist > atk_range:
		var move_dir: Vector2 = to_target
		if dist < atk_range * 2.8 and absf(_slot_angle_offset) > 0.05:
			var from_target: Vector2 = (global_position - target.global_position).normalized()
			var slot_pos: Vector2 = target.global_position + from_target.rotated(_slot_angle_offset * 0.45) * (atk_range * 0.9)
			move_dir = slot_pos - global_position
		_move_step(move_dir, move_dir.length(), spd, delta)
	else:
		_set_facing(to_target.angle())
		if _atk_timer <= 0.0:
			target.health.take_damage(data.damage * _dmg_mult)
			_atk_timer = data.attack_interval


func _apply_separation(delta: float) -> void:
	if _context == null or data == null:
		return
	var push: Vector2 = Vector2.ZERO
	var my_layer: GameEnums.TargetLayer = get_layer()
	for other: Enemy in _context.get_enemies():
		if other == self or other._emerging or other._leaving:
			continue
		if other.faction != faction or other.get_layer() != my_layer:
			continue
		var min_sep: float = (data.radius + other.data.radius) * 1.35
		var diff: Vector2 = global_position - other.global_position
		var d2: float = diff.length_squared()
		if d2 < min_sep * min_sep:
			var d: float = sqrt(d2)
			var dir: Vector2 = (diff / d) if d > 0.05 else Vector2.RIGHT.rotated(float(get_instance_id() % 360) * 0.01745)
			push += dir * ((min_sep - d) / maxf(1.0, min_sep))
	if push.length_squared() > 0.0001:
		var max_push: float = data.speed * _speed_mult * 0.85 * delta
		global_position += push.limit_length(1.0) * max_push


func _process_mole_cricket(delta: float) -> void:
	if not is_instance_valid(_target_building) or not (_target_building.data is StorageData) or _target_building.health.is_dead():
		_target_building = _find_nearest_storage()
	var spd: float = data.speed * _speed_mult * _slow_factor
	if is_instance_valid(_target_building):
		var diff: Vector2 = _target_building.global_position - global_position
		var dist: float = diff.length()
		if dist > data.radius + _target_building.get_hit_radius():
			_move_step(diff, dist, spd, delta)
		else:
			_set_facing(diff.angle())
			if _atk_timer <= 0.0:
				_target_building.health.take_damage(data.damage * _dmg_mult)
				_steal_random_resource()
				_atk_timer = data.attack_interval
	else:
		if _no_storage_steals >= 3:
			leave_battlefield()
			return
		var queen_pos: Vector2 = _get_queen_pos()
		var diff: Vector2 = queen_pos - global_position
		var dist: float = diff.length()
		var queen_hit: float = _context.queen.get_hit_radius() if is_instance_valid(_context.queen) else 40.0
		if dist > data.radius + queen_hit:
			_move_step(diff, dist, spd, delta)
		else:
			_set_facing(diff.angle())
			if _atk_timer <= 0.0:
				_steal_random_resource()
				_no_storage_steals += 1
				_atk_timer = data.attack_interval


func _steal_random_resource() -> void:
	var types: Array[GameEnums.ResourceType] = [
		GameEnums.ResourceType.POLLEN,
		GameEnums.ResourceType.NECTAR,
		GameEnums.ResourceType.WAX,
		GameEnums.ResourceType.HONEY,
	]
	types.shuffle()
	for rtype: GameEnums.ResourceType in types:
		if _context.bank.get_amount(rtype) > 0.0:
			_context.bank.remove_up_to(rtype, data.steal_amount)
			return


func _process_ally(delta: float) -> void:
	if not is_instance_valid(_target_enemy) or not _target_enemy.is_targetable() or _target_enemy.faction == GameEnums.Faction.ALLY:
		_target_enemy = _find_nearest_hostile_enemy()
	if is_instance_valid(_target_enemy):
		var diff: Vector2 = _target_enemy.global_position - global_position
		var dist: float = diff.length()
		if dist > data.radius + 16.0:
			_move_step(diff, dist, data.speed * 1.15, delta)
		else:
			_set_facing(diff.angle())
			if _atk_timer <= 0.0:
				_target_enemy.health.take_damage(data.damage)
				_atk_timer = data.attack_interval
	else:
		_ally_orbit_angle += delta * 1.2
		var orbit_pos: Vector2 = _get_queen_pos() + Vector2(cos(_ally_orbit_angle), sin(_ally_orbit_angle)) * 68.0
		var diff: Vector2 = orbit_pos - global_position
		var dist: float = diff.length()
		if dist > 4.0:
			_move_step(diff, dist, data.speed, delta)


func _pick_building_target() -> Building:
	if data.target_mode == GameEnums.EnemyTargetMode.QUEEN:
		return _context.queen
	if is_instance_valid(_target_building) and not _target_building.health.is_dead():
		return _target_building
	var best: Building = null
	var best_dist: float = INF
	for b: Building in _context.arena.get_buildings():
		if b.health.is_dead():
			continue
		var d: float = b.global_position.distance_squared_to(global_position)
		if d < best_dist:
			best_dist = d
			best = b
	_target_building = best
	return best


func _find_nearest_storage() -> Building:
	var best: Building = null
	var best_dist: float = INF
	for b: Building in _context.arena.get_buildings():
		if b.is_built and b.data is StorageData and not b.health.is_dead():
			var d: float = b.global_position.distance_squared_to(global_position)
			if d < best_dist:
				best_dist = d
				best = b
	return best


func _find_nearest_hostile_enemy() -> Enemy:
	var best: Enemy = null
	var best_dist: float = INF
	for enemy: Enemy in _context.get_hostile_enemies():
		var d: float = enemy.global_position.distance_squared_to(global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _move_step(diff: Vector2, dist: float, move_speed: float, delta: float) -> void:
	if dist <= 0.001:
		return
	global_position += diff / dist * minf(dist, move_speed * delta)
	_set_facing(diff.angle())


func _set_facing(angle: float) -> void:
	if absf(angle - _facing) > 0.02:
		_facing = angle
		if _visual != null:
			_visual.facing = angle
			_visual.queue_redraw()


func _get_queen_pos() -> Vector2:
	if is_instance_valid(_context.queen):
		return _context.queen.global_position
	if is_instance_valid(_context.arena):
		return _context.arena.global_position
	return Vector2.ZERO


func _on_health_died() -> void:
	if _context != null and _context.effects != null:
		_context.effects.spawn_burst(global_position, Color(0.95, 0.45, 0.2, 1.0), 10, 95.0)
	died.emit(self)
	removed.emit(self)
	queue_free()


func _draw() -> void:
	if _emerging or data == null or health == null:
		return
	if is_breakthrough:
		var aura_a: float = 0.6 + 0.3 * sin(_pulse_time * 8.0)
		draw_arc(Vector2.ZERO, data.radius + 5.0, 0.0, TAU, 24, Color(1.0, 0.12, 0.18, aura_a), 2.5)
	if health.current < health.max_health:
		var bar_w: float = maxf(20.0, data.radius * 2.0)
		var bar_h: float = 3.5
		var pos: Vector2 = Vector2(-bar_w * 0.5, -data.radius - 8.0)
		draw_rect(Rect2(pos, Vector2(bar_w, bar_h)), Color(0.1, 0.1, 0.1, 0.85))
		var bar_col: Color = Color(0.25, 0.9, 0.35, 0.95) if faction == GameEnums.Faction.ALLY else Color(0.95, 0.25, 0.2, 0.95)
		draw_rect(Rect2(pos, Vector2(bar_w * health.get_ratio(), bar_h)), bar_col)
