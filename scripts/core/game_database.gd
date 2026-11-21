class_name GameDatabase
extends Object

const BUILDING_IDS: Array[StringName] = [
	&"queen",
	&"pollen_post",
	&"nectar_post",
	&"wax_factory",
	&"honey_factory",
	&"storage",
	&"kindergarten",
	&"apartments",
	&"lab",
	&"ballista",
	&"anti_air",
	&"honey_mortar",
	&"tesla_spire",
	&"golden_hive",
]

const ENEMY_IDS: Array[StringName] = [
	&"hornet",
	&"spider",
	&"mole_cricket",
	&"ladybug",
	&"dragonfly",
	&"hornet_queen",
]

const RESEARCH_IDS: Array[StringName] = [
	&"spear",
	&"honey_mortar",
	&"tesla_spire",
	&"elite_regiment",
	&"reinforced_wax",
	&"general_battle",
	&"honey_factory",
	&"aluminium_bucket",
	&"swift_wings",
	&"improved_hinge",
	&"mega_apartments",
	&"golden_hive",
	&"translator",
	&"agitation",
	&"sabotage",
	&"field_talks",
	&"mercenary_pact",
	&"peace_treaty",
]

const WAVE_COUNT: int = 15


static func load_buildings() -> Array[BuildingData]:
	var result: Array[BuildingData] = []
	for id: StringName in BUILDING_IDS:
		var path: String = "res://assets/data/buildings/%s.tres" % String(id)
		var res: BuildingData = load(path) as BuildingData
		if res == null:
			push_error("GameDatabase: failed to load building %s" % path)
		else:
			result.append(res)
	return result


static func load_enemies() -> Dictionary[StringName, EnemyData]:
	var result: Dictionary[StringName, EnemyData] = {}
	for id: StringName in ENEMY_IDS:
		var path: String = "res://assets/data/enemies/%s.tres" % String(id)
		var res: EnemyData = load(path) as EnemyData
		if res == null:
			push_error("GameDatabase: failed to load enemy %s" % path)
		else:
			result[id] = res
	return result


static func load_research() -> Array[ResearchData]:
	var result: Array[ResearchData] = []
	for id: StringName in RESEARCH_IDS:
		var path: String = "res://assets/data/research/%s.tres" % String(id)
		var res: ResearchData = load(path) as ResearchData
		if res == null:
			push_error("GameDatabase: failed to load research %s" % path)
		else:
			result.append(res)
	return result


static func load_waves() -> Array[WaveData]:
	var result: Array[WaveData] = []
	for i: int in range(1, WAVE_COUNT + 1):
		var path: String = "res://assets/data/waves/wave_%02d.tres" % i
		var res: WaveData = load(path) as WaveData
		if res == null:
			push_error("GameDatabase: failed to load wave %s" % path)
		else:
			result.append(res)
	return result
