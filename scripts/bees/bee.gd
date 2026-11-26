class_name Bee
extends Node2D

enum State {
	IDLE,
	TO_WORK,
	WORKING,
	TRIP_OUT,
	COLLECTING,
	TRIP_BACK,
	RETRAINING,
}

signal arrived
signal trip_completed(bee: Bee)
signal retrained(bee: Bee, new_role: GameEnums.BeeRole)

const SPEED: float = 110.0

var role: GameEnums.BeeRole = GameEnums.BeeRole.GATHERER
var state: State = State.IDLE
var assigned_building: Building = null

var _context: GameContext
var _home_pos: Vector2 = Vector2.ZERO
var _idle_target: Vector2 = Vector2.ZERO
var _trip_target: Vector2 = Vector2.ZERO
var _collect_time: float = 1.5
var _collect_timer: float = 0.0
var _facing: float = 0.0
var _anim_time: float = 0.0

var _retrain_role: GameEnums.BeeRole = GameEnums.BeeRole.NONE
var _retrain_target: Vector2 = Vector2.ZERO
var _retrain_timer: float = 0.0
var _retrain_at_queen: bool = false
var _orbit_angle: float = 0.0


func setup(p_role: GameEnums.BeeRole, p_home_pos: Vector2, p_context: GameContext = null) -> void:
	role = p_role
	_home_pos = p_home_pos
	_context = p_context
	_anim_time = randf() * 10.0
	state = State.IDLE
	_pick_idle_target()
	queue_redraw()


func get_effective_role() -> GameEnums.BeeRole:
	if state == State.RETRAINING and _retrain_role != GameEnums.BeeRole.NONE:
		return _retrain_role
	return role


func assign_to(building: Building) -> void:
	assigned_building = building
	state = State.TO_WORK


func release() -> void:
	assigned_building = null
	state = State.IDLE
	_pick_idle_target()


func start_trip(target: Vector2, collect_time: float) -> void:
	_trip_target = target
	_collect_time = collect_time
	state = State.TRIP_OUT


func start_retrain(new_role: GameEnums.BeeRole, queen_pos: Vector2, duration: float) -> void:
	assigned_building = null
	_retrain_role = new_role
	_retrain_target = queen_pos
	_retrain_timer = maxf(0.2, duration)
	_retrain_at_queen = false
	_orbit_angle = randf() * TAU
	state = State.RETRAINING


func is_at_work() -> bool:
	return state == State.WORKING


func _get_speed() -> float:
	var base: float = _context.balance.bee_speed if (_context != null and _context.balance != null) else SPEED
	if _context != null and _context.modifiers != null:
		return base * _context.modifiers.multiplier(StatModifiers.BEE_SPEED)
	return base


func _process(delta: float) -> void:
	_anim_time += delta
	var spd: float = _get_speed()
	match state:
		State.IDLE:
			if _move_toward(_idle_target, spd * 0.65, delta):
				_pick_idle_target()
		State.TO_WORK:
			if not is_instance_valid(assigned_building):
				release()
				return
			if _move_toward(assigned_building.global_position, spd, delta):
				state = State.WORKING
				arrived.emit()
		State.WORKING:
			if not is_instance_valid(assigned_building):
				release()
				return
			var slot_off: Vector2 = assigned_building.get_worker_slot_offset(self)
			var hover: Vector2 = Vector2(sin(_anim_time * 3.4) * 1.6, cos(_anim_time * 4.1) * 1.4)
			var desired_pos: Vector2 = assigned_building.global_position + slot_off + hover
			global_position = global_position.lerp(desired_pos, minf(1.0, delta * 10.0))
			queue_redraw()
		State.TRIP_OUT:
			if not is_instance_valid(assigned_building):
				release()
				return
			if _move_toward(_trip_target, spd, delta):
				state = State.COLLECTING
				_collect_timer = _collect_time
		State.COLLECTING:
			if not is_instance_valid(assigned_building):
				release()
				return
			_collect_timer -= delta
			global_position = _trip_target + Vector2(sin(_anim_time * 9.0) * 3.0, cos(_anim_time * 12.0) * 2.5)
			queue_redraw()
			if _collect_timer <= 0.0:
				state = State.TRIP_BACK
		State.TRIP_BACK:
			if not is_instance_valid(assigned_building):
				release()
				return
			if _move_toward(assigned_building.global_position, spd, delta):
				state = State.WORKING
				trip_completed.emit(self)
		State.RETRAINING:
			if not _retrain_at_queen:
				if _move_toward(_retrain_target, spd * 1.35, delta):
					_retrain_at_queen = true
			else:
				_orbit_angle += delta * 6.5
				global_position = _retrain_target + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * 18.0
				_facing = _orbit_angle + PI * 0.5
				_retrain_timer -= delta
				queue_redraw()
				if _retrain_timer <= 0.0:
					role = _retrain_role
					_retrain_role = GameEnums.BeeRole.NONE
					_retrain_at_queen = false
					state = State.IDLE
					_pick_idle_target()
					if _context != null and _context.effects != null:
						_context.effects.spawn_burst(global_position, Color(1.0, 0.9, 0.35, 1.0), 8, 70.0)
					retrained.emit(self, role)


func _move_toward(target: Vector2, move_speed: float, delta: float) -> bool:
	var diff: Vector2 = target - global_position
	var dist: float = diff.length()
	if dist <= 4.0:
		global_position = target
		return true
	_facing = diff.angle()
	global_position += diff / dist * minf(dist, move_speed * delta)
	queue_redraw()
	return false


func _pick_idle_target() -> void:
	var a: float = randf() * TAU
	var r: float = randf_range(22.0, 56.0)
	_idle_target = _home_pos + Vector2(cos(a), sin(a)) * r


func _get_body_color() -> Color:
	match role:
		GameEnums.BeeRole.GATHERER:
			return Color(1.0, 0.85, 0.15, 1.0)
		GameEnums.BeeRole.BUILDER:
			return Color(1.0, 0.55, 0.12, 1.0)
		GameEnums.BeeRole.SOLDIER:
			return Color(0.95, 0.25, 0.2, 1.0)
	return Color(0.95, 0.85, 0.2, 1.0)


func _draw() -> void:
	if state == State.RETRAINING:
		draw_arc(Vector2.ZERO, 9.5, 0.0, TAU, 18, Color(1.0, 0.88, 0.25, 0.95), 2.0)
	var wing_w: float = 3.5 + sin(_anim_time * 36.0) * 0.8
	StripedDrawer.draw_wings(self, Vector2.ZERO, Vector2(-1.0, 5.0), Vector2(wing_w, 2.0), _facing)
	StripedDrawer.draw_striped_body(self, Vector2.ZERO, Vector2(6.0, 4.0), _facing, _get_body_color(), Color(0.1, 0.08, 0.05, 1.0), 2)
	draw_set_transform(Vector2.ZERO, _facing, Vector2.ONE)
	match role:
		GameEnums.BeeRole.GATHERER:
			draw_circle(Vector2(-1.0, -3.8), 1.6, Color(1.0, 0.95, 0.45, 0.95))
			draw_circle(Vector2(-1.0, 3.8), 1.6, Color(1.0, 0.95, 0.45, 0.95))
		GameEnums.BeeRole.BUILDER:
			draw_circle(Vector2(6.8, 0.0), 1.9, Color(0.96, 0.76, 0.24, 0.95))
		GameEnums.BeeRole.SOLDIER:
			var stinger: PackedVector2Array = PackedVector2Array([
				Vector2(-5.5, -1.6),
				Vector2(-9.5, 0.0),
				Vector2(-5.5, 1.6),
			])
			draw_colored_polygon(stinger, Color(0.14, 0.1, 0.08, 1.0))
			draw_circle(Vector2(4.2, 0.0), 2.3, Color(0.95, 0.22, 0.2, 1.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
