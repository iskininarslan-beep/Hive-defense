class_name CameraController
extends Camera2D

@export var edge_margin: float = 14.0
@export var pan_speed: float = 900.0
@export var zoom_min: float = 1.0
@export var zoom_max: float = 3.0
@export var zoom_step: float = 1.15
@export var start_zoom: float = 2.0
@export var bounds_center: Vector2 = Vector2(640.0, 335.0)
@export var bounds_half_extents: Vector2 = Vector2(420.0, 380.0)

var _shake: float = 0.0


func _ready() -> void:
	set_zoom_level(start_zoom)


func set_zoom_level(z: float) -> void:
	var clamped: float = clampf(z, zoom_min, zoom_max)
	zoom = Vector2.ONE * clamped
	_clamp_position()


func add_shake(amount: float) -> void:
	_shake = minf(22.0, _shake + amount)


func _process(delta: float) -> void:
	var real_delta: float = delta / maxf(Engine.time_scale, 0.01)
	if _shake > 0.05:
		_shake = maxf(0.0, _shake - 35.0 * real_delta)
		offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	elif offset != Vector2.ZERO:
		_shake = 0.0
		offset = Vector2.ZERO

	if not get_window().has_focus():
		return
	var vp: Viewport = get_viewport()
	var rect: Rect2 = vp.get_visible_rect()
	var mouse: Vector2 = vp.get_mouse_position()
	if not rect.has_point(mouse):
		return
	var dir: Vector2 = Vector2.ZERO
	if mouse.x <= rect.position.x + edge_margin:
		dir.x -= 1.0
	elif mouse.x >= rect.end.x - edge_margin:
		dir.x += 1.0
	if mouse.y <= rect.position.y + edge_margin:
		dir.y -= 1.0
	elif mouse.y >= rect.end.y - edge_margin:
		dir.y += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * pan_speed * real_delta / maxf(zoom.x, 0.1)
		_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var old_z: float = zoom.x
			var factor: float = zoom_step if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / zoom_step
			var new_z: float = clampf(old_z * factor, zoom_min, zoom_max)
			if not is_equal_approx(old_z, new_z):
				var vp_size: Vector2 = get_viewport().get_visible_rect().size
				var cursor_offset: Vector2 = get_viewport().get_mouse_position() - vp_size * 0.5
				var world_before: Vector2 = position + cursor_offset / old_z
				zoom = Vector2.ONE * new_z
				position = world_before - cursor_offset / new_z
				_clamp_position()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		position -= mm.relative / maxf(zoom.x, 0.1)
		_clamp_position()
		get_viewport().set_input_as_handled()


func _clamp_position() -> void:
	position.x = clampf(position.x, bounds_center.x - bounds_half_extents.x, bounds_center.x + bounds_half_extents.x)
	position.y = clampf(position.y, bounds_center.y - bounds_half_extents.y, bounds_center.y + bounds_half_extents.y)
