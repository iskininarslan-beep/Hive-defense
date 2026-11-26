class_name EffectsLayer
extends Node2D


class EffectParticle extends RefCounted:
	var pos: Vector2
	var vel: Vector2
	var color: Color
	var size: float
	var life: float
	var max_life: float

	func _init(p_pos: Vector2, p_vel: Vector2, p_color: Color, p_size: float, p_life: float) -> void:
		pos = p_pos
		vel = p_vel
		color = p_color
		size = p_size
		life = p_life
		max_life = maxf(0.05, p_life)


class EffectRing extends RefCounted:
	var pos: Vector2
	var max_radius: float
	var color: Color
	var life: float
	var max_life: float
	var filled_alpha: float

	func _init(p_pos: Vector2, p_max_radius: float, p_color: Color, p_duration: float, p_filled: float) -> void:
		pos = p_pos
		max_radius = p_max_radius
		color = p_color
		life = p_duration
		max_life = maxf(0.05, p_duration)
		filled_alpha = p_filled


class EffectLightning extends RefCounted:
	var points: PackedVector2Array
	var color: Color
	var life: float
	var max_life: float

	func _init(p_pts: PackedVector2Array, p_color: Color, p_duration: float) -> void:
		points = p_pts
		color = p_color
		life = p_duration
		max_life = maxf(0.05, p_duration)


class EffectText extends RefCounted:
	var pos: Vector2
	var text: String
	var color: Color
	var life: float
	var max_life: float

	func _init(p_pos: Vector2, p_text: String, p_color: Color, p_duration: float = 1.1) -> void:
		pos = p_pos
		text = p_text
		color = p_color
		life = p_duration
		max_life = maxf(0.05, p_duration)


const MAX_PARTICLES: int = 240
const MAX_RINGS: int = 32
const MAX_LIGHTNING: int = 24
const MAX_TEXTS: int = 32

var arena_center: Vector2 = Vector2(640.0, 335.0)
var arena_rim_radius: float = 255.0

var _particles: Array[EffectParticle] = []
var _rings: Array[EffectRing] = []
var _lightnings: Array[EffectLightning] = []
var _texts: Array[EffectText] = []
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
		_particles.append(EffectParticle.new(pos, Vector2(cos(a), sin(a)) * s, color, randf_range(2.0, 4.2), randf_range(0.25, 0.5)))
	queue_redraw()


func spawn_ring(pos: Vector2, max_radius: float, color: Color, duration: float = 0.45, filled_alpha: float = 0.0) -> void:
	if _rings.size() >= MAX_RINGS:
		_rings.pop_front()
	_rings.append(EffectRing.new(pos, max_radius, color, duration, filled_alpha))
	queue_redraw()


func spawn_lightning(points: PackedVector2Array, color: Color, duration: float = 0.16) -> void:
	if points.size() < 2:
		return
	if _lightnings.size() >= MAX_LIGHTNING:
		_lightnings.pop_front()
	_lightnings.append(EffectLightning.new(points, color, duration))
	queue_redraw()


func spawn_floating_text(pos: Vector2, text: String, color: Color) -> void:
	if _texts.size() >= MAX_TEXTS:
		_texts.pop_front()
	_texts.append(EffectText.new(pos, text, color, 1.1))
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
		var p: EffectParticle = _particles[i]
		p.life -= delta
		if p.life <= 0.0:
			_particles.remove_at(i)
		else:
			p.pos += p.vel * delta
			p.vel *= maxf(0.0, 1.0 - 4.0 * delta)
		dirty = true

	for i: int in range(_rings.size() - 1, -1, -1):
		var r: EffectRing = _rings[i]
		r.life -= delta
		if r.life <= 0.0:
			_rings.remove_at(i)
		dirty = true

	for i: int in range(_lightnings.size() - 1, -1, -1):
		var l: EffectLightning = _lightnings[i]
		l.life -= delta
		if l.life <= 0.0:
			_lightnings.remove_at(i)
		dirty = true

	for i: int in range(_texts.size() - 1, -1, -1):
		var t: EffectText = _texts[i]
		t.life -= delta
		if t.life <= 0.0:
			_texts.remove_at(i)
		else:
			t.pos += Vector2(0.0, -24.0) * delta
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

	for r: EffectRing in _rings:
		var t: float = 1.0 - r.life / r.max_life
		var alpha: float = clampf(r.life / r.max_life, 0.0, 1.0)
		var radius: float = r.max_radius * (0.35 + 0.65 * minf(1.0, t * 2.5))
		if r.filled_alpha > 0.0:
			draw_circle(r.pos, radius, Color(r.color.r, r.color.g, r.color.b, r.filled_alpha * alpha))
		draw_arc(r.pos, radius, 0.0, TAU, 32, Color(r.color.r, r.color.g, r.color.b, r.color.a * alpha), 2.5)

	for l: EffectLightning in _lightnings:
		var alpha: float = clampf(l.life / l.max_life, 0.0, 1.0)
		draw_polyline(l.points, Color(l.color.r, l.color.g, l.color.b, 0.75 * alpha), 5.0)
		draw_polyline(l.points, Color(1.0, 1.0, 1.0, alpha), 2.0)

	for p: EffectParticle in _particles:
		var alpha: float = clampf(p.life / p.max_life, 0.0, 1.0)
		draw_circle(p.pos, p.size, Color(p.color.r, p.color.g, p.color.b, alpha))

	var font: Font = ThemeDB.fallback_font
	for t: EffectText in _texts:
		var alpha: float = clampf(t.life / t.max_life, 0.0, 1.0)
		draw_string(font, t.pos + Vector2(-49.0, 1.0), t.text, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 14, Color(0.0, 0.0, 0.0, 0.8 * alpha))
		draw_string(font, t.pos + Vector2(-50.0, 0.0), t.text, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 14, Color(t.color.r, t.color.g, t.color.b, alpha))
