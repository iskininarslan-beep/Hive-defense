class_name DataValidator
extends RefCounted

var warnings: Array[String] = []


func validate_all(
	balance: GameBalanceConfig,
	buildings: Array[BuildingData],
	enemies: Dictionary[StringName, EnemyData],
	research: Array[ResearchData],
	waves: Array[WaveData],
	abilities: Array[AbilityData]
) -> void:
	warnings.clear()
	validate_balance(balance)

	var research_ids: Dictionary[StringName, bool] = {}
	for r: ResearchData in research:
		if r != null and r.id != &"":
			research_ids[r.id] = true

	for r: ResearchData in research:
		validate_research(r, research_ids)
	for b: BuildingData in buildings:
		validate_building(b, research_ids)
	for eid: StringName in enemies.keys():
		validate_enemy(enemies[eid], eid)
	for i: int in range(waves.size()):
		validate_wave(waves[i], i + 1, enemies)
	for ab: AbilityData in abilities:
		validate_ability(ab, research_ids)


func validate_balance(cfg: GameBalanceConfig) -> void:
	if cfg == null:
		_warn("GameBalanceConfig отсутствует; используются значения по умолчанию")
		return
	cfg.start_pollen = _clamp_min(cfg.start_pollen, 0.0, "balance.start_pollen")
	cfg.start_nectar = _clamp_min(cfg.start_nectar, 0.0, "balance.start_nectar")
	cfg.start_wax = _clamp_min(cfg.start_wax, 0.0, "balance.start_wax")
	cfg.start_honey = _clamp_min(cfg.start_honey, 0.0, "balance.start_honey")
	cfg.base_storage_capacity = _clamp_min(cfg.base_storage_capacity, 20.0, "balance.base_storage_capacity")
	cfg.comb_wax_cost = _clamp_min(cfg.comb_wax_cost, 0.0, "balance.comb_wax_cost")
	cfg.demolish_refund_ratio = clampf(cfg.demolish_refund_ratio, 0.0, 1.0)
	cfg.base_bee_cap = maxi(1, cfg.base_bee_cap)
	cfg.bee_speed = _clamp_min(cfg.bee_speed, 20.0, "balance.bee_speed")
	cfg.retrain_duration = _clamp_min(cfg.retrain_duration, 0.2, "balance.retrain_duration")
	cfg.repair_hp_per_sec = _clamp_min(cfg.repair_hp_per_sec, 0.5, "balance.repair_hp_per_sec")
	cfg.combat_repair_hp_per_sec = _clamp_min(cfg.combat_repair_hp_per_sec, 0.5, "balance.combat_repair_hp_per_sec")
	cfg.upgrade_hp_mult = _clamp_min(cfg.upgrade_hp_mult, 1.0, "balance.upgrade_hp_mult")
	cfg.upgrade_tower_damage_mult = _clamp_min(cfg.upgrade_tower_damage_mult, 1.0, "balance.upgrade_tower_damage_mult")
	cfg.upgrade_tower_rate_mult = _clamp_min(cfg.upgrade_tower_rate_mult, 1.0, "balance.upgrade_tower_rate_mult")
	cfg.upgrade_economy_output_mult = _clamp_min(cfg.upgrade_economy_output_mult, 1.0, "balance.upgrade_economy_output_mult")
	cfg.first_wave_delay = _clamp_min(cfg.first_wave_delay, 5.0, "balance.first_wave_delay")
	cfg.wave_interval = _clamp_min(cfg.wave_interval, 5.0, "balance.wave_interval")
	cfg.breakthrough_delay = _clamp_min(cfg.breakthrough_delay, 2.0, "balance.breakthrough_delay")


func validate_building(d: BuildingData, research_ids: Dictionary[StringName, bool]) -> void:
	if d == null:
		return
	var tag: String = "building:%s" % String(d.id)
	if d.display_name.strip_edges().is_empty():
		d.display_name = String(d.id) if d.id != &"" else "Здание"
		_warn("%s.display_name пуст → подставлено '%s'" % [tag, d.display_name])
	d.cost_pollen = _clamp_min(d.cost_pollen, 0.0, "%s.cost_pollen" % tag)
	d.cost_nectar = _clamp_min(d.cost_nectar, 0.0, "%s.cost_nectar" % tag)
	d.cost_wax = _clamp_min(d.cost_wax, 0.0, "%s.cost_wax" % tag)
	d.cost_honey = _clamp_min(d.cost_honey, 0.0, "%s.cost_honey" % tag)
	d.max_hp = _clamp_min(d.max_hp, 1.0, "%s.max_hp" % tag)
	if d.build_time < 0.0:
		_warn("%s.build_time=%.2f → исправлено на 0.5" % [tag, d.build_time])
		d.build_time = 0.5
	d.footprint_radius = clampi(d.footprint_radius, 0, 1)
	if d.worker_slots < 0:
		_warn("%s.worker_slots=%d → исправлено на 0" % [tag, d.worker_slots])
		d.worker_slots = 0
	if d.icon == null:
		d.icon = GameIcons.UI_WARNING
		_warn("%s.icon == null → подставлена безопасная иконка" % tag)
	if d.required_research != &"" and not research_ids.has(d.required_research):
		_warn("%s.required_research '%s' не найдено → блокировка снята" % [tag, String(d.required_research)])
		d.required_research = &""
	if d is TowerData:
		var td: TowerData = d as TowerData
		td.attack_range = _clamp_min(td.attack_range, 20.0, "%s.attack_range" % tag)
		td.damage = _clamp_min(td.damage, 0.0, "%s.damage" % tag)
		td.fire_interval = _clamp_min(td.fire_interval, 0.08, "%s.fire_interval" % tag)
		td.projectile_speed = _clamp_min(td.projectile_speed, 50.0, "%s.projectile_speed" % tag)
		td.slow_factor = clampf(td.slow_factor, 0.1, 1.0)
		td.chain_count = maxi(1, td.chain_count)
	elif d is FactoryData:
		var fd: FactoryData = d as FactoryData
		fd.input_amount = _clamp_min(fd.input_amount, 0.0, "%s.input_amount" % tag)
		fd.output_amount = _clamp_min(fd.output_amount, 0.1, "%s.output_amount" % tag)
		fd.cycle_time = _clamp_min(fd.cycle_time, 0.1, "%s.cycle_time" % tag)
	elif d is GatherData:
		var gd: GatherData = d as GatherData
		gd.amount_per_trip = _clamp_min(gd.amount_per_trip, 0.5, "%s.amount_per_trip" % tag)
		gd.collect_time = _clamp_min(gd.collect_time, 0.1, "%s.collect_time" % tag)
	elif d is KindergartenData:
		var kd: KindergartenData = d as KindergartenData
		kd.honey_cost = _clamp_min(kd.honey_cost, 0.0, "%s.honey_cost" % tag)
		kd.hatch_time = _clamp_min(kd.hatch_time, 0.2, "%s.hatch_time" % tag)


func validate_enemy(d: EnemyData, fallback_id: StringName = &"") -> void:
	if d == null:
		return
	var tag: String = "enemy:%s" % String(d.id if d.id != &"" else fallback_id)
	d.max_hp = _clamp_min(d.max_hp, 1.0, "%s.max_hp" % tag)
	d.speed = _clamp_min(d.speed, 10.0, "%s.speed" % tag)
	d.damage = _clamp_min(d.damage, 0.0, "%s.damage" % tag)
	d.attack_interval = _clamp_min(d.attack_interval, 0.1, "%s.attack_interval" % tag)
	d.radius = _clamp_min(d.radius, 4.0, "%s.radius" % tag)
	d.visual_scale = _clamp_min(d.visual_scale, 0.25, "%s.visual_scale" % tag)
	if d.visual_script == null:
		d.visual_script = HornetVisual
		_warn("%s.visual_script == null → подставлен HornetVisual" % tag)


func validate_research(d: ResearchData, all_ids: Dictionary[StringName, bool]) -> void:
	if d == null:
		return
	var tag: String = "research:%s" % String(d.id)
	d.cost_pollen = _clamp_min(d.cost_pollen, 0.0, "%s.cost_pollen" % tag)
	d.cost_nectar = _clamp_min(d.cost_nectar, 0.0, "%s.cost_nectar" % tag)
	d.cost_wax = _clamp_min(d.cost_wax, 0.0, "%s.cost_wax" % tag)
	d.cost_honey = _clamp_min(d.cost_honey, 0.0, "%s.cost_honey" % tag)
	d.time = _clamp_min(d.time, 0.5, "%s.time" % tag)
	if d.icon == null:
		d.icon = GameIcons.BLD_LAB
		_warn("%s.icon == null → подставлена иконка лаборатории" % tag)
	var clean_reqs: PackedStringArray = PackedStringArray()
	for req: String in d.prerequisites:
		if all_ids.has(StringName(req)):
			clean_reqs.append(req)
		else:
			_warn("%s: неизвестная зависимость '%s' удалена" % [tag, req])
	d.prerequisites = clean_reqs


func validate_wave(w: WaveData, idx: int, enemy_db: Dictionary[StringName, EnemyData]) -> void:
	if w == null:
		return
	var tag: String = "wave_%02d" % idx
	w.spawn_interval = _clamp_min(w.spawn_interval, 0.1, "%s.spawn_interval" % tag)
	var pair_count: int = mini(w.enemy_ids.size(), w.enemy_counts.size())
	if w.enemy_ids.size() != w.enemy_counts.size():
		_warn("%s: несовпадение длин enemy_ids (%d) и enemy_counts (%d)" % [tag, w.enemy_ids.size(), w.enemy_counts.size()])
	var valid_ids: PackedStringArray = PackedStringArray()
	var valid_counts: PackedInt32Array = PackedInt32Array()
	for i: int in range(pair_count):
		var eid: StringName = StringName(w.enemy_ids[i])
		var cnt: int = w.enemy_counts[i]
		if not enemy_db.has(eid):
			_warn("%s: неизвестный враг '%s' пропущен" % [tag, String(eid)])
			continue
		if cnt <= 0:
			_warn("%s: count=%d для '%s' → исправлено на 1" % [tag, cnt, String(eid)])
			cnt = 1
		valid_ids.append(w.enemy_ids[i])
		valid_counts.append(cnt)
	w.enemy_ids = valid_ids
	w.enemy_counts = valid_counts


func validate_ability(ab: AbilityData, research_ids: Dictionary[StringName, bool]) -> void:
	if ab == null:
		return
	var tag: String = "ability:%s" % String(ab.id)
	ab.cooldown = _clamp_min(ab.cooldown, 1.0, "%s.cooldown" % tag)
	ab.duration = _clamp_min(ab.duration, 0.0, "%s.duration" % tag)
	if ab.icon == null:
		ab.icon = GameIcons.UI_WARNING
		_warn("%s.icon == null → подставлена безопасная иконка" % tag)
	if ab.required_research != &"" and not research_ids.has(ab.required_research):
		_warn("%s.required_research '%s' не найдено" % [tag, String(ab.required_research)])
		ab.required_research = &""


func _clamp_min(val: float, min_val: float, field_name: String) -> float:
	if is_nan(val) or is_inf(val):
		_warn("%s имеет некорректное число (NaN/Inf) → %.2f" % [field_name, min_val])
		return min_val
	if val < min_val:
		_warn("%s=%.2f < %.2f → скорректировано до %.2f" % [field_name, val, min_val, min_val])
		return min_val
	return val


func _warn(msg: String) -> void:
	warnings.append(msg)
	push_warning("DataValidator: %s" % msg)
