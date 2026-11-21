class_name ResearchPanel
extends Control

@onready var dim_rect: ColorRect = %Dim
@onready var center_panel: PanelContainer = %CenterPanel
@onready var header_icon: TextureRect = %HeaderIcon
@onready var close_btn: Button = %CloseBtn
@onready var columns_box: HBoxContainer = %BranchesColumns

var _context: GameContext
var _research: ResearchManager
var _cards: Array[Dictionary] = []
var _fade_tween: Tween = null


func _ready() -> void:
	visible = false
	header_icon.texture = GameIcons.BLD_LAB
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close)
	dim_rect.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
				close()
	)


func setup(p_context: GameContext, p_research: ResearchManager) -> void:
	_context = p_context
	_research = p_research
	_research.research_started.connect(func(_d: ResearchData) -> void: _refresh())
	_research.research_completed.connect(func(_d: ResearchData) -> void: _refresh())
	_build_tree()


func open() -> void:
	visible = true
	_refresh()
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.14)


func close() -> void:
	if not visible:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.12)
	_fade_tween.tween_callback(func() -> void: visible = false)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kev: InputEventKey = event as InputEventKey
		if kev.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible and _research != null and _research.get_current() != null:
		_refresh()


func _build_tree() -> void:
	for child: Node in columns_box.get_children():
		child.queue_free()
	_cards.clear()

	var branches: Array[GameEnums.ResearchBranch] = [
		GameEnums.ResearchBranch.MILITARY,
		GameEnums.ResearchBranch.BEES,
		GameEnums.ResearchBranch.DIPLOMACY,
	]
	for branch: GameEnums.ResearchBranch in branches:
		var col: VBoxContainer = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 10)
		columns_box.add_child(col)

		var title: Label = Label.new()
		title.text = GameEnums.branch_name(branch)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
		col.add_child(title)

		var by_tier: Dictionary[int, Array] = {}
		for r: ResearchData in _research.get_all():
			if r.branch == branch:
				if not by_tier.has(r.tier):
					by_tier[r.tier] = []
				(by_tier[r.tier] as Array).append(r)

		var tiers: Array[int] = []
		for t: int in by_tier.keys():
			tiers.append(t)
		tiers.sort()

		for t: int in tiers:
			var tier_items: Array = by_tier[t] as Array
			if tier_items.size() == 1:
				var r: ResearchData = tier_items[0] as ResearchData
				col.add_child(_create_card(r, false))
			else:
				var pair_row: HBoxContainer = HBoxContainer.new()
				pair_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				pair_row.add_theme_constant_override("separation", 8)
				for item_var: Variant in tier_items:
					var r: ResearchData = item_var as ResearchData
					pair_row.add_child(_create_card(r, true))
				col.add_child(pair_row)


func _create_card(r: ResearchData, compact: bool) -> VBoxContainer:
	var card: VBoxContainer = VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 3)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(170.0, 50.0) if compact else Vector2(340.0, 50.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.icon = r.icon
	btn.expand_icon = true
	btn.text = r.display_name
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 15 if compact else 18)
	btn.pressed.connect(func() -> void:
		if _research.start(r):
			_refresh()
	)
	card.add_child(btn)

	var cost_row: HBoxContainer = HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 6 if compact else 10)
	var cost: Dictionary[GameEnums.ResourceType, float] = r.get_cost()
	for t: GameEnums.ResourceType in cost.keys():
		var chip_icon: TextureRect = TextureRect.new()
		var sz: float = 18.0 if compact else 22.0
		chip_icon.custom_minimum_size = Vector2(sz, sz)
		chip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip_icon.texture = GameIcons.resource_icon(t)
		cost_row.add_child(chip_icon)

		var chip_lbl: Label = Label.new()
		chip_lbl.text = str(int(cost[t]))
		chip_lbl.add_theme_font_size_override("font_size", 15 if compact else 18)
		cost_row.add_child(chip_lbl)
	card.add_child(cost_row)

	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0.0, 7.0)
	bar.show_percentage = false
	bar.visible = false
	card.add_child(bar)

	_cards.append({"btn": btn, "bar": bar, "data": r})
	return card


func _refresh() -> void:
	if _research == null:
		return
	for item: Dictionary in _cards:
		var btn: Button = item["btn"] as Button
		var bar: ProgressBar = item["bar"] as ProgressBar
		var r: ResearchData = item["data"] as ResearchData
		var st: ResearchManager.State = _research.get_state(r)
		bar.visible = (st == ResearchManager.State.IN_PROGRESS)
		match st:
			ResearchManager.State.DONE:
				btn.modulate = Color(1.0, 0.85, 0.32)
				btn.disabled = true
			ResearchManager.State.IN_PROGRESS:
				btn.modulate = Color(0.45, 0.9, 1.0)
				btn.disabled = true
				bar.value = _research.get_progress_ratio() * 100.0
			ResearchManager.State.AVAILABLE:
				btn.modulate = Color.WHITE
				btn.disabled = false
			ResearchManager.State.LOCKED:
				btn.modulate = Color(0.45, 0.45, 0.45)
				btn.disabled = true
		btn.tooltip_text = _make_tooltip(r, st)


func _make_tooltip(r: ResearchData, st: ResearchManager.State) -> String:
	var lines: Array[String] = [r.display_name, r.description, "Время: %d с" % int(r.time)]
	if st != ResearchManager.State.DONE and st != ResearchManager.State.IN_PROGRESS:
		var reason: String = _research.get_block_reason(r)
		if not reason.is_empty():
			lines.append(reason)
	return "\n".join(lines)
