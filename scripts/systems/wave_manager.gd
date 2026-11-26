class_name WaveManager
extends Node

signal wave_started(index: int, wave: WaveData, direction_text: String)
signal enemy_killed(enemy: Enemy)
signal boss_spawned
signal boss_killed
signal intel_message(text: String)
signal enemy_breakthrough_announced
signal breakthrough_wave_started


class SpawnEntry extends RefCounted:
	var data: EnemyData
	var pattern: GameEnums.WavePattern = GameEnums.WavePattern.SCATTERED
	var base_angle: float = 0.0
	var is_breakthrough: bool = false

	func _init(p_data: EnemyData, p_pattern: GameEnums.WavePattern, p_angle: float, p_bt: bool = false) -> void:
		data = p_data
		pattern = p_pattern
		base_angle = p_angle
		is_breakthrough = p_bt


const SPAWN_RADIUS: float = 650.0

@export var enemy_scene: PackedScene
@export var first_wave_delay: float = 55.0
@export var wave_interval: float = 65.0
@export var breakthrough_delay: float = 12.0

var _context: GameContext
var _waves: Array[WaveData] = []
var _enemy_db: Dictionary[StringName, EnemyData] = {}
var _wave_index: int = 0
var _timer: float = 55.0
var _spawn_queue: Array[SpawnEntry] = []
var _spawn_timer: float = 0.0
var _current_interval: float = 0.6
var _breakthrough_announced: bool = false
var _breakthrough_launched: bool = false
var _breakthrough_timer: float = 0.0


func setup(context: GameContext, waves: Array[WaveData], enemy_db: Dictionary[StringName, EnemyData]) -> void:
	_context = context
	_waves = waves
	_enemy_db = enemy_db
	if _context != null and _context.balance != null:
		first_wave_delay = _context.balance.first_wave_delay
		wave_interval = _context.balance.wave_interval
		breakthrough_delay = _context.balance.breakthrough_delay
	_timer = first_wave_delay


func get_time_to_next_wave() -> float:
	if _wave_index >= _waves.size():
		return 0.0
	return maxf(0.0, _timer)


func get_wave_interval() -> float:
	return first_wave_delay if _wave_index == 0 else wave_interval


func get_wave_index() -> int:
	return _wave_index


func get_total_waves() -> int:
	return _waves.size()


func get_enemy_potential() -> float:
	var growth: float = _context.balance.wave_hp_growth if (_context != null and _context.balance != null) else 0.06
	return 1.0 + growth * float(maxi(0, _wave_index - 1))


func can_call_early() -> bool:
	return _wave_index < _waves.size() and _timer > 4.0 and not _breakthrough_announced


func is_breakthrough_announced() -> bool:
	return _breakthrough_announced


func is_breakthrough_active() -> bool:
	return _breakthrough_launched


func get_breakthrough_countdown() -> float:
	if _breakthrough_announced and not _breakthrough_launched:
		return maxf(0.0, _breakthrough_timer)
	return 0.0


func call_next_wave_early() -> bool:
	if not can_call_early():
		return false
	var wax_bonus: float = _context.balance.early_wave_wax_bonus if _context.balance != null else 15.0
	var honey_bonus: float = _context.balance.early_wave_honey_bonus if _context.balance != null else 10.0
	_context.bank.add(GameEnums.ResourceType.WAX, wax_bonus)
	_context.bank.add(GameEnums.ResourceType.HONEY, honey_bonus)
	if _context.effects != null:
		_context.effects.spawn_floating_text(_get_queen_pos() + Vector2(0.0, -32.0), "+%d воска +%d мёда" % [int(wax_bonus), int(honey_bonus)], Color(1.0, 0.9, 0.35))
	start_next_wave_now()
	return true


func start_next_wave_now() -> void:
	if _wave_index < _waves.size():
		_launch_next_wave()
		_timer = wave_interval


func trigger_breakthrough_now() -> void:
	_wave_index = _waves.size()
	_spawn_queue.clear()
	if not _breakthrough_announced:
		_announce_breakthrough()
	elif not _breakthrough_launched:
		_launch_breakthrough_wave()


func spawn_boss() -> void:
	var boss_data: EnemyData = _enemy_db.get(&"hornet_queen")
	var hornet_data: EnemyData = _enemy_db.get(&"hornet")
	if boss_data == null:
		return
	var base_angle: float = randf() * TAU
	var center: Vector2 = _get_arena_center()
	var boss_pos: Vector2 = center + Vector2(cos(base_angle), sin(base_angle)) * SPAWN_RADIUS
	var boss: Enemy = spawn_enemy(boss_data, boss_pos, GameEnums.Faction.HOSTILE)
	if boss != null:
		boss.died.connect(func(_e: Enemy) -> void: boss_killed.emit())
	if hornet_data != null:
		for i: int in range(10):
			var a: float = base_angle + randf_range(-0.26, 0.26)
			var pos: Vector2 = center + Vector2(cos(a), sin(a)) * (SPAWN_RADIUS + randf_range(0.0, 50.0))
			spawn_enemy(hornet_data, pos, GameEnums.Faction.HOSTILE)
	boss_spawned.emit()


func spawn_enemy(data: EnemyData, pos: Vector2, faction: GameEnums.Faction = GameEnums.Faction.HOSTILE, is_breakthrough_unit: bool = false) -> Enemy:
	if enemy_scene == null:
		push_error("WaveManager: enemy_scene is not assigned")
		return null
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	_context.enemies_root.add_child(enemy)
	enemy.global_position = pos
	var hp_mult: float = 1.0
	if faction == GameEnums.Faction.HOSTILE and not is_breakthrough_unit:
		hp_mult = maxf(0.65, get_enemy_potential() * _context.modifiers.multiplier(StatModifiers.ENEMY_POWER))
	enemy.setup(data, _context, faction, hp_mult)
	if is_breakthrough_unit:
		enemy.setup_breakthrough()
	enemy.died.connect(_on_enemy_died)
	return enemy


func _process(delta: float) -> void:
	if _context == null:
		return
	if _wave_index < _waves.size():
		_timer -= delta
		if _timer <= 0.0:
			_launch_next_wave()
			_timer = wave_interval
	if not _spawn_queue.is_empty():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = _current_interval
			var entry: SpawnEntry = _spawn_queue.pop_front()
			_spawn_entry(entry)
	elif _wave_index >= _waves.size():
		if not _breakthrough_announced:
			if not _has_hostile_enemies():
				_announce_breakthrough()
		elif not _breakthrough_launched:
			_breakthrough_timer -= delta
			if _breakthrough_timer <= 0.0:
				_launch_breakthrough_wave()


func _announce_breakthrough() -> void:
	_breakthrough_announced = true
	_breakthrough_timer = breakthrough_delay
	enemy_breakthrough_announced.emit()
	if _context.effects != null:
		_context.effects.set_breakthrough_alert(true)
	if _context.camera != null:
		_context.camera.add_shake(14.0)


func _launch_breakthrough_wave() -> void:
	_breakthrough_launched = true
	_current_interval = 0.15
	var center: Vector2 = _get_arena_center()
	var queen_data: EnemyData = _enemy_db.get(&"hornet_queen")
	var hornet_data: EnemyData = _enemy_db.get(&"hornet")
	var dragonfly_data: EnemyData = _enemy_db.get(&"dragonfly")
	if queen_data != null:
		for i: int in range(4):
			var a: float = float(i) * PI * 0.5
			var pos: Vector2 = center + Vector2(cos(a), sin(a)) * SPAWN_RADIUS
			spawn_enemy(queen_data, pos, GameEnums.Faction.HOSTILE, true)
	if hornet_data != null:
		for i: int in range(30):
			_spawn_queue.append(SpawnEntry.new(hornet_data, GameEnums.WavePattern.SCATTERED, 0.0, true))
	if dragonfly_data != null:
		for i: int in range(20):
			_spawn_queue.append(SpawnEntry.new(dragonfly_data, GameEnums.WavePattern.SCATTERED, 0.0, true))
	_spawn_timer = 0.0
	breakthrough_wave_started.emit()
	if _context.camera != null:
		_context.camera.add_shake(18.0)


func _launch_next_wave() -> void:
	if _wave_index >= _waves.size():
		return
	var wave: WaveData = _waves[_wave_index]
	_wave_index += 1
	_current_interval = maxf(0.1, wave.spawn_interval)
	var base_angle: float = randf() * TAU
	var dir_text: String = "со всех сторон" if wave.pattern == GameEnums.WavePattern.SCATTERED else _angle_to_direction(base_angle)
	if wave.pattern == GameEnums.WavePattern.FOCUSED and _context.effects != null:
		_context.effects.set_incoming_arrow(base_angle, 8.0)
	var size_mult: float = _context.modifiers.multiplier(StatModifiers.WAVE_SIZE)
	var pair_count: int = mini(wave.enemy_ids.size(), wave.enemy_counts.size())
	var entries: Array[SpawnEntry] = []
	for i: int in range(pair_count):
		var eid: StringName = StringName(wave.enemy_ids[i])
		var edata: EnemyData = _enemy_db.get(eid)
		if edata == null:
			continue
		var scaled_count: int = maxi(1, int(roundf(float(wave.enemy_counts[i]) * size_mult)))
		for c: int in range(scaled_count):
			entries.append(SpawnEntry.new(edata, wave.pattern, base_angle, false))
	entries.shuffle()
	_spawn_queue.append_array(entries)
	_spawn_timer = 0.0
	_spawn_allied_hornets()
	wave_started.emit(_wave_index, wave, dir_text)
	if _wave_index == 5:
		intel_message.emit("Разведка: враг наращивает военный потенциал")
	elif _wave_index == 10:
		intel_message.emit("Разведка: враг близок к научному прорыву!")


func _spawn_allied_hornets() -> void:
	var allies: int = int(roundf(_context.modifiers.get_value(StatModifiers.ALLIED_HORNETS)))
	if allies <= 0:
		return
	var hornet_data: EnemyData = _enemy_db.get(&"hornet")
	if hornet_data == null:
		return
	var center: Vector2 = _get_arena_center()
	for i: int in range(allies):
		var a: float = randf() * TAU
		spawn_enemy(hornet_data, center + Vector2(cos(a), sin(a)) * randf_range(36.0, 72.0), GameEnums.Faction.ALLY)


func _spawn_entry(entry: SpawnEntry) -> void:
	if entry == null or entry.data == null:
		return
	var pos: Vector2 = _pick_spawn_position(entry.data, entry.pattern, entry.base_angle)
	spawn_enemy(entry.data, pos, GameEnums.Faction.HOSTILE, entry.is_breakthrough)


func _pick_spawn_position(edata: EnemyData, pattern: GameEnums.WavePattern, base_angle: float) -> Vector2:
	var center: Vector2 = _get_arena_center()
	if edata.target_mode == GameEnums.EnemyTargetMode.STORAGE:
		var storages: Array[Building] = []
		for b: Building in _context.arena.get_buildings():
			if b.is_built and b.data is StorageData:
				storages.append(b)
		var anchor: Vector2 = center
		if not storages.is_empty():
			var chosen: Building = storages[randi() % storages.size()]
			anchor = chosen.global_position
		var offset_a: float = randf() * TAU
		return anchor + Vector2(cos(offset_a), sin(offset_a)) * randf_range(24.0, 60.0)
	var angle: float = randf() * TAU if pattern == GameEnums.WavePattern.SCATTERED else base_angle + deg_to_rad(randf_range(-22.0, 22.0))
	var dist: float = SPAWN_RADIUS + randf_range(-18.0, 42.0)
	return center + Vector2(cos(angle), sin(angle)) * dist


func _has_hostile_enemies() -> bool:
	for enemy: Enemy in _context.get_enemies():
		if enemy.faction == GameEnums.Faction.HOSTILE and not enemy.is_leaving():
			return true
	return false


func _on_enemy_died(enemy: Enemy) -> void:
	enemy_killed.emit(enemy)


func _get_arena_center() -> Vector2:
	if is_instance_valid(_context.arena):
		return _context.arena.global_position
	return Vector2(640.0, 335.0)


func _get_queen_pos() -> Vector2:
	if is_instance_valid(_context.queen):
		return _context.queen.global_position
	return _get_arena_center()


func _angle_to_direction(angle: float) -> String:
	var deg: float = fposmod(rad_to_deg(angle), 360.0)
	if deg >= 337.5 or deg < 22.5:
		return "с востока"
	if deg < 67.5:
		return "с юго-востока"
	if deg < 112.5:
		return "с юга"
	if deg < 157.5:
		return "с юго-запада"
	if deg < 202.5:
		return "с запада"
	if deg < 247.5:
		return "с северо-запада"
	if deg < 292.5:
		return "с севера"
	return "с северо-востока"
