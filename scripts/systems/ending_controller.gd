class_name EndingController
extends Node

signal game_ended(ending: GameEnums.Ending)

var _ended: bool = false
var _waves: WaveManager


func setup(context: GameContext, research: ResearchManager, waves: WaveManager, arena: Arena) -> void:
	_waves = waves
	if is_instance_valid(context.queen):
		context.queen.health.died.connect(_on_queen_died)
	arena.building_placed.connect(func(b: Building) -> void:
		if b.data != null and b.data.id == &"queen":
			if not b.health.died.is_connected(_on_queen_died):
				b.health.died.connect(_on_queen_died)
	)
	arena.building_removed.connect(func(b: Building) -> void:
		if b.data != null and b.data.id == &"queen":
			_on_queen_died()
	)
	research.ending_unlocked.connect(func(ending: GameEnums.Ending) -> void:
		if ending == GameEnums.Ending.DIPLOMATIC:
			_trigger(GameEnums.Ending.DIPLOMATIC)
	)
	waves.boss_killed.connect(func() -> void: _trigger(GameEnums.Ending.MILITARY))
	arena.building_completed.connect(func(b: Building) -> void:
		if b.data != null and b.data.id == &"golden_hive":
			_trigger(GameEnums.Ending.ECONOMIC)
	)


func _on_queen_died() -> void:
	if _waves != null and _waves.is_breakthrough_active():
		_trigger(GameEnums.Ending.ENEMY_BREAKTHROUGH)
	else:
		_trigger(GameEnums.Ending.DEFEAT)


func _trigger(ending: GameEnums.Ending) -> void:
	if _ended or ending == GameEnums.Ending.NONE:
		return
	_ended = true
	game_ended.emit(ending)


static func get_ending_title(ending: GameEnums.Ending) -> String:
	match ending:
		GameEnums.Ending.MILITARY:
			return "«Истребление»"
		GameEnums.Ending.DIPLOMATIC:
			return "«Вечный мир»"
		GameEnums.Ending.ECONOMIC:
			return "«Золотой век»"
		GameEnums.Ending.ENEMY_BREAKTHROUGH:
			return "«Научный прорыв врага»"
		GameEnums.Ending.DEFEAT:
			return "«Улей пал»"
	return ""


static func get_ending_text(ending: GameEnums.Ending) -> String:
	match ending:
		GameEnums.Ending.MILITARY:
			return "Королева шершней повержена. Враги бегут, и больше никто не посмеет напасть на улей."
		GameEnums.Ending.DIPLOMATIC:
			return "Мирный договор подписан. Соседи согласились жить в мире с ульем."
		GameEnums.Ending.ECONOMIC:
			return "Золотой улей построен. Процветание колонии стало легендой."
		GameEnums.Ending.ENEMY_BREAKTHROUGH:
			return "Враг опередил колонию в развитии и сокрушил улей технологическим превосходством. Завершите одну из веток победы до прорыва."
		GameEnums.Ending.DEFEAT:
			return "Королева погибла. Колония рассеяна."
	return ""
