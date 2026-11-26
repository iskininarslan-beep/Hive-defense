class_name GameDatabase
extends Object

const BALANCE_PATH: String = "res://assets/data/config/game_balance.tres"
const BUILDINGS_DIR: String = "res://assets/data/buildings"
const ENEMIES_DIR: String = "res://assets/data/enemies"
const RESEARCH_DIR: String = "res://assets/data/research"
const WAVES_DIR: String = "res://assets/data/waves"
const ABILITIES_DIR: String = "res://assets/data/abilities"
const EXTRA_MODS_DIR: String = "user://mods"


static func load_balance_config() -> GameBalanceConfig:
	if ResourceLoader.exists(BALANCE_PATH):
		var cfg: GameBalanceConfig = load(BALANCE_PATH) as GameBalanceConfig
		if cfg != null:
			return cfg
	push_warning("GameDatabase: fallback GameBalanceConfig")
	return GameBalanceConfig.new()


static func load_buildings(extra_dirs: PackedStringArray = PackedStringArray()) -> Array[BuildingData]:
	var by_id: Dictionary[StringName, BuildingData] = {}
	for path: String in _collect_paths(BUILDINGS_DIR, "buildings", extra_dirs):
		var res: BuildingData = load(path) as BuildingData
		if res == null or res.id == &"":
			push_warning("GameDatabase: skipped invalid building resource %s" % path)
			continue
		by_id[res.id] = res
	var result: Array[BuildingData] = []
	for b: BuildingData in by_id.values():
		result.append(b)
	result.sort_custom(func(a: BuildingData, b: BuildingData) -> bool:
		if int(a.category) != int(b.category):
			return int(a.category) < int(b.category)
		if a.sort_order != b.sort_order:
			return a.sort_order < b.sort_order
		return String(a.id) < String(b.id)
	)
	return result


static func load_enemies(extra_dirs: PackedStringArray = PackedStringArray()) -> Dictionary[StringName, EnemyData]:
	var result: Dictionary[StringName, EnemyData] = {}
	for path: String in _collect_paths(ENEMIES_DIR, "enemies", extra_dirs):
		var res: EnemyData = load(path) as EnemyData
		if res == null or res.id == &"":
			push_warning("GameDatabase: skipped invalid enemy resource %s" % path)
			continue
		result[res.id] = res
	return result


static func load_research(extra_dirs: PackedStringArray = PackedStringArray()) -> Array[ResearchData]:
	var by_id: Dictionary[StringName, ResearchData] = {}
	for path: String in _collect_paths(RESEARCH_DIR, "research", extra_dirs):
		var res: ResearchData = load(path) as ResearchData
		if res == null or res.id == &"":
			push_warning("GameDatabase: skipped invalid research resource %s" % path)
			continue
		by_id[res.id] = res
	var result: Array[ResearchData] = []
	for r: ResearchData in by_id.values():
		result.append(r)
	result.sort_custom(func(a: ResearchData, b: ResearchData) -> bool:
		if int(a.branch) != int(b.branch):
			return int(a.branch) < int(b.branch)
		if a.tier != b.tier:
			return a.tier < b.tier
		if a.sort_order != b.sort_order:
			return a.sort_order < b.sort_order
		return String(a.id) < String(b.id)
	)
	return result


static func load_waves(extra_dirs: PackedStringArray = PackedStringArray()) -> Array[WaveData]:
	var paths: Array[String] = _collect_paths(WAVES_DIR, "waves", extra_dirs)
	paths.sort()
	var result: Array[WaveData] = []
	for path: String in paths:
		var res: WaveData = load(path) as WaveData
		if res == null:
			push_warning("GameDatabase: skipped invalid wave resource %s" % path)
			continue
		result.append(res)
	return result


static func load_abilities(extra_dirs: PackedStringArray = PackedStringArray()) -> Array[AbilityData]:
	var by_id: Dictionary[StringName, AbilityData] = {}
	for path: String in _collect_paths(ABILITIES_DIR, "abilities", extra_dirs):
		var res: AbilityData = load(path) as AbilityData
		if res == null or res.id == &"":
			push_warning("GameDatabase: skipped invalid ability resource %s" % path)
			continue
		by_id[res.id] = res
	var result: Array[AbilityData] = []
	for ab: AbilityData in by_id.values():
		result.append(ab)
	result.sort_custom(func(a: AbilityData, b: AbilityData) -> bool:
		if a.sort_order != b.sort_order:
			return a.sort_order < b.sort_order
		return String(a.id) < String(b.id)
	)
	return result


static func get_runtime_extra_dirs() -> PackedStringArray:
	var dirs: PackedStringArray = PackedStringArray()
	if DirAccess.dir_exists_absolute(EXTRA_MODS_DIR):
		dirs.append(EXTRA_MODS_DIR)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--extra-data-dir="):
			var p: String = arg.substr("--extra-data-dir=".length()).strip_edges()
			if not p.is_empty():
				dirs.append(p)
	return dirs


static func _collect_paths(base_dir: String, sub_name: String, extra_dirs: PackedStringArray) -> Array[String]:
	var paths: Array[String] = _list_tres_in_dir(base_dir)
	for ext_root: String in extra_dirs:
		var sub_dir: String = ext_root.path_join(sub_name)
		for p: String in _list_tres_in_dir(sub_dir):
			paths.append(p)
	return paths


static func _list_tres_in_dir(dir_path: String) -> Array[String]:
	var seen: Dictionary[String, bool] = {}
	var paths: Array[String] = []
	var entries: PackedStringArray = ResourceLoader.list_directory(dir_path)
	if entries.is_empty() and DirAccess.dir_exists_absolute(dir_path):
		var da: DirAccess = DirAccess.open(dir_path)
		if da != null:
			entries = da.get_files()
	for raw_name: String in entries:
		var clean: String = raw_name
		if clean.ends_with(".remap"):
			clean = clean.substr(0, clean.length() - 6)
		if clean.ends_with(".tres"):
			var full: String = dir_path.path_join(clean)
			if not seen.has(full):
				seen[full] = true
				paths.append(full)
	paths.sort()
	return paths
