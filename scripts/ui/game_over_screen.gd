class_name GameOverScreen
extends Control

@onready var center_panel: PanelContainer = $CenterPanel
@onready var title_label: Label = $CenterPanel/VBox/TitleLabel
@onready var desc_label: Label = $CenterPanel/VBox/DescLabel
@onready var stats_label: Label = $CenterPanel/VBox/StatsLabel
@onready var restart_btn: Button = $CenterPanel/VBox/RestartBtn


func _ready() -> void:
	visible = false
	restart_btn.focus_mode = Control.FOCUS_NONE
	restart_btn.pressed.connect(func() -> void:
		Engine.time_scale = 1.0
		get_tree().paused = false
		get_tree().reload_current_scene()
	)


func show_ending(ending: GameEnums.Ending, elapsed_sec: float, wave_index: int, total_waves: int) -> void:
	title_label.text = EndingController.get_ending_title(ending)
	desc_label.text = EndingController.get_ending_text(ending)
	var secs: int = int(elapsed_sec)
	stats_label.text = "Время: %d:%02d  |  Волны: %d / %d" % [floori(float(secs) / 60.0), secs % 60, wave_index, total_waves]

	var title_col: Color = Color(1.0, 0.88, 0.35, 1.0)
	match ending:
		GameEnums.Ending.DIPLOMATIC:
			title_col = Color(0.45, 0.95, 0.62, 1.0)
		GameEnums.Ending.ECONOMIC:
			title_col = Color(1.0, 0.92, 0.36, 1.0)
		GameEnums.Ending.MILITARY:
			title_col = Color(1.0, 0.72, 0.28, 1.0)
		GameEnums.Ending.ENEMY_BREAKTHROUGH, GameEnums.Ending.DEFEAT:
			title_col = Color(1.0, 0.34, 0.30, 1.0)
	title_label.add_theme_color_override("font_color", title_col)

	visible = true
	center_panel.pivot_offset = center_panel.size * 0.5
	center_panel.scale = Vector2(0.92, 0.92)
	modulate.a = 0.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(center_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
