class_name DebugTools
extends Node

var _context: GameContext
var _research: ResearchManager
var _waves: WaveManager
var _camera: CameraController
var _skip_intro: bool = false
var _demo_lab: bool = false
var _demo_retrain: bool = false
var _demo_breakthrough: bool = false
var _has_zoom_override: bool = false
var _zoom_override: float = 2.0
var _screenshot_path: String = ""
var _screenshot_delay: float = 5.0
var _screenshot_elapsed: float = 0.0
var _screenshot_taken: bool = false


func setup(p_context: GameContext, p_research: ResearchManager, p_waves: WaveManager, p_camera: CameraController) -> void:
	_context = p_context
	_research = p_research
	_waves = p_waves
	_camera = p_camera
	if not OS.is_debug_build():
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--skip-intro":
			_skip_intro = true
		elif arg == "--demo-lab":
			_demo_lab = true
			_skip_intro = true
		elif arg == "--demo-retrain":
			_demo_retrain = true
			_skip_intro = true
		elif arg == "--demo-breakthrough":
			_demo_breakthrough = true
			_skip_intro = true
		elif arg.begins_with("--camera-zoom="):
			_has_zoom_override = true
			_zoom_override = float(arg.substr("--camera-zoom=".length()))
		elif arg.begins_with("--screenshot="):
			_screenshot_path = arg.substr("--screenshot=".length())
		elif arg.begins_with("--screenshot-delay="):
			_screenshot_delay = float(arg.substr("--screenshot-delay=".length()))
	if _has_zoom_override and _camera != null:
		_camera.set_zoom_level(_zoom_override)


func should_skip_intro() -> bool:
	return OS.is_debug_build() and _skip_intro


func should_demo_lab() -> bool:
	return OS.is_debug_build() and _demo_lab


func should_demo_retrain() -> bool:
	return OS.is_debug_build() and _demo_retrain


func should_demo_breakthrough() -> bool:
	return OS.is_debug_build() and _demo_breakthrough


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or _context == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kev: InputEventKey = event as InputEventKey
		match kev.keycode:
			KEY_F1:
				for t: GameEnums.ResourceType in [
					GameEnums.ResourceType.POLLEN,
					GameEnums.ResourceType.NECTAR,
					GameEnums.ResourceType.WAX,
					GameEnums.ResourceType.HONEY,
				]:
					_context.bank.add(t, _context.bank.get_capacity(t))
				get_viewport().set_input_as_handled()
			KEY_F2:
				if _research != null:
					_research.complete_current_instantly()
				get_viewport().set_input_as_handled()
			KEY_F3:
				if _waves != null:
					_waves.start_next_wave_now()
				get_viewport().set_input_as_handled()
			KEY_F4:
				Engine.time_scale = 1.0 if is_equal_approx(Engine.time_scale, 6.0) else 6.0
				get_viewport().set_input_as_handled()
			KEY_F5:
				if _waves != null:
					_waves.trigger_breakthrough_now()
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not OS.is_debug_build() or _screenshot_path.is_empty() or _screenshot_taken:
		return
	var scale: float = maxf(0.01, Engine.time_scale)
	_screenshot_elapsed += delta / scale
	if _screenshot_elapsed >= _screenshot_delay:
		_screenshot_taken = true
		_capture_and_quit()


func _capture_and_quit() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir_path: String = _screenshot_path.get_base_dir()
	if not dir_path.is_empty():
		DirAccess.make_dir_recursive_absolute(dir_path)
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_screenshot_path)
	get_tree().quit()
