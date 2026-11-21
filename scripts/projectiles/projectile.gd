class_name Projectile
extends Node2D

var _target: Enemy
var _last_target_pos: Vector2 = Vector2.ZERO
var _damage: float = 10.0
var _speed: float = 500.0
var _splash_radius: float = 0.0
var _slow_factor: float = 1.0
var _slow_duration: float = 0.0
var _layer: GameEnums.TargetLayer = GameEnums.TargetLayer.BOTH
var _color: Color = Color.YELLOW
var _context: GameContext
var _fan_angle: float = 0.0
var _fan_timer: float = 0.0
var _lifetime: float = 3.0
var _trail: PackedVector2Array = PackedVector2Array()


func setup(
	p_target: Enemy,
	p_damage: float,
	p_speed: float,
	p_splash_radius: float,
	p_slow_factor: float,
	p_slow_duration: float,
	p_layer: GameEnums.TargetLayer,
	p_color: Color,
	p_context: GameContext,
	p_initial_angle: float = 0.0
) -> void:
	_target = p_target
	_last_target_pos = p_target.global_position if is_instance_valid(p_target) else global_position
	_damage = p_damage
	_speed = p_speed
	_splash_radius = p_splash_radius
	_slow_factor = p_slow_factor
	_slow_duration = p_slow_duration
	_layer = p_layer
	_color = p_color
	_context = p_context
	_fan_angle = p_initial_angle
	_trail.clear()
	_trail.append(global_position)
	var direct_angle: float = (_last_target_pos - global_position).angle()
	_fan_timer = 0.12 if absf(angle_difference(direct_angle, p_initial_angle)) > 0.03 else 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return
	if is_instance_valid(_target) and _target.is_targetable():
		_last_target_pos = _target.global_position
	if _fan_timer > 0.0:
		_fan_timer -= delta
		global_position += Vector2(cos(_fan_angle), sin(_fan_angle)) * _speed * delta
	else:
		var diff: Vector2 = _last_target_pos - global_position
		var dist: float = diff.length()
		if dist <= 8.0 or dist <= _speed * delta:
			global_position = _last_target_pos
			_impact()
			return
		global_position += diff / dist * _speed * delta
	_trail.append(global_position)
	if _trail.size() > 5:
		_trail.remove_at(0)
	queue_redraw()


func _impact() -> void:
	if _context != null:
		if _splash_radius > 0.0:
			for enemy: Enemy in _context.get_hostile_enemies():
				if _layer != GameEnums.TargetLayer.BOTH and enemy.get_layer() != _layer:
					continue
				if enemy.global_position.distance_to(global_position) <= _splash_radius:
					enemy.health.take_damage(_damage)
					if _slow_duration > 0.0:
						enemy.apply_slow(_slow_factor, _slow_duration)
			if _context.effects != null:
				_context.effects.spawn_ring(global_position, _splash_radius, Color(1.0, 0.68, 0.12, 0.85), 1.6, 0.25)
				_context.effects.spawn_burst(global_position, _color, 7, 75.0)
		elif is_instance_valid(_target) and _target.is_targetable():
			_target.health.take_damage(_damage)
			if _slow_duration > 0.0:
				_target.apply_slow(_slow_factor, _slow_duration)
	queue_free()


func _draw() -> void:
	if _trail.size() >= 2:
		var local_pts: PackedVector2Array = PackedVector2Array()
		for gp: Vector2 in _trail:
			local_pts.append(gp - global_position)
		draw_polyline(local_pts, Color(_color.r, _color.g, _color.b, 0.45), 2.5)
	draw_circle(Vector2.ZERO, 3.5 if _splash_radius <= 0.0 else 5.0, _color)
