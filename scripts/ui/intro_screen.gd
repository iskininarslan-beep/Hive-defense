class_name IntroScreen
extends Control

signal start_requested

@onready var start_btn: Button = $CenterPanel/VBox/StartBtn


func _ready() -> void:
	start_btn.focus_mode = Control.FOCUS_NONE
	start_btn.pressed.connect(func() -> void: start_requested.emit())
