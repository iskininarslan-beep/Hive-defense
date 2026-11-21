class_name BuildingPanel
extends PanelContainer

signal demolish_requested(b: Building)
signal role_requested(b: Building, role: GameEnums.BeeRole)
signal research_requested
signal upgrade_requested(b: Building)
signal retrain_panel_requested

@onready var icon_rect: TextureRect = %BPIcon
@onready var name_label: Label = %BPName
@onready var hp_bar: ProgressBar = %BPHpBar
@onready var status_label: Label = %BPStatus
@onready var workers_row: HBoxContainer = %BPWorkersRow
@onready var worker_icon: TextureRect = %BPWorkerIcon
@onready var workers_label: Label = %BPWorkersLabel
@onready var kindergarten_box: HBoxContainer = %BPKindergartenBox
@onready var gatherer_btn: Button = %BPGathererBtn
@onready var builder_btn: Button = %BPBuilderBtn
@onready var soldier_btn: Button = %BPSoldierBtn
@onready var upgrade_btn: Button = %BPUpgradeBtn
@onready var retrain_btn: Button = %BPRetrainBtn
@onready var lab_btn: Button = %BPLabBtn
@onready var demolish_btn: Button = %BPDemolishBtn

var _building: Building = null
var _tween: Tween = null


func _ready() -> void:
	visible = false
	gatherer_btn.icon = GameIcons.ROLE_GATHERER
	builder_btn.icon = GameIcons.ROLE_BUILDER
	soldier_btn.icon = GameIcons.ROLE_SOLDIER
	upgrade_btn.icon = GameIcons.UI_UPGRADE
	retrain_btn.icon = GameIcons.UI_RETRAIN
	lab_btn.icon = GameIcons.BLD_LAB
	demolish_btn.icon = GameIcons.UI_DEMOLISH

	for btn: Button in [gatherer_btn, builder_btn, soldier_btn, upgrade_btn, retrain_btn, lab_btn, demolish_btn]:
		btn.focus_mode = Control.FOCUS_NONE

	gatherer_btn.pressed.connect(func() -> void:
		if is_instance_valid(_building):
			role_requested.emit(_building, GameEnums.BeeRole.GATHERER)
	)
	builder_btn.pressed.connect(func() -> void:
		if is_instance_valid(_building):
			role_requested.emit(_building, GameEnums.BeeRole.BUILDER)
	)
	soldier_btn.pressed.connect(func() -> void:
		if is_instance_valid(_building):
			role_requested.emit(_building, GameEnums.BeeRole.SOLDIER)
	)
	upgrade_btn.pressed.connect(func() -> void:
		if is_instance_valid(_building):
			upgrade_requested.emit(_building)
	)
	retrain_btn.pressed.connect(func() -> void: retrain_panel_requested.emit())
	lab_btn.pressed.connect(func() -> void: research_requested.emit())
	demolish_btn.pressed.connect(func() -> void:
		if is_instance_valid(_building):
			demolish_requested.emit(_building)
	)


func set_building(b: Building) -> void:
	var was_same: bool = _building == b and visible
	_building = b
	if not is_instance_valid(_building):
		visible = false
		return
	visible = true
	refresh()
	if not was_same:
		_play_pop_in()


func refresh() -> void:
	if not is_instance_valid(_building) or _building.data == null:
		visible = false
		return
	icon_rect.texture = _building.data.icon
	name_label.text = "%s ★%d" % [_building.data.display_name, _building.level] if _building.level >= 2 else _building.data.display_name
	hp_bar.value = _building.health.get_ratio() * 100.0
	status_label.text = _building.get_status_text()

	if _building.data.worker_slots > 0:
		workers_row.visible = true
		worker_icon.texture = GameIcons.role_icon(_building.data.worker_role)
		workers_label.text = "%d/%d" % [_building.get_present_operators(), _building.data.worker_slots]
	else:
		workers_row.visible = false

	var is_kg: bool = _building.behavior is KindergartenBehavior
	kindergarten_box.visible = is_kg
	if is_kg:
		var kb: KindergartenBehavior = _building.behavior as KindergartenBehavior
		gatherer_btn.modulate = Color(1.0, 0.9, 0.35) if kb.selected_role == GameEnums.BeeRole.GATHERER else Color.WHITE
		builder_btn.modulate = Color(1.0, 0.7, 0.35) if kb.selected_role == GameEnums.BeeRole.BUILDER else Color.WHITE
		soldier_btn.modulate = Color(1.0, 0.45, 0.45) if kb.selected_role == GameEnums.BeeRole.SOLDIER else Color.WHITE

	var can_upg: bool = _building.can_upgrade()
	upgrade_btn.visible = can_upg
	if can_upg:
		upgrade_btn.tooltip_text = _make_upgrade_tooltip(_building)

	var show_retrain: bool = _building.is_built and (_building.behavior is QueenBehavior or _building.behavior is KindergartenBehavior or _building.behavior is ApartmentsBehavior)
	retrain_btn.visible = show_retrain
	lab_btn.visible = _building.behavior is LabBehavior and _building.is_built
	demolish_btn.visible = _building.data.id != &"queen"


func _make_upgrade_tooltip(b: Building) -> String:
	var cost: Dictionary[GameEnums.ResourceType, float] = b.get_upgrade_cost()
	var parts: Array[String] = []
	for t: GameEnums.ResourceType in cost.keys():
		parts.append("%s %d" % [GameEnums.resource_name(t), int(cost[t])])
	var bonus: String = "+35% прочность, +35% урон, +20% скорость" if b.data is TowerData else "+35% прочность, +45% выпуск"
	return "Улучшить до Ур.2\n%s\n%s" % [bonus, " · ".join(parts)]


func _play_pop_in() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	pivot_offset = size * 0.5
	scale = Vector2(0.92, 0.92)
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.12)
