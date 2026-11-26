extends Node2D

@onready var camera: CameraController = $Camera
@onready var bank: ResourceBank = $Systems/ResourceBank
@onready var colony: Colony = $Systems/Colony
@onready var research_manager: ResearchManager = $Systems/ResearchManager
@onready var wave_manager: WaveManager = $Systems/WaveManager
@onready var ability_manager: AbilityManager = $Systems/AbilityManager
@onready var ending_controller: EndingController = $Systems/EndingController

@onready var flower_field: FlowerField = $World/FlowerField
@onready var arena: Arena = $World/Arena
@onready var buildings_root: Node2D = $World/Buildings
@onready var bees_root: Node2D = $World/Bees
@onready var enemies_root: Node2D = $World/Enemies
@onready var projectiles_root: Node2D = $World/Projectiles
@onready var build_controller: BuildController = $World/BuildController
@onready var effects_layer: EffectsLayer = $World/EffectsLayer

@onready var hud: HUD = $UI/HUD
@onready var research_panel: ResearchPanel = $UI/ResearchPanel
@onready var game_over_screen: GameOverScreen = $UI/GameOverScreen
@onready var intro_screen: IntroScreen = $UI/IntroScreen
@onready var debug_tools: DebugTools = $DebugTools

var _demo_director: DemoDirector
var _context: GameContext
var _elapsed_time: float = 0.0
var _is_paused: bool = false
var _speed: float = 1.0
var _game_ended: bool = false
var _last_queen_hp: float = 600.0


func _ready() -> void:
	Engine.time_scale = 1.0
	var extra_dirs: PackedStringArray = GameDatabase.get_runtime_extra_dirs()
	var balance_cfg: GameBalanceConfig = GameDatabase.load_balance_config()
	var all_buildings: Array[BuildingData] = GameDatabase.load_buildings(extra_dirs)
	var all_enemies: Dictionary[StringName, EnemyData] = GameDatabase.load_enemies(extra_dirs)
	var all_research: Array[ResearchData] = GameDatabase.load_research(extra_dirs)
	var all_waves: Array[WaveData] = GameDatabase.load_waves(extra_dirs)
	var all_abilities: Array[AbilityData] = GameDatabase.load_abilities(extra_dirs)

	if debug_tools.should_test_invalid_data():
		debug_tools.inject_invalid_test_cases(balance_cfg, all_buildings, all_enemies, all_waves)

	var validator: DataValidator = DataValidator.new()
	validator.validate_all(balance_cfg, all_buildings, all_enemies, all_research, all_waves, all_abilities)

	_context = GameContext.new()
	_context.balance = balance_cfg
	_context.validation_warnings = validator.warnings
	_context.bank = bank
	_context.colony = colony
	_context.research = research_manager
	_context.modifiers = StatModifiers.new()
	_context.arena = arena
	_context.flower_field = flower_field
	_context.buildings_root = buildings_root
	_context.bees_root = bees_root
	_context.enemies_root = enemies_root
	_context.projectiles_root = projectiles_root
	_context.effects = effects_layer
	_context.camera = camera

	var buildings_by_id: Dictionary[StringName, BuildingData] = {}
	for b: BuildingData in all_buildings:
		buildings_by_id[b.id] = b

	bank.setup(balance_cfg.get_initial_resources(), balance_cfg.base_storage_capacity)
	arena.setup(_context)
	colony.setup(_context)
	research_manager.setup(_context, all_research)
	wave_manager.setup(_context, all_waves, all_enemies)
	ability_manager.setup(_context, all_abilities)
	ending_controller.setup(_context, research_manager, wave_manager, arena)
	build_controller.setup(_context)
	hud.setup(_context, all_buildings, research_manager, wave_manager, ability_manager, build_controller)
	research_panel.setup(_context, research_manager)
	debug_tools.setup(_context, research_manager, wave_manager, camera)

	arena.create_initial_base(buildings_by_id)
	colony.spawn_initial_bees()

	if is_instance_valid(_context.queen):
		_last_queen_hp = _context.queen.health.current
		_context.queen.health.health_changed.connect(_on_queen_health_changed)

	_connect_signals()

	if debug_tools.should_demo_lab() and buildings_by_id.has(&"lab"):
		arena.place_building(Vector2i(4, -2), buildings_by_id[&"lab"], true)
		research_panel.open()

	if debug_tools.should_demo_retrain():
		var qpos: Vector2 = _context.queen.global_position if is_instance_valid(_context.queen) else Vector2(640.0, 335.0)
		for i: int in range(7):
			colony.spawn_bee(GameEnums.BeeRole.SOLDIER, qpos)
		hud.open_retrain_panel()

	if debug_tools.should_demo_breakthrough():
		wave_manager.trigger_breakthrough_now()

	hud.refresh_all()

	_demo_director = DemoDirector.new()
	add_child(_demo_director)
	_demo_director.configure(
		self,
		_context,
		buildings_by_id,
		all_enemies,
		research_manager,
		wave_manager,
		ability_manager,
		build_controller,
		hud,
		research_panel,
		intro_screen,
		camera
	)

	if debug_tools.should_test_invalid_data():
		hud.show_message("DataValidator: исправлено %d ошибок данных — игра работает стабильно" % validator.warnings.size())

	if debug_tools.should_skip_intro() or _demo_director.should_skip_intro():
		intro_screen.visible = false
		get_tree().paused = false
	else:
		intro_screen.visible = true
		get_tree().paused = true
	hud.set_pause_speed_state(_is_paused, _speed)


func _connect_signals() -> void:
	hud.build_requested.connect(build_controller.start_build)
	hud.comb_mode_requested.connect(build_controller.toggle_comb_mode)
	hud.delete_mode_requested.connect(build_controller.toggle_delete_mode)
	hud.ability_requested.connect(_on_ability_requested)
	hud.pause_toggled.connect(_toggle_pause)
	hud.speed_cycle_requested.connect(_cycle_speed)
	hud.demolish_requested.connect(build_controller.demolish_building)
	hud.kindergarten_role_requested.connect(_on_kindergarten_role_requested)
	hud.lab_open_requested.connect(research_panel.open)
	hud.retrain_requested.connect(_on_retrain_requested)
	hud.upgrade_requested.connect(_on_upgrade_requested)
	hud.call_wave_requested.connect(wave_manager.call_next_wave_early)
	hud.workers_adjust_requested.connect(_on_workers_adjust_requested)

	build_controller.building_selected.connect(_on_building_selected)
	build_controller.pause_toggle_requested.connect(_toggle_pause)
	build_controller.message.connect(hud.show_message)

	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.boss_spawned.connect(func() -> void: hud.show_message("Королева шершней атакует улей!"))
	wave_manager.intel_message.connect(hud.show_message)
	wave_manager.enemy_breakthrough_announced.connect(_on_breakthrough_announced)
	wave_manager.breakthrough_wave_started.connect(_on_breakthrough_started)
	research_manager.research_completed.connect(_on_research_completed)
	ending_controller.game_ended.connect(_on_game_ended)
	intro_screen.start_requested.connect(_on_intro_started)


func _process(delta: float) -> void:
	if not _game_ended and not get_tree().paused:
		_elapsed_time += delta


func _on_queen_health_changed(current: float, _max_hp: float) -> void:
	if current < _last_queen_hp:
		camera.add_shake(8.5 if wave_manager.is_breakthrough_active() else 4.0)
	_last_queen_hp = current


func _on_intro_started() -> void:
	intro_screen.visible = false
	_is_paused = false
	get_tree().paused = false
	hud.set_pause_speed_state(_is_paused, _speed)


func _toggle_pause() -> void:
	if intro_screen.visible or _game_ended:
		return
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	hud.set_pause_speed_state(_is_paused, _speed)


func _cycle_speed() -> void:
	if is_equal_approx(_speed, 1.0):
		_speed = 2.0
	elif is_equal_approx(_speed, 2.0):
		_speed = 3.0
	else:
		_speed = 1.0
	Engine.time_scale = _speed
	hud.set_pause_speed_state(_is_paused, _speed)


func _on_building_selected(b: Building) -> void:
	hud.show_building(b)
	if is_instance_valid(b) and b.behavior is LabBehavior and b.is_built:
		research_panel.open()


func _on_retrain_requested(from_role: GameEnums.BeeRole, to_role: GameEnums.BeeRole) -> void:
	if not colony.retrain_bee(from_role, to_role):
		hud.show_message("Нет свободной пчелы этой роли")


func _on_workers_adjust_requested(b: Building, delta: int) -> void:
	if not is_instance_valid(b):
		return
	b.set_desired_operators(b.desired_operators + delta)
	colony.trigger_assign_now()
	hud.refresh_building_panel()


func _on_upgrade_requested(b: Building) -> void:
	if not is_instance_valid(b):
		return
	if b.upgrade():
		hud.refresh_building_panel()
	else:
		hud.show_message("Недостаточно ресурсов для улучшения")


func _on_ability_requested(ability: Ability) -> void:
	if not ability_manager.activate(ability):
		if ability is AgitationAbility:
			hud.show_message("Нет вражеских шершней для агитации")
		elif ability is FieldTalksAbility:
			hud.show_message("Нет врагов для переговоров")
		else:
			hud.show_message("Способность сейчас недоступна")


func _on_kindergarten_role_requested(b: Building, role: GameEnums.BeeRole) -> void:
	if is_instance_valid(b) and b.behavior is KindergartenBehavior:
		(b.behavior as KindergartenBehavior).set_role(role)
		hud.refresh_building_panel()


func _on_wave_started(index: int, _wave: WaveData, direction_text: String) -> void:
	hud.show_message("Волна %d/%d — %s!" % [index, wave_manager.get_total_waves(), direction_text])


func _on_breakthrough_announced() -> void:
	hud.show_message("ВРАГ СОВЕРШИЛ НАУЧНЫЙ ПРОРЫВ! Улей обречён в следующей волне!")


func _on_breakthrough_started() -> void:
	hud.show_message("ВОЛНА ПРОРЫВА! Враг атакует всеми силами!")


func _on_research_completed(data: ResearchData) -> void:
	hud.show_message("Изучено: %s" % data.display_name)
	if data.id == &"general_battle":
		wave_manager.spawn_boss()


func _on_game_ended(ending: GameEnums.Ending) -> void:
	if _game_ended:
		return
	_game_ended = true
	Engine.time_scale = 1.0
	get_tree().paused = true
	game_over_screen.show_ending(ending, _elapsed_time, wave_manager.get_wave_index(), wave_manager.get_total_waves())
