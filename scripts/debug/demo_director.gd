class_name DemoDirector
extends CanvasLayer

class TimelineAction extends RefCounted:
	var at_sec: float
	var fn: Callable
	var done: bool = false

	func _init(p_at: float, p_fn: Callable) -> void:
		at_sec = p_at
		fn = p_fn


var _mode: String = ""
var _capture_dir: String = ""
var _context: GameContext
var _main: Node2D
var _research: ResearchManager
var _waves: WaveManager
var _abilities: AbilityManager
var _build_controller: BuildController
var _hud: HUD
var _research_panel: ResearchPanel
var _intro_screen: IntroScreen
var _camera: CameraController
var _buildings_by_id: Dictionary[StringName, BuildingData] = {}
var _enemy_db: Dictionary[StringName, EnemyData] = {}

var _elapsed: float = 0.0
var _actions: Array[TimelineAction] = []
var _end_at: float = 0.0
var _finished: bool = false

var _cursor_pos: Vector2 = Vector2(640.0, 360.0)
var _cursor_target: Vector2 = Vector2(640.0, 360.0)
var _click_ripple: float = 0.0
var _click_pos: Vector2 = Vector2.ZERO
var _cursor_visible: bool = false

var _banner_panel: PanelContainer
var _banner_label: Label
var _side_panel: PanelContainer
var _side_label: Label
var _cursor_draw: Control


func configure(
	p_main: Node2D,
	p_context: GameContext,
	p_buildings: Dictionary[StringName, BuildingData],
	p_enemies: Dictionary[StringName, EnemyData],
	p_research: ResearchManager,
	p_waves: WaveManager,
	p_abilities: AbilityManager,
	p_bc: BuildController,
	p_hud: HUD,
	p_rp: ResearchPanel,
	p_intro: IntroScreen,
	p_camera: CameraController
) -> void:
	_main = p_main
	_context = p_context
	_buildings_by_id = p_buildings
	_enemy_db = p_enemies
	_research = p_research
	_waves = p_waves
	_abilities = p_abilities
	_build_controller = p_bc
	_hud = p_hud
	_research_panel = p_rp
	_intro_screen = p_intro
	_camera = p_camera

	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--record-demo="):
			_mode = arg.substr("--record-demo=".length()).strip_edges()
		elif arg.begins_with("--capture-pack="):
			_mode = "capture_pack"
			_capture_dir = arg.substr("--capture-pack=".length()).strip_edges()

	if _mode.is_empty():
		visible = false
		return

	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay_ui()
	_schedule_mode()


func is_active() -> bool:
	return not _mode.is_empty()


func should_skip_intro() -> bool:
	return _mode in ["invalid_data", "new_element"]


func _build_overlay_ui() -> void:
	_banner_panel = PanelContainer.new()
	_banner_panel.visible = false
	_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_panel.anchor_left = 0.5
	_banner_panel.anchor_right = 0.5
	_banner_panel.offset_left = -390.0
	_banner_panel.offset_right = 390.0
	_banner_panel.offset_top = 574.0
	_banner_panel.offset_bottom = 622.0
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.05, 0.03, 0.90)
	st.border_color = Color(0.96, 0.78, 0.25, 0.9)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	st.set_content_margin_all(8)
	_banner_panel.add_theme_stylebox_override("panel", st)
	_banner_label = Label.new()
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 17)
	_banner_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.65))
	_banner_panel.add_child(_banner_label)
	add_child(_banner_panel)

	_side_panel = PanelContainer.new()
	_side_panel.visible = false
	_side_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side_panel.offset_left = 14.0
	_side_panel.offset_top = 92.0
	_side_panel.offset_right = 470.0
	_side_panel.offset_bottom = 355.0
	var st2: StyleBoxFlat = st.duplicate()
	st2.bg_color = Color(0.06, 0.05, 0.03, 0.92)
	_side_panel.add_theme_stylebox_override("panel", st2)
	_side_label = Label.new()
	_side_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side_label.add_theme_font_size_override("font_size", 14)
	_side_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	_side_panel.add_child(_side_label)
	add_child(_side_panel)

	_cursor_draw = Control.new()
	_cursor_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cursor_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_draw.draw.connect(_on_draw_cursor)
	add_child(_cursor_draw)


func _on_draw_cursor() -> void:
	if _click_ripple > 0.0:
		var t: float = 1.0 - _click_ripple / 0.35
		var r: float = 8.0 + t * 22.0
		_cursor_draw.draw_arc(_click_pos, r, 0.0, TAU, 24, Color(1.0, 0.88, 0.3, (1.0 - t) * 0.95), 2.5)
	if not _cursor_visible:
		return
	var p: Vector2 = _cursor_pos
	var pts: PackedVector2Array = PackedVector2Array([
		p,
		p + Vector2(0.0, 22.0),
		p + Vector2(6.5, 16.5),
		p + Vector2(12.0, 25.0),
		p + Vector2(15.5, 23.0),
		p + Vector2(10.0, 14.5),
		p + Vector2(17.5, 14.0),
	])
	_cursor_draw.draw_colored_polygon(pts, Color(1.0, 0.95, 0.72, 0.98))
	var outline: PackedVector2Array = pts.duplicate()
	outline.append(pts[0])
	_cursor_draw.draw_polyline(outline, Color(0.1, 0.07, 0.03, 1.0), 2.0)


func _set_banner(text: String) -> void:
	if text.is_empty():
		_banner_panel.visible = false
	else:
		_banner_panel.visible = true
		_banner_label.text = text


func _move_cursor_to_screen(pos: Vector2) -> void:
	_cursor_visible = true
	_cursor_target = pos


func _move_cursor_to_cell(cell: Vector2i) -> void:
	var gpos: Vector2 = _context.arena.cell_to_global(cell)
	_move_cursor_to_screen(_world_to_screen(gpos))


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return _main.get_viewport().get_canvas_transform() * world_pos


func _click_effect(screen_pos: Vector2) -> void:
	_cursor_visible = true
	_cursor_pos = screen_pos
	_cursor_target = screen_pos
	_click_pos = screen_pos
	_click_ripple = 0.35


func _click_cell(cell: Vector2i) -> void:
	var sp: Vector2 = _world_to_screen(_context.arena.cell_to_global(cell))
	_click_effect(sp)


func _at(sec: float, fn: Callable) -> void:
	_actions.append(TimelineAction.new(sec, fn))


func _save_shot(filename: String) -> void:
	if _capture_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	var img: Image = _main.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_capture_dir.path_join(filename))


func _process(delta: float) -> void:
	if _mode.is_empty() or _finished:
		return
	var real_dt: float = delta / maxf(0.01, Engine.time_scale)
	_elapsed += real_dt
	_cursor_pos = _cursor_pos.lerp(_cursor_target, minf(1.0, real_dt * 10.0))
	if _click_ripple > 0.0:
		_click_ripple = maxf(0.0, _click_ripple - real_dt)
	_cursor_draw.queue_redraw()

	for act: TimelineAction in _actions:
		if not act.done and _elapsed >= act.at_sec:
			act.done = true
			act.fn.call()

	if _elapsed >= _end_at:
		_finished = true
		_main.get_tree().quit()


func _schedule_mode() -> void:
	match _mode:
		"main_cycle":
			_schedule_main_cycle()
		"invalid_data":
			_schedule_invalid_data()
		"new_element":
			_schedule_new_element()
		"capture_pack":
			_schedule_capture_pack()
		_:
			_end_at = 1.0


func _place_comb_safe(cell: Vector2i) -> void:
	if _context.arena.can_place_comb(cell) and _context.bank.try_spend(GameEnums.ResourceType.WAX, _context.balance.comb_wax_cost):
		_context.arena.place_comb(cell)


func _build_safe(cell: Vector2i, id: StringName) -> Building:
	var d: BuildingData = _buildings_by_id.get(id)
	if d == null:
		return null
	if not _context.arena.can_place_building(cell, d).is_empty():
		return null
	if not _context.bank.spend(d.get_cost()):
		return null
	return _context.arena.place_building(cell, d, false)


func _grant_resources(wax: float, honey: float, pollen: float = 40.0, nectar: float = 40.0) -> void:
	_context.bank.add(GameEnums.ResourceType.WAX, wax)
	_context.bank.add(GameEnums.ResourceType.HONEY, honey)
	_context.bank.add(GameEnums.ResourceType.POLLEN, pollen)
	_context.bank.add(GameEnums.ResourceType.NECTAR, nectar)


func _schedule_main_cycle() -> void:
	_cursor_visible = true
	_cursor_pos = Vector2(640.0, 250.0)
	_cursor_target = Vector2(640.0, 445.0)
	_set_banner("Слайд 1–3 · Запуск игры → Инициализация GameDatabase и GameContext")

	_at(2.5, func() -> void:
		_click_effect(Vector2(640.0, 445.0))
		_intro_screen.start_requested.emit()
		_camera.set_zoom_level(1.65)
		_set_banner("Слайд 3 · Фаза 1: Сбор ресурсов и проверка территории сот (Arena)")
	)
	_at(5.5, func() -> void:
		_move_cursor_to_cell(Vector2i(4, -2))
		_build_controller.start_build(_buildings_by_id[&"lab"])
		_build_controller._hover_cell = Vector2i(4, -2)
		_build_controller.queue_redraw()
		_hud.show_message("Сначала нарисуйте соты под все клетки (3)")
		_set_banner("Слайд 4–5 · Валидация: без сот постройка запрещена (Arena.can_place_building)")
	)
	_at(10.0, func() -> void:
		_build_controller.toggle_comb_mode()
		_set_banner("Слайд 4–5 · Инструмент «Соты»: ручное расширение территории за Воск")
	)
	var lab_combs: Array[Vector2i] = [Vector2i(4, -2), Vector2i(4, -3)]
	for idx: int in range(lab_combs.size()):
		var c: Vector2i = lab_combs[idx]
		_at(11.5 + float(idx) * 1.4, func() -> void:
			_click_cell(c)
			_build_controller._hover_cell = c
			_place_comb_safe(c)
		)
	_at(17.0, func() -> void:
		_build_controller.start_build(_buildings_by_id[&"lab"])
		_build_controller._hover_cell = Vector2i(3, -2)
		_move_cursor_to_cell(Vector2i(3, -2))
		_build_controller.queue_redraw()
		_set_banner("Слайд 4–5 · Все 7 гексов на сотах — зелёное превью постройки Лаборатории")
	)
	_at(19.5, func() -> void:
		_click_cell(Vector2i(3, -2))
		var b: Building = _build_safe(Vector2i(3, -2), &"lab")
		_build_controller.select_building(b)
		_build_controller.cancel()
		_set_banner("Слайд 5 · Приоритет строителей (Colony): постройка чертежа раньше ремонта")
	)
	_at(24.0, func() -> void:
		_click_cell(Vector2i(-1, -2))
		var bal: Building = _build_safe(Vector2i(-1, -2), &"ballista")
		_build_controller.select_building(bal)
		_set_banner("Слайд 4–6 · Баллиста построена из Ballista.tres (TowerData → TowerBehavior)")
	)
	_at(27.5, func() -> void:
		_click_cell(Vector2i(-2, 2))
		_build_safe(Vector2i(-2, 2), &"kindergarten")
	)
	_at(31.0, func() -> void:
		Engine.time_scale = 2.0
		_hud.set_pause_speed_state(false, 2.0)
	)
	_at(36.0, func() -> void:
		Engine.time_scale = 1.0
		_hud.set_pause_speed_state(false, 1.0)
		var wax_b: Building = _context.arena.get_building_at(Vector2i(0, 2))
		if wax_b != null:
			_click_cell(Vector2i(0, 2))
			_build_controller.select_building(wax_b)
		_set_banner("Слайд 7 · Управление слотами рабочих [- / +] в BuildingPanel без сноса здания")
	)
	_at(39.0, func() -> void:
		var wax_b: Building = _context.arena.get_building_at(Vector2i(0, 2))
		if wax_b != null:
			_main._on_workers_adjust_requested(wax_b, -1)
	)
	_at(42.0, func() -> void:
		_click_effect(Vector2(380.0, 42.0))
		_hud.open_retrain_panel()
		_set_banner("Слайд 7 · Переквалификация: Собиратель → Воин по золотой орбите Королевы")
	)
	_at(44.5, func() -> void:
		_click_effect(Vector2(215.0, 180.0))
		_context.colony.retrain_bee(GameEnums.BeeRole.GATHERER, GameEnums.BeeRole.SOLDIER)
	)
	_at(49.5, func() -> void:
		_hud.close_retrain_panel()
		var bal: Building = _context.arena.get_building_at(Vector2i(-1, -2))
		if bal != null:
			_build_controller.select_building(bal)
		_set_banner("Слайд 8 · Воин заступает в Баллисту: «Нет воинов» → «Работает»")
	)
	_at(53.0, func() -> void:
		_grant_resources(280.0, 280.0, 120.0, 120.0)
		_research_panel.open()
		_set_banner("Слайд 8 · Дерево технологий (ResearchManager): Копьё → Электрожало → Элитный полк")
	)
	_at(55.5, func() -> void:
		for r: ResearchData in _research.get_all():
			if r.id == &"spear":
				_research.start(r)
				_research.complete_current_instantly()
			elif r.id == &"tesla_spire":
				_research.start(r)
				_research.complete_current_instantly()
			elif r.id == &"elite_regiment":
				_research.start(r)
		_set_banner("Слайд 8 · Разблокировка Электрожала, Ярости роя и новой башни из данных")
	)
	_at(59.0, func() -> void:
		_research.complete_current_instantly()
		for r: ResearchData in _research.get_all():
			if r.id == &"agitation" or r.id == &"translator":
				_research._completed[r.id] = true
		_research.research_completed.emit(_research.get_all()[0])
		_research_panel.close()
	)
	_at(61.5, func() -> void:
		_click_cell(Vector2i(1, -2))
		_build_safe(Vector2i(1, -2), &"tesla_spire")
		if _buildings_by_id.has(&"amber_blaster"):
			_click_cell(Vector2i(2, 1))
			_build_safe(Vector2i(2, 1), &"amber_blaster")
		Engine.time_scale = 2.5
		_hud.set_pause_speed_state(false, 2.5)
		_set_banner("Слайд 8 · Постройка Электрожала и Прополисного стреломёта + апгрейд ★2")
	)
	_at(68.0, func() -> void:
		Engine.time_scale = 1.0
		_hud.set_pause_speed_state(false, 1.0)
		var bal: Building = _context.arena.get_building_at(Vector2i(-1, -2))
		if bal != null and bal.can_upgrade():
			bal.upgrade()
			_build_controller.select_building(bal)
		for i: int in range(3):
			_context.colony.spawn_bee(GameEnums.BeeRole.SOLDIER, _context.queen.global_position)
	)
	_at(72.0, func() -> void:
		_click_effect(Vector2(738.0, 32.0))
		_waves.call_next_wave_early()
		_set_banner("Слайд 8 · Досрочный вызов волны (+15 воска, +10 мёда) → Штурм шершней и пауков")
	)
	_at(79.0, func() -> void:
		_waves.call_next_wave_early()
		_set_banner("Слайд 8 · Разведение пауков (без слипания), цепная молния и турели в бою")
	)
	_at(85.0, func() -> void:
		var abs: Array[Ability] = _abilities.get_available()
		for ab: Ability in abs:
			if ab is SwarmFuryAbility or ab is AgitationAbility:
				_abilities.activate(ab)
		_set_banner("Слайд 8 · Способности: «Ярость роя» (x2 скорость) и «Агитация» (союзные шершни)")
	)
	_at(96.0, func() -> void:
		_research._completed[&"reinforced_wax"] = true
		_research._completed[&"general_battle"] = true
		_waves.spawn_boss()
		_set_banner("Слайд 8 · Финальная ветка «Генеральное сражение» → Босс Королева шершней")
	)
	_at(103.0, func() -> void:
		Engine.time_scale = 2.0
		_hud.set_pause_speed_state(false, 2.0)
		# Add an extra ballista & tesla for fast decisive battle finish
		_grant_resources(200.0, 200.0)
		_context.modifiers.add(StatModifiers.TOWER_DAMAGE, 2.5)
	)
	_at(118.0, func() -> void:
		Engine.time_scale = 1.0
		_hud.set_pause_speed_state(false, 1.0)
		# Ensure victory screen triggers cleanly if boss still slightly alive
		for e: Enemy in _context.get_hostile_enemies():
			if e.data != null and e.data.id == &"hornet_queen":
				e.health.take_damage(99999.0)
		_set_banner("Слайд 3, 8 · EndingController → Завершение цикла: Победа «Истребление»!")
	)
	_end_at = 126.0


func _schedule_invalid_data() -> void:
	_cursor_visible = true
	_cursor_pos = Vector2(750.0, 350.0)
	_cursor_target = Vector2(750.0, 350.0)
	_camera.set_zoom_level(1.6)
	_side_panel.visible = true

	var lines: Array[String] = [
		"СРЕДНИЙ УРОВЕНЬ (C5–C7): DATA VALIDATOR",
		"Поданы ошибочные и граничные значения:",
		"• test_corrupt_tower: cost_wax = -80, max_hp = -25,",
		"  fire_interval = 0.0, worker_slots = -2, icon = null",
		"• test_corrupt_bug: max_hp = -10, speed = -5, visual = null",
		"• wave_01: несуществующий 'ghost_ant', count = -4",
		"──────────────────────────────────────",
		"РЕАКЦИЯ СИСТЕМЫ (исправлено %d ошибок):" % _context.validation_warnings.size(),
		"✓ Цены зажаты >= 0.0, max_hp >= 1.0, interval >= 0.08",
		"✓ Подставлены безопасные иконки и HornetVisual",
		"✓ Неизвестный враг пропущен без сбоя спавна",
	]
	_side_label.text = "\n".join(lines)
	_set_banner("Средний уровень (C5–C7) · Контролируемая валидация битых конфигов без сбоя игры")

	_at(4.0, func() -> void:
		_place_comb_safe(Vector2i(4, -2))
		_place_comb_safe(Vector2i(4, -1))
		var b: Building = _build_safe(Vector2i(4, -2), &"test_corrupt_tower")
		if b != null:
			_click_cell(Vector2i(4, -2))
			_build_controller.select_building(b)
	)
	_at(11.0, func() -> void:
		_waves.start_next_wave_now()
		_set_banner("Волна 1 запущена с исправленными данными: state игры целостный, 0 падений")
	)
	_at(18.0, func() -> void:
		Engine.time_scale = 2.0
		_hud.set_pause_speed_state(false, 2.0)
	)
	_end_at = 32.0


func _schedule_new_element() -> void:
	_cursor_visible = true
	_cursor_pos = Vector2(640.0, 350.0)
	_cursor_target = Vector2(640.0, 350.0)
	_camera.set_zoom_level(1.75)
	_side_panel.visible = true
	_side_panel.offset_right = 450.0
	_side_panel.offset_bottom = 290.0
	_side_label.text = "\n".join([
		"ВЫСШИЙ УРОВЕНЬ (C8–C9): РАСШИРЕНИЕ ЧЕРЕЗ ДАННЫЕ",
		"Добавлен новый элемент без изменения кода (.gd = 0):",
		"1. assets/icons/bld_amber_blaster.svg",
		"2. assets/data/buildings/amber_blaster.tres (TowerData)",
		"   • Прополисный стреломёт (Земля + Воздух)",
		"   • damage = 12, fire_interval = 0.6, slow = 0.82",
		"   • required_research = &'spear'",
		"────────────────────────────────────",
		"GameDatabase.load_buildings() обнаружил файл",
		"автоматически — башня уже в панели стройки!",
	])
	_set_banner("Высший уровень (C8–C9) · Новая башня «Прополисный стреломёт» из .tres без правки кода")

	_at(2.5, func() -> void:
		_grant_resources(180.0, 120.0)
		_research._completed[&"spear"] = true
		_research.research_completed.emit(_research.get_all()[0])
		_move_cursor_to_screen(Vector2(860.0, 680.0))
	)
	_at(6.0, func() -> void:
		_click_effect(Vector2(860.0, 680.0))
		_build_controller.start_build(_buildings_by_id[&"amber_blaster"])
		_build_controller._hover_cell = Vector2i(-2, -1)
		_move_cursor_to_cell(Vector2i(-2, -1))
		_build_controller.queue_redraw()
	)
	_at(8.5, func() -> void:
		_click_cell(Vector2i(-2, -1))
		var ab1: Building = _build_safe(Vector2i(-2, -1), &"amber_blaster")
		_build_controller.select_building(ab1)
		_click_cell(Vector2i(2, 1))
		_build_safe(Vector2i(2, 1), &"amber_blaster")
		_build_controller.cancel()
		for i: int in range(2):
			_context.colony.spawn_bee(GameEnums.BeeRole.SOLDIER, _context.queen.global_position)
	)
	_at(14.0, func() -> void:
		Engine.time_scale = 2.0
		_hud.set_pause_speed_state(false, 2.0)
	)
	_at(19.0, func() -> void:
		Engine.time_scale = 1.0
		_hud.set_pause_speed_state(false, 1.0)
		_waves.start_next_wave_now()
		_set_banner("Новая башня стреляет по наземным и воздушным врагам, замедляя их липкой смолой!")
	)
	_at(23.0, func() -> void:
		_waves.start_next_wave_now()
	)
	_end_at = 38.0


func _schedule_capture_pack() -> void:
	_cursor_visible = false
	_banner_panel.visible = false
	_side_panel.visible = false

	_at(0.3, func() -> void: _save_shot("01_intro_screen.png"))
	_at(0.6, func() -> void:
		_intro_screen.start_requested.emit()
		_camera.set_zoom_level(1.55)
		_grant_resources(300.0, 300.0, 100.0, 100.0)
	)
	_at(4.5, func() -> void:
		_save_shot("02_gameplay_calm.png")
		_camera.set_zoom_level(2.4)
		_hud.open_retrain_panel()
		_context.colony.retrain_bee(GameEnums.BeeRole.GATHERER, GameEnums.BeeRole.SOLDIER)
		_context.colony.retrain_bee(GameEnums.BeeRole.GATHERER, GameEnums.BeeRole.BUILDER)
	)
	_at(6.5, func() -> void:
		_save_shot("03_queen_retrain.png")
		_hud.close_retrain_panel()
		_camera.set_zoom_level(1.75)
		_build_controller.start_build(_buildings_by_id[&"lab"])
		_build_controller._hover_cell = Vector2i(4, -2)
		_build_controller.queue_redraw()
	)
	_at(7.0, func() -> void:
		_save_shot("04_comb_build_preview.png")
		_build_controller.cancel()
		for c: Vector2i in [Vector2i(4, -2), Vector2i(4, -3)]:
			_place_comb_safe(c)
		_context.arena.place_building(Vector2i(3, -2), _buildings_by_id[&"lab"], true)
		_research_panel.open()
		_research._completed[&"spear"] = true
		_research._completed[&"translator"] = true
		_research.start(_research.get_all()[1])
	)
	_at(7.6, func() -> void:
		_save_shot("05_research_panel.png")
		_research_panel.close()
		# Unlock all for showcase
		for r: ResearchData in _research.get_all():
			_research._completed[r.id] = true
		_research.research_completed.emit(_research.get_all()[0])
		var wax_b: Building = _context.arena.get_building_at(Vector2i(0, 2))
		_build_controller.select_building(wax_b)
	)
	_at(8.2, func() -> void:
		_save_shot("06_building_panel_workers.png")
		# Mechanic Sequence 1: Sleeping ballista + retrain -> active firing
		var bal: Building = _context.arena.place_building(Vector2i(-1, -2), _buildings_by_id[&"ballista"], true)
		bal.set_desired_operators(0)
		_build_controller.select_building(bal)
		_camera.set_zoom_level(2.15)
	)
	_at(8.6, func() -> void:
		_save_shot("13_mech_frame_1.png")
		var bal: Building = _context.arena.get_building_at(Vector2i(-1, -2))
		if bal != null:
			bal.set_desired_operators(1)
		_hud.open_retrain_panel()
		_context.colony.retrain_bee(GameEnums.BeeRole.GATHERER, GameEnums.BeeRole.SOLDIER)
	)
	_at(9.3, func() -> void:
		_save_shot("13_mech_frame_2.png")
		_hud.close_retrain_panel()
		_context.colony.trigger_assign_now()
		_waves.spawn_enemy(_enemy_db[&"spider"], _context.arena.global_position + Vector2(-70.0, -145.0))
	)
	_at(10.6, func() -> void:
		_save_shot("13_mech_frame_3.png")
		_context.colony.trigger_assign_now()
	)
	_at(11.8, func() -> void:
		_save_shot("13_mech_frame_4.png")
		_build_controller.select_building(null)
		# Spawn showcase base + mixed enemies for combat shot
		_context.arena.place_building(Vector2i(1, -2), _buildings_by_id[&"tesla_spire"], true)
		_context.arena.place_building(Vector2i(-2, -1), _buildings_by_id[&"honey_mortar"], true)
		if _buildings_by_id.has(&"amber_blaster"):
			_context.arena.place_building(Vector2i(2, 1), _buildings_by_id[&"amber_blaster"], true)
		_context.arena.place_building(Vector2i(-2, 2), _buildings_by_id[&"storage"], true)
		for i: int in range(6):
			_context.colony.spawn_bee(GameEnums.BeeRole.SOLDIER, _context.queen.global_position)
		_context.colony.trigger_assign_now()
	)
	_at(13.2, func() -> void:
		# Spawn rich showcase enemy wave close enough to engage
		var center: Vector2 = _context.arena.global_position
		for a_deg: float in [25.0, 42.0, 58.0]:
			_waves.spawn_enemy(_enemy_db[&"spider"], center + Vector2.from_angle(deg_to_rad(a_deg)) * 225.0)
		for a_deg: float in [145.0, 175.0, 210.0]:
			_waves.spawn_enemy(_enemy_db[&"hornet"], center + Vector2.from_angle(deg_to_rad(a_deg)) * 235.0)
		_waves.spawn_enemy(_enemy_db[&"dragonfly"], center + Vector2.from_angle(deg_to_rad(280.0)) * 240.0)
		_waves.spawn_enemy(_enemy_db[&"ladybug"], center + Vector2.from_angle(deg_to_rad(320.0)) * 220.0)
		_waves.spawn_enemy(_enemy_db[&"mole_cricket"], center + Vector2(-45.0, 50.0))
		_waves.spawn_enemy(_enemy_db[&"hornet"], center + Vector2(60.0, -40.0), GameEnums.Faction.ALLY)
		_camera.set_zoom_level(1.45)
	)
	_at(15.6, func() -> void:
		_save_shot("07_combat_enemies_variety.png")
		var center: Vector2 = _context.arena.global_position
		_waves.spawn_enemy(_enemy_db[&"hornet_queen"], center + Vector2(-215.0, -70.0))
		_context.effects.set_breakthrough_alert(true)
	)
	_at(16.8, func() -> void:
		_save_shot("08_breakthrough_boss.png")
		_context.effects.set_breakthrough_alert(false)
		for e: Enemy in _context.get_enemies():
			e.queue_free()
		for c: Vector2i in [Vector2i(-3, 2), Vector2i(-3, 3), Vector2i(-2, 3), Vector2i(-4, 2), Vector2i(-4, 3), Vector2i(-2, 4), Vector2i(-3, 4)]:
			_place_comb_safe(c)
		_context.arena.place_building(Vector2i(-3, 3), _buildings_by_id[&"golden_hive"], true)
		_camera.set_zoom_level(1.55)
	)
	_at(17.5, func() -> void:
		_save_shot("09_golden_hive_wonder.png")
		_main._on_game_ended(GameEnums.Ending.ECONOMIC)
	)
	_at(18.0, func() -> void:
		_save_shot("10_ending_economic.png")
		_main._game_ended = false
		_main._on_game_ended(GameEnums.Ending.DIPLOMATIC)
	)
	_at(18.5, func() -> void:
		_save_shot("11_ending_diplomatic.png")
		_main._game_ended = false
		_main._on_game_ended(GameEnums.Ending.ENEMY_BREAKTHROUGH)
	)
	_at(19.0, func() -> void:
		_save_shot("12_ending_breakthrough.png")
	)
	_end_at = 19.5
