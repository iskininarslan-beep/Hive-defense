class_name AbilityData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var required_research: StringName = &""
@export var cooldown: float = 60.0
@export var duration: float = 0.0
@export var effect_value: float = 0.0
@export var max_targets: int = 0
@export var is_toggle: bool = false
@export var sort_order: int = 100
@export var ability_script: Script


func create_ability() -> Ability:
	var ab: Ability = null
	if ability_script != null:
		var inst: Variant = ability_script.new()
		if inst is Ability:
			ab = inst as Ability
	if ab == null:
		ab = Ability.new()
	ab.configure(self)
	return ab
