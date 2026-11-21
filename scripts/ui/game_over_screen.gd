class_name GameOverScreen
extends Control

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
	visible = true
