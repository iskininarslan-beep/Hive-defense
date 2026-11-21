class_name GameEnums
extends Object

enum ResourceType {
	POLLEN,
	NECTAR,
	WAX,
	HONEY,
}

enum BeeRole {
	NONE,
	GATHERER,
	BUILDER,
	SOLDIER,
}

enum BalanceStatus {
	BALANCED,
	TOO_MANY_SOLDIERS,
	TOO_MANY_GATHERERS,
}

enum BuildCategory {
	ECONOMY,
	COLONY,
	SCIENCE,
	DEFENSE,
	WONDER,
	HIDDEN,
}

enum TargetLayer {
	GROUND,
	AIR,
	BOTH,
}

enum EnemyTargetMode {
	QUEEN,
	NEAREST_BUILDING,
	STORAGE,
}

enum Faction {
	HOSTILE,
	ALLY,
}

enum ResearchBranch {
	MILITARY,
	BEES,
	DIPLOMACY,
}

enum Ending {
	NONE,
	MILITARY,
	DIPLOMATIC,
	ECONOMIC,
	ENEMY_BREAKTHROUGH,
	DEFEAT,
}

enum WavePattern {
	SCATTERED,
	FOCUSED,
}


static func resource_name(type: ResourceType) -> String:
	match type:
		ResourceType.POLLEN:
			return "Пыльца"
		ResourceType.NECTAR:
			return "Нектар"
		ResourceType.WAX:
			return "Воск"
		ResourceType.HONEY:
			return "Мёд"
	return ""


static func role_name(role: BeeRole) -> String:
	match role:
		BeeRole.NONE:
			return "Нет"
		BeeRole.GATHERER:
			return "Собиратель"
		BeeRole.BUILDER:
			return "Строитель"
		BeeRole.SOLDIER:
			return "Воин"
	return ""


static func category_name(cat: BuildCategory) -> String:
	match cat:
		BuildCategory.ECONOMY:
			return "Экономика"
		BuildCategory.COLONY:
			return "Колония"
		BuildCategory.SCIENCE:
			return "Наука"
		BuildCategory.DEFENSE:
			return "Оборона"
		BuildCategory.WONDER:
			return "Чудо"
	return ""


static func branch_name(branch: ResearchBranch) -> String:
	match branch:
		ResearchBranch.MILITARY:
			return "Военное"
		ResearchBranch.BEES:
			return "Экономика"
		ResearchBranch.DIPLOMACY:
			return "Дипломатия"
	return ""
