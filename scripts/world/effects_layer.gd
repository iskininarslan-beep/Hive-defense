class_name EffectsLayer
extends Node2D

const MAX_PARTICLES: int = 240
const MAX_RINGS: int = 32
const MAX_LIGHTNING: int = 24
const MAX_TEXTS: int = 32

var arena_center: Vector2 = Vector2(640.0, 335.0)
var arena_rim_radius: float = 255.0

var _particles: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _lightnings: Array[Dictionary] = []
var _texts: Array[Dictionary] = []
var _arrow_angle: float = 0.0
var _arrow_timer: float = 0.0
var _breakthrough_active: bool = false
var _pulse_time: float = 0.0


func spawn_burst(pos: Vector2, color: Color, count: int = 8, speed: float = 90.0) -> void:
	for i: int in range(count):
		if _particles.size() >= MAX_PARTICLES:
			_particles.pop_front()
		var a: float = randf() * TAU
		var s: float = randf_range(speed * 0.4, speed * 1.1)
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(a), sin(a)) * s,
			"color": color,
			"size": randf_range(2.0, 4.2),
			"life": randf_range(0.25, 0.5),
			"max_life": 0.5,
		})
	queue_redraw()


func spawn_ring(pos: Vector2, max_radius: float, color: Color, duration: float = 0.45, filled_alpha: float = 0.0) -> void:
	if _rings.size() >= MAX_RINGS:
		_rings.pop_front()
	_rings.append({
		"pos": pos,
		"max_radius": max_radius,
		"color": color,
		"life": duration,
		"max_life": maxf(0.05, duration),
		"filled_alpha": filled_alpha,
	})
	queue_redraw()


func spawn_lightning(points: PackedVector2Array, color: Color, duration: float = 0.16) -> void:
	if points.size() < 2:
		return
	if _lightnings.size() >= MAX_LIGHTNING:
		_lightnings.pop_front()
	_lightnings.append({
		"points": points,
		"color": color,
		"life": duration,
		"max_life": maxf(0.05, duration),
	})
	queue_redraw()


func spawn_floating_text(pos: Vector2, text: String, color: Color) -> void:
	if _texts.size() >= MAX_TEXTS:
		_texts.pop_front()
	_texts.append({
		"pos": pos,
		"text": text,
		"color": color,
		"life": 1.1,
		"max_life": 1.1,
	})
	queue_redraw()


func set_incoming_arrow(angle: float, duration: float = 8.0) -> void:
	_arrow_angle = angle
	_arrow_timer = duration
	queue_redraw()


func set_breakthrough_alert(active: bool) -> void:
	_breakthrough_active = active
	queue_redraw()


func _process(delta: float) -> void:
	var dirty: bool = false
	if _breakthrough_active:
		_pulse_time += delta
		dirty = true
	if _arrow_timer > 0.0:
		_arrow_timer = maxf(0.0, _arrow_timer - delta)
		_pulse_time += delta
		dirty = true

	for i: int in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			_particles.remove_at(i)
		else:
			p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
			p["vel"] = (p["vel"] as Vector2) * maxf(0.0, 1.0 - 4.0 * delta)
		dirty = true

	for i: int in range(_rings.size() - 1, -1, -1):
		var r: Dictionary = _rings[i]
		r["life"] = float(r["life"]) - delta
		if float(r["life"]) <= 0.0:
			_rings.remove_at(i)
		dirty = true

	for i: int in range(_lightnings.size() - 1, -1, -1):
		var l: Dictionary = _lightnings[i]
		l["life"] = float(l["life"]) - delta
		if float(l["life"]) <= 0.0:
			_lightnings.remove_at(i)
		dirty = true

	for i: int in range(_texts.size() - 1, -1, -1):
		var t: Dictionary = _texts[i]
		t["life"] = float(t["life"]) - delta
		if float(t["life"]) <= 0.0:
			_texts.remove_at(i)
		else:
			t["pos"] = (t["pos"] as Vector2) + Vector2(0.0, -24.0) * delta
		dirty = true

	if dirty:
		queue_redraw()


func _draw() -> void:
	if _breakthrough_active:
		var pulse: float = 0.4 + 0.45 * absf(sin(_pulse_time * 5.0))
		draw_arc(arena_center, arena_rim_radius + 4.0, 0.0, TAU, 72, Color(1.0, 0.12, 0.16, pulse), 6.0)

	if _arrow_timer > 0.0:
		var dir: Vector2 = Vector2(cos(_arrow_angle), sin(_arrow_angle))
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		var base: Vector2 = arena_center + dir * (arena_rim_radius + 16.0)
		var pulse_a: float = 0.5 + 0.5 * absf(sin(_pulse_time * 6.0))
		var tip: Vector2 = base - dir * 18.0
		var tri: PackedVector2Array = PackedVector2Array([
			tip,
			base + perp * 11.0,
			base - perp * 11.0,
		])
		draw_colored_polygon(tri, Color(1.0, 0.28, 0.22, pulse_a))

	for r: Dictionary in _rings:
		var t: float = 1.0 - float(r["life"]) / float(r["max_life"])
		var alpha: float = clampf(float(r["life"]) / float(r["max_life"]), 0.0, 1.0)
		var col: Color = r["color"] as Color
		var pos: Vector2 = r["pos"] as Vector2
		var radius: float = float(r["max_radius"]) * (0.35 + 0.65 * minf(1.0, t * 2.5))
		var filled_a: float = float(r["filled_alpha"])
		if filled_a > 0.0:
			draw_circle(pos, radius, Color(col.r, col.g, col.b, filled_a * alpha))
		draw_arc(pos, radius, 0.0, TAU, 32, Color(col.r, col.g, col.b, col.a * alpha), 2.5)

	for l: Dictionary in _lightnings:
		var alpha: float = clampf(float(l["life"]) / float(l["max_life"]), 0.0, 1.0)
		var pts: PackedVector2Array = l["points"] as PackedVector2Array
		var col: Color = l["color"] as Color
		draw_polyline(pts, Color(col.r, col.g, col.b, 0.75 * alpha), 5.0)
		draw_polyline(pts, Color(1.0, 1.0, 1.0, alpha), 2.0)

	for p: Dictionary in _particles:
		var alpha: float = clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
		var col: Color = p["color"] as Color
		draw_circle(p["pos"] as Vector2, float(p["size"]), Color(col.r, col.g, col.b, alpha))

	var font: Font = ThemeDB.fallback_font
	for t: Dictionary in _texts:
		var alpha: float = clampf(float(t["life"]) / float(t["max_life"]), 0.0, 1.0)
		var col: Color = t["color"] as Color
		var pos: Vector2 = t["pos"] as Vector2
		var msg: String = String(t["text"])
		draw_string(font, pos + Vector2(-49.0, 1.0), msg, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 14, Color(0.0, 0.0, 0.0, 0.8 * alpha))
		draw_string(font, pos + Vector2(-50.0, 0.0), msg, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 14, Color(col.r, col.g, col.b, alpha))
