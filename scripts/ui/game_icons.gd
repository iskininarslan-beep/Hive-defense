class_name GameIcons
extends Object

const RES_POLLEN: Texture2D = preload("res://assets/icons/res_pollen.svg")
const RES_NECTAR: Texture2D = preload("res://assets/icons/res_nectar.svg")
const RES_WAX: Texture2D = preload("res://assets/icons/res_wax.svg")
const RES_HONEY: Texture2D = preload("res://assets/icons/res_honey.svg")

const ROLE_GATHERER: Texture2D = preload("res://assets/icons/role_gatherer.svg")
const ROLE_BUILDER: Texture2D = preload("res://assets/icons/role_builder.svg")
const ROLE_SOLDIER: Texture2D = preload("res://assets/icons/role_soldier.svg")

const UI_BEE: Texture2D = preload("res://assets/icons/ui_bee.svg")
const UI_CROWN: Texture2D = preload("res://assets/icons/ui_crown.svg")
const UI_COMB: Texture2D = preload("res://assets/icons/ui_comb.svg")
const UI_DEMOLISH: Texture2D = preload("res://assets/icons/ui_demolish.svg")
const UI_PAUSE: Texture2D = preload("res://assets/icons/ui_pause.svg")
const UI_SPEED: Texture2D = preload("res://assets/icons/ui_speed.svg")
const UI_SCROLL: Texture2D = preload("res://assets/icons/ui_scroll.svg")
const UI_DOVE: Texture2D = preload("res://assets/icons/ui_dove.svg")
const UI_RETRAIN: Texture2D = preload("res://assets/icons/ui_retrain.svg")
const UI_UPGRADE: Texture2D = preload("res://assets/icons/ui_upgrade.svg")
const UI_WARNING: Texture2D = preload("res://assets/icons/ui_warning.svg")
const UI_WAVE_NEXT: Texture2D = preload("res://assets/icons/ui_wave_next.svg")

const BLD_LAB: Texture2D = preload("res://assets/icons/bld_lab.svg")
const BLD_APARTMENTS: Texture2D = preload("res://assets/icons/bld_apartments.svg")
const BLD_TESLA_SPIRE: Texture2D = preload("res://assets/icons/bld_tesla_spire.svg")


static func resource_icon(type: GameEnums.ResourceType) -> Texture2D:
	match type:
		GameEnums.ResourceType.POLLEN:
			return RES_POLLEN
		GameEnums.ResourceType.NECTAR:
			return RES_NECTAR
		GameEnums.ResourceType.WAX:
			return RES_WAX
		GameEnums.ResourceType.HONEY:
			return RES_HONEY
	return null


static func role_icon(role: GameEnums.BeeRole) -> Texture2D:
	match role:
		GameEnums.BeeRole.GATHERER:
			return ROLE_GATHERER
		GameEnums.BeeRole.BUILDER:
			return ROLE_BUILDER
		GameEnums.BeeRole.SOLDIER:
			return ROLE_SOLDIER
	return null
