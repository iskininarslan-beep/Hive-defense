class_name HUD
extends Control

signal build_requested(data: BuildingData)
signal comb_mode_requested
signal delete_mode_requested
signal ability_requested(ability: Ability)
signal pause_toggled
signal speed_cycle_requested
signal demolish_requested(b: Building)
signal kindergarten_role_requested(b: Building, role: GameEnums.BeeRole)
signal lab_open_requested
signal upgrade_requested(b: Building)
signal retrain_requested(from_role: GameEnums.BeeRole, to_role: GameEnums.BeeRole)
signal call_wave_requested
signal workers_adjust_requested(b: Building, delta: int)


class BuildingButtonEntry extends RefCounted:
	var btn: Button
	var data: BuildingData

	func _init(p_btn: Button, p_data: BuildingData) -> void:
		btn = p_btn
		data = p_data


class AbilityButtonEntry extends RefCounted:
	var btn: Button
	var label: Label
	var ability: Ability

	func _init(p_btn: Button, p_lbl: Label, p_ab: Ability) -> void:
		btn = p_btn
		label = p_lbl
		ability = p_ab


class RetrainRowEntry extends RefCounted:
	var role: GameEnums.BeeRole
	var label: Label
	var btns: Array[Button] = []

	func _init(p_role: GameEnums.BeeRole, p_lbl: Label, p_btns: Array[Button]) -> void:
		role = p_role
		label = p_lbl
		btns = p_btns


@onready var pollen_chip: HBoxContainer = %PollenChip
@onready var pollen_label: Label = %PollenLabel
@onready var nectar_chip: HBoxContainer = %NectarChip
@onready var nectar_label: Label = %NectarLabel
@onready var wax_chip: HBoxContainer = %WaxChip
@onready var wax_label: Label = %WaxLabel
@onready var honey_chip: HBoxContainer = %HoneyChip
@onready var honey_label: Label = %HoneyLabel
@onready var bees_btn: Button = %BeesBtn
@onready var queen_hp_bar: ProgressBar = %QueenHPBar

@onready var wave_label: Label = %WaveLabel
@onready var wave_progress: ProgressBar = %WaveProgress
@onready var call_wave_btn: Button = %CallWaveBtn
@onready var toast_label: Label = %ToastLabel

@onready var pause_btn: Button = %PauseBtn
@onready var speed_btn: Button = %SpeedBtn
@onready var balance_badge: Button = %BalanceBadge
@onready var retrain_panel: PanelContainer = %RetrainPanel
@onready var retrain_icon: TextureRect = %RetrainIcon
@onready var retrain_close_btn: Button = %RetrainCloseBtn
@onready var retrain_rows_box: VBoxContainer = %RetrainRowsBox
@onready var ability_bar: VBoxContainer = %AbilityBar
@onready var build_bar_box: HBoxContainer = %BuildBarBox
@onready var building_panel: BuildingPanel = %BuildingPanel

var _context: GameContext
var _all_buildings: Array[BuildingData] = []
var _research: ResearchManager
var _waves: WaveManager
var _abilities: AbilityManager
var _build_controller: BuildController

var _comb_btn: Button
var _delete_btn: Button
var _building_buttons: Array[BuildingButtonEntry] = []
var _ability_buttons: Array[AbilityButtonEntry] = []
var _retrain_rows: Array[RetrainRowEntry] = []
var _toast_tween: Tween = null
var _pulse_tween: Tween = null


func setup(
	p_context: GameContext,
	p_buildings: Array[BuildingData],
	p_research: ResearchManager,
	p_waves: WaveManager,
	p_abilities: AbilityManager,
	p_build_controller: BuildController
) -> void:
	_context = p_context
	_all_buildings = p_buildings
	_research = p_research
	_waves = p_waves
	_abilities = p_abilities
	_build_controller = p_build_controller

	bees_btn.icon = GameIcons.UI_BEE
	bees_btn.focus_mode = Control.FOCUS_NONE
	bees_btn.pressed.connect(toggle_retrain_panel)

	call_wave_btn.icon = GameIcons.UI_WAVE_NEXT
	call_wave_btn.focus_mode = Control.FOCUS_NONE
	call_wave_btn.pressed.connect(func() -> void: call_wave_requested.emit())
	if _context != null and _context.balance != null:
		call_wave_btn.tooltip_text = "Вызвать волну раньше (+%d воска, +%d мёда)" % [
			int(_context.balance.early_wave_wax_bonus),
			int(_context.balance.early_wave_honey_bonus),
		]

	pause_btn.icon = GameIcons.UI_PAUSE
	speed_btn.icon = GameIcons.UI_SPEED
	pause_btn.focus_mode = Control.FOCUS_NONE
	speed_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(func() -> void: pause_toggled.emit())
	speed_btn.pressed.connect(func() -> void: speed_cycle_requested.emit())

	balance_badge.icon = GameIcons.UI_WARNING
	balance_badge.focus_mode = Control.FOCUS_NONE
	balance_badge.visible = false
	balance_badge.pressed.connect(open_retrain_panel)

	retrain_icon.texture = GameIcons.UI_RETRAIN
	retrain_close_btn.focus_mode = Control.FOCUS_NONE
	retrain_close_btn.pressed.connect(close_retrain_panel)
	retrain_panel.visible = false

	building_panel.set_balance_config(_context.balance if _context != null else null)
	building_panel.demolish_requested.connect(func(b: Building) -> void: demolish_requested.emit(b))
	building_panel.role_requested.connect(func(b: Building, role: GameEnums.BeeRole) -> void: kindergarten_role_requested.emit(b, role))
	building_panel.research_requested.connect(func() -> void: lab_open_requested.emit())
	building_panel.upgrade_requested.connect(func(b: Building) -> void: upgrade_requested.emit(b))
	building_panel.retrain_panel_requested.connect(open_retrain_panel)
	building_panel.workers_adjust_requested.connect(func(b: Building, d: int) -> void: workers_adjust_requested.emit(b, d))

	_build_controller.building_selected.connect(show_building)
	_build_controller.mode_changed.connect(_on_build_mode_changed)
	_abilities.abilities_changed.connect(_rebuild_abilities)
	_research.research_completed.connect(func(_d: ResearchData) -> void: _refresh_build_bar())
	_context.arena.building_placed.connect(_on_building_placed)
	_context.arena.building_removed.connect(func(_b: Building) -> void: _refresh_build_bar())
	_context.bank.resources_changed.connect(_on_resource_changed)
	_context.colony.population_changed.connect(_on_population_changed)
	_context.colony.balance_changed.connect(_on_balance_changed)

	_build_retrain_rows()
	_build_bottom_bar()
	_rebuild_abilities()
	refresh_all()
	toast_label.text = ""
	toast_label.modulate.a = 0.0


func refresh_all() -> void:
	if _context == null:
		return
	for t: GameEnums.ResourceType in [
		GameEnums.ResourceType.POLLEN,
		GameEnums.ResourceType.NECTAR,
		GameEnums.ResourceType.WAX,
		GameEnums.ResourceType.HONEY,
	]:
		_on_resource_changed(t, _context.bank.get_amount(t), _context.bank.get_capacity(t))
	_on_population_changed(_context.colony.get_population(), _context.colony.get_cap())
	_on_balance_changed(_context.colony.get_balance_status())
	if is_instance_valid(_context.queen):
		queen_hp_bar.value = _context.queen.health.get_ratio() * 100.0


func open_retrain_panel() -> void:
	if retrain_panel.visible:
		_refresh_retrain_rows()
		return
	retrain_panel.visible = true
	_refresh_retrain_rows()
	retrain_panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(retrain_panel, "modulate:a", 1.0, 0.14)


func close_retrain_panel() -> void:
	retrain_panel.visible = false


func toggle_retrain_panel() -> void:
	if retrain_panel.visible:
		close_retrain_panel()
	else:
		open_retrain_panel()


func show_building(b: Building) -> void:
	building_panel.set_building(b)


func refresh_building_panel() -> void:
	building_panel.refresh()


func set_pause_speed_state(paused: bool, speed: float) -> void:
	pause_btn.modulate = Color(1.0, 0.85, 0.35) if paused else Color.WHITE
	speed_btn.text = "x%d" % int(roundf(speed))


func show_message(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 1.0)


func _on_building_placed(b: Building) -> void:
	_refresh_build_bar()
	if b.data != null and b.data.id == &"queen":
		if not b.health.health_changed.is_connected(_on_queen_health_changed):
			b.health.health_changed.connect(_on_queen_health_changed)
		queen_hp_bar.value = b.health.get_ratio() * 100.0


func _on_queen_health_changed(current: float, max_hp: float) -> void:
	queen_hp_bar.value = (current / maxf(1.0, max_hp)) * 100.0


func _on_resource_changed(type: GameEnums.ResourceType, amount: float, capacity: float) -> void:
	var lbl: Label = null
	var chip: HBoxContainer = null
	match type:
		GameEnums.ResourceType.POLLEN:
			lbl = pollen_label
			chip = pollen_chip
		GameEnums.ResourceType.NECTAR:
			lbl = nectar_label
			chip = nectar_chip
		GameEnums.ResourceType.WAX:
			lbl = wax_label
			chip = wax_chip
		GameEnums.ResourceType.HONEY:
			lbl = honey_label
			chip = honey_chip
	if lbl == null or chip == null:
		return
	lbl.text = str(int(amount))
	lbl.modulate = Color(1.0, 0.62, 0.2) if amount >= capacity * 0.95 else Color.WHITE
	chip.tooltip_text = "%s %d / %d" % [GameEnums.resource_name(type), int(amount), int(capacity)]


func _on_population_changed(total: int, cap: int) -> void:
	bees_btn.text = "%d/%d" % [total, cap]
	if _context != null and _context.colony != null:
		bees_btn.tooltip_text = "Пчёлы: %d / %d (нажмите для переквалификации)\nСобиратели: %d · Строители: %d · Воины: %d" % [
			total,
			cap,
			_context.colony.get_count(GameEnums.BeeRole.GATHERER),
			_context.colony.get_count(GameEnums.BeeRole.BUILDER),
			_context.colony.get_count(GameEnums.BeeRole.SOLDIER),
		]
	if retrain_panel.visible:
		_refresh_retrain_rows()


func _on_balance_changed(status: GameEnums.BalanceStatus) -> void:
	if status == GameEnums.BalanceStatus.BALANCED:
		balance_badge.visible = false
		if _pulse_tween != null and _pulse_tween.is_valid():
			_pulse_tween.kill()
		return
	balance_badge.visible = true
	if status == GameEnums.BalanceStatus.TOO_MANY_SOLDIERS:
		balance_badge.text = "Перевес воинов"
		balance_badge.modulate = Color(1.0, 0.55, 0.4)
		balance_badge.tooltip_text = "Слишком много воинов относительно собирателей.\nНажмите, чтобы переобучить пчёл."
	else:
		balance_badge.text = "Перевес собирателей"
		balance_badge.modulate = Color(1.0, 0.85, 0.35)
		balance_badge.tooltip_text = "Мало воинов относительно собирателей.\nНажмите, чтобы переобучить пчёл."
	if _pulse_tween == null or not _pulse_tween.is_valid():
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(balance_badge, "modulate:a", 0.55, 0.75)
		_pulse_tween.tween_property(balance_badge, "modulate:a", 1.0, 0.75)


func _build_retrain_rows() -> void:
	for child: Node in retrain_rows_box.get_children():
		child.queue_free()
	_retrain_rows.clear()
	var roles: Array[GameEnums.BeeRole] = [
		GameEnums.BeeRole.GATHERER,
		GameEnums.BeeRole.BUILDER,
		GameEnums.BeeRole.SOLDIER,
	]
	for from_role: GameEnums.BeeRole in roles:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(28.0, 28.0)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = GameIcons.role_icon(from_role)
		row.add_child(icon_rect)

		var cnt_lbl: Label = Label.new()
		cnt_lbl.custom_minimum_size = Vector2(36.0, 0.0)
		cnt_lbl.add_theme_font_size_override("font_size", 20)
		cnt_lbl.text = "0"
		row.add_child(cnt_lbl)

		var arrow_lbl: Label = Label.new()
		arrow_lbl.text = "→"
		arrow_lbl.add_theme_font_size_override("font_size", 20)
		row.add_child(arrow_lbl)

		var target_btns: Array[Button] = []
		for to_role: GameEnums.BeeRole in roles:
			if to_role == from_role:
				continue
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(42.0, 42.0)
			btn.icon = GameIcons.role_icon(to_role)
			btn.expand_icon = true
			btn.focus_mode = Control.FOCUS_NONE
			btn.tooltip_text = "Переобучить: %s → %s" % [GameEnums.role_name(from_role), GameEnums.role_name(to_role)]
			btn.pressed.connect(func() -> void: retrain_requested.emit(from_role, to_role))
			row.add_child(btn)
			target_btns.append(btn)

		retrain_rows_box.add_child(row)
		_retrain_rows.append(RetrainRowEntry.new(from_role, cnt_lbl, target_btns))


func _refresh_retrain_rows() -> void:
	if _context == null or _context.colony == null:
		return
	for item: RetrainRowEntry in _retrain_rows:
		var count: int = _context.colony.get_count(item.role)
		var ready: int = _context.colony.get_retrainable_count(item.role)
		item.label.text = str(count)
		for btn: Button in item.btns:
			btn.disabled = (ready <= 0)


func _build_bottom_bar() -> void:
	for child: Node in build_bar_box.get_children():
		child.queue_free()
	_building_buttons.clear()

	var comb_cost: int = int(_context.balance.comb_wax_cost) if (_context != null and _context.balance != null) else 5
	_comb_btn = _make_bar_button(GameIcons.UI_COMB, "Соты (Воск %d)\nЗажмите ЛКМ для рисования сот" % comb_cost)
	_comb_btn.pressed.connect(func() -> void: comb_mode_requested.emit())
	build_bar_box.add_child(_comb_btn)

	_delete_btn = _make_bar_button(GameIcons.UI_DEMOLISH, "Снос зданий\nВозврат 50% ресурсов")
	_delete_btn.pressed.connect(func() -> void: delete_mode_requested.emit())
	build_bar_box.add_child(_delete_btn)

	var prev_cat: int = -1
	for data: BuildingData in _all_buildings:
		if data.category == GameEnums.BuildCategory.HIDDEN:
			continue
		if int(data.category) != prev_cat:
			var sep: VSeparator = VSeparator.new()
			build_bar_box.add_child(sep)
			prev_cat = int(data.category)
		var btn: Button = _make_bar_button(data.icon, "")
		btn.pressed.connect(func() -> void: build_requested.emit(data))
		build_bar_box.add_child(btn)
		_building_buttons.append(BuildingButtonEntry.new(btn, data))
	_refresh_build_bar()


func _make_bar_button(tex: Texture2D, tip: String) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(54.0, 54.0)
	btn.icon = tex
	btn.expand_icon = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = tip
	return btn


func _refresh_build_bar() -> void:
	if _research == null or _context == null:
		return
	var active_mode: BuildController.Mode = _build_controller.mode
	var active_data: BuildingData = _build_controller.build_data
	if _comb_btn != null:
		_comb_btn.modulate = Color(1.0, 0.9, 0.35) if active_mode == BuildController.Mode.COMB else Color.WHITE
	if _delete_btn != null:
		_delete_btn.modulate = Color(1.0, 0.55, 0.45) if active_mode == BuildController.Mode.DELETE else Color.WHITE

	for item: BuildingButtonEntry in _building_buttons:
		var locked: bool = item.data.required_research != &"" and not _research.is_completed(item.data.required_research)
		var at_limit: bool = item.data.max_count > 0 and _context.arena.count_all(item.data.id) >= item.data.max_count
		item.btn.disabled = locked or at_limit
		if item.btn.disabled:
			item.btn.modulate = Color(0.58, 0.58, 0.62, 0.88)
		elif active_mode == BuildController.Mode.BUILD and active_data == item.data:
			item.btn.modulate = Color(1.0, 0.92, 0.4)
		else:
			item.btn.modulate = Color.WHITE
		item.btn.tooltip_text = _build_tooltip(item.data, locked, at_limit)


func _build_tooltip(data: BuildingData, locked: bool, at_limit: bool) -> String:
	var lines: Array[String] = [data.display_name, data.description]
	var cost: Dictionary[GameEnums.ResourceType, float] = data.get_cost()
	if not cost.is_empty():
		var parts: Array[String] = []
		for t: GameEnums.ResourceType in cost.keys():
			parts.append("%s %d" % [GameEnums.resource_name(t), int(cost[t])])
		lines.append(" · ".join(parts))
	if locked:
		lines.append("Нужно исследование: %s" % _find_research_name(data.required_research))
	elif at_limit:
		lines.append("Построено максимум")
	return "\n".join(lines)


func _find_research_name(id: StringName) -> String:
	for r: ResearchData in _research.get_all():
		if r.id == id:
			return r.display_name
	return String(id)


func _rebuild_abilities() -> void:
	for child: Node in ability_bar.get_children():
		child.queue_free()
	_ability_buttons.clear()
	if _abilities == null:
		return
	for ability: Ability in _abilities.get_available():
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(64.0, 64.0)
		btn.icon = ability.icon
		btn.expand_icon = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = "%s\n%s" % [ability.display_name, ability.description]
		btn.pressed.connect(func() -> void: ability_requested.emit(ability))

		var cd_lbl: Label = Label.new()
		cd_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd_lbl.add_theme_font_size_override("font_size", 22)
		cd_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cd_lbl)

		ability_bar.add_child(btn)
		_ability_buttons.append(AbilityButtonEntry.new(btn, cd_lbl, ability))
	_refresh_abilities()


func _refresh_abilities() -> void:
	for item: AbilityButtonEntry in _ability_buttons:
		if item.ability.is_active():
			item.btn.disabled = true
			item.btn.modulate = Color(0.45, 0.95, 0.55)
			item.label.text = "%d" % int(ceilf(item.ability.get_active_left()))
		elif item.ability.get_cooldown_left() > 0.0:
			item.btn.disabled = true
			item.btn.modulate = Color(0.55, 0.55, 0.55)
			item.label.text = "%d" % int(ceilf(item.ability.get_cooldown_left()))
		else:
			item.btn.disabled = false
			item.btn.modulate = Color.WHITE
			item.label.text = ""


func _on_build_mode_changed(_mode: BuildController.Mode, _data: BuildingData) -> void:
	_refresh_build_bar()


func _process(_delta: float) -> void:
	if _context == null:
		return
	_refresh_wave_panel()
	_refresh_abilities()
	if building_panel.visible:
		building_panel.refresh()


func _refresh_wave_panel() -> void:
	var idx: int = _waves.get_wave_index()
	var total: int = _waves.get_total_waves()
	call_wave_btn.visible = _waves.can_call_early()
	if _waves.is_breakthrough_active():
		wave_label.text = "ПРОРЫВ ВРАГА!"
		wave_label.modulate = Color(1.0, 0.25, 0.25)
		wave_progress.value = 100.0
		wave_progress.tooltip_text = "Враг совершил научный прорыв"
		return
	if _waves.is_breakthrough_announced():
		var bt_secs: int = int(ceilf(_waves.get_breakthrough_countdown()))
		wave_label.text = "ПРОРЫВ: 0:%02d" % bt_secs
		wave_label.modulate = Color(1.0, 0.3, 0.3)
		wave_progress.value = clampf((1.0 - _waves.get_breakthrough_countdown() / maxf(1.0, _waves.breakthrough_delay)) * 100.0, 0.0, 100.0)
		wave_progress.tooltip_text = "До волны прорыва: 0:%02d" % bt_secs
		return
	wave_label.modulate = Color.WHITE
	wave_label.text = "Волна %d/%d" % [idx, total]
	if idx >= total:
		wave_progress.value = 100.0
		wave_progress.tooltip_text = "Идёт финальная волна"
	else:
		var left: float = _waves.get_time_to_next_wave()
		var interval: float = maxf(1.0, _waves.get_wave_interval())
		wave_progress.value = clampf((1.0 - left / interval) * 100.0, 0.0, 100.0)
		var secs: int = int(ceilf(left))
		wave_progress.tooltip_text = "До волны: %d:%02d" % [floori(float(secs) / 60.0), secs % 60]
