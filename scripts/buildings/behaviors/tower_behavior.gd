class_name TowerBehavior
extends BuildingBehavior

var _aim_angle: float = 0.0
var _cooldown: float = 0.0
var _projectile_scene: PackedScene


func setup(p_building: Building, p_context: GameContext) -> void:
	super.setup(p_building, p_context)
	_projectile_scene = load("res://scenes/projectiles/projectile.tscn") as PackedScene


func _process(delta: float) -> void:
	if building == null or not building.is_built or _context == null:
		return
	var td: TowerData = building.data as TowerData
	if td == null:
		return
	var present: int = building.get_present_operators()
	if present <= 0:
		return
	var base_rate: float = _context.balance.upgrade_tower_rate_mult if _context.balance != null else 1.20
	var lvl_rate: float = base_rate if building.level >= 2 else 1.0
	var rate_mult: float = (float(present) / float(maxi(1, td.worker_slots))) * _context.modifiers.multiplier(StatModifiers.TOWER_FIRE_RATE) * lvl_rate
	_cooldown = maxf(0.0, _cooldown - delta * rate_mult)
	var target: Enemy = _find_target(td)
	if target != null:
		_aim_angle = (target.global_position - building.global_position).angle()
		queue_redraw()
		if _cooldown <= 0.0:
			_fire(td, target)
			_cooldown = td.fire_interval


func _find_target(td: TowerData) -> Enemy:
	var queen_pos: Vector2 = _get_queen_pos()
	var best: Enemy = null
	var best_queen_dist: float = INF
	for enemy: Enemy in _context.get_hostile_enemies():
		if td.target_layer != GameEnums.TargetLayer.BOTH and enemy.get_layer() != td.target_layer:
			continue
		if enemy.global_position.distance_to(building.global_position) > td.attack_range:
			continue
		var dq: float = enemy.global_position.distance_squared_to(queen_pos)
		if dq < best_queen_dist:
			best_queen_dist = dq
			best = enemy
	return best


func _fire(td: TowerData, target: Enemy) -> void:
	var base_dmg: float = _context.balance.upgrade_tower_damage_mult if _context.balance != null else 1.35
	var lvl_dmg: float = base_dmg if building.level >= 2 else 1.0
	var dmg: float = td.damage * _context.modifiers.multiplier(StatModifiers.TOWER_DAMAGE) * lvl_dmg
	if td.chain_count > 1:
		_fire_chain(td, target, dmg)
		return
	if _projectile_scene == null:
		return
	var proj: Projectile = _projectile_scene.instantiate() as Projectile
	_context.projectiles_root.add_child(proj)
	proj.global_position = building.global_position + Vector2(cos(_aim_angle), sin(_aim_angle)) * 12.0
	proj.setup(
		target,
		dmg,
		td.projectile_speed,
		td.splash_radius,
		td.slow_factor,
		td.slow_duration,
		td.target_layer,
		td.projectile_color,
		_context,
		_aim_angle
	)


func _fire_chain(td: TowerData, first_target: Enemy, dmg: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([building.global_position, first_target.global_position])
	var hit: Dictionary[Enemy, bool] = {first_target: true}
	first_target.health.take_damage(dmg)
	if _context.effects != null:
		_context.effects.spawn_burst(first_target.global_position, td.projectile_color, 5, 65.0)

	var prev: Enemy = first_target
	var hop_dmg: float = dmg * 0.75
	for _hop: int in range(td.chain_count - 1):
		var best: Enemy = null
		var best_dist: float = td.chain_range * td.chain_range
		for candidate: Enemy in _context.get_hostile_enemies():
			if hit.has(candidate):
				continue
			if td.target_layer != GameEnums.TargetLayer.BOTH and candidate.get_layer() != td.target_layer:
				continue
			var d2: float = prev.global_position.distance_squared_to(candidate.global_position)
			if d2 <= best_dist:
				best_dist = d2
				best = candidate
		if best == null:
			break
		hit[best] = true
		best.health.take_damage(hop_dmg)
		pts.append(best.global_position)
		if _context.effects != null:
			_context.effects.spawn_burst(best.global_position, td.projectile_color, 4, 55.0)
		prev = best

	if _context.effects != null:
		_context.effects.spawn_lightning(pts, td.projectile_color, 0.16)


func _get_queen_pos() -> Vector2:
	if is_instance_valid(_context.queen):
		return _context.queen.global_position
	if is_instance_valid(_context.arena):
		return _context.arena.global_position
	return Vector2.ZERO


func get_status_text() -> String:
	if building.desired_operators <= 0:
		return "Приостановлено"
	if building.get_present_operators() <= 0:
		return "Нет воинов"
	return "Работает"


func _draw() -> void:
	var td: TowerData = building.data as TowerData if building != null else null
	draw_set_transform(Vector2.ZERO, _aim_angle, Vector2.ONE)
	if td != null and td.chain_count > 1:
		# Tesla coil emitter prongs & crystal tip
		draw_line(Vector2.ZERO, Vector2(14.0, -4.0), Color(0.42, 0.48, 0.54, 1.0), 2.4)
		draw_line(Vector2.ZERO, Vector2(14.0, 4.0), Color(0.42, 0.48, 0.54, 1.0), 2.4)
		draw_circle(Vector2(14.5, 0.0), 4.2, Color(0.38, 0.92, 1.0, 0.95))
	elif td != null and td.splash_radius > 0.0:
		# Heavy honey mortar barrel
		draw_line(Vector2(-3.0, 0.0), Vector2(13.0, 0.0), Color(0.18, 0.13, 0.09, 1.0), 7.5)
		draw_line(Vector2(-2.0, 0.0), Vector2(12.0, 0.0), Color(0.55, 0.38, 0.16, 1.0), 4.5)
		draw_circle(Vector2(13.0, 0.0), 3.4, Color(1.0, 0.72, 0.14, 0.95))
	elif td != null and td.target_layer == GameEnums.TargetLayer.AIR:
		# Twin anti-air dart launcher
		draw_line(Vector2(-2.0, -3.5), Vector2(15.0, -3.5), Color(0.18, 0.26, 0.24, 1.0), 2.4)
		draw_line(Vector2(-2.0, 3.5), Vector2(15.0, 3.5), Color(0.18, 0.26, 0.24, 1.0), 2.4)
		draw_circle(Vector2(14.0, -3.5), 1.8, Color(0.5, 1.0, 0.85, 1.0))
		draw_circle(Vector2(14.0, 3.5), 1.8, Color(0.5, 1.0, 0.85, 1.0))
	elif td != null and td.target_layer == GameEnums.TargetLayer.BOTH:
		# Universal twin-resin amber blaster
		draw_line(Vector2(-2.0, -2.8), Vector2(15.0, -2.0), Color(0.24, 0.16, 0.08, 1.0), 2.6)
		draw_line(Vector2(-2.0, 2.8), Vector2(15.0, 2.0), Color(0.24, 0.16, 0.08, 1.0), 2.6)
		draw_circle(Vector2(14.5, 0.0), 3.0, td.projectile_color)
	else:
		# Crossbow ballista arms + bolt
		draw_arc(Vector2(2.0, 0.0), 11.0, -1.1, 1.1, 12, Color(0.45, 0.28, 0.12, 1.0), 2.8)
		draw_line(Vector2(7.0, -9.8), Vector2(0.0, 0.0), Color(0.88, 0.85, 0.78, 0.8), 1.2)
		draw_line(Vector2(7.0, 9.8), Vector2(0.0, 0.0), Color(0.88, 0.85, 0.78, 0.8), 1.2)
		draw_line(Vector2(-3.0, 0.0), Vector2(15.0, 0.0), Color(0.16, 0.12, 0.08, 1.0), 2.6)
		var tip: PackedVector2Array = PackedVector2Array([Vector2(17.5, 0.0), Vector2(12.5, -2.6), Vector2(12.5, 2.6)])
		draw_colored_polygon(tip, Color(0.95, 0.3, 0.25, 1.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if building != null and building.is_selected and td != null:
		draw_arc(Vector2.ZERO, td.attack_range, 0.0, TAU, 48, Color(0.45, 0.9, 1.0, 0.45), 1.5)
