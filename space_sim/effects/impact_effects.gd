class_name ImpactEffects
extends Node2D

var _effects: Array[Dictionary] = []
var render_scale := 1.0


func set_render_scale(new_scale: float) -> void:
	render_scale = new_scale


func spawn_impact(position_m: Vector2, energy: float, severity: float) -> void:
	var visual_radius := lerpf(18.0, 120.0, clampf(log(maxf(energy, 1.0)) / 35.0, 0.0, 1.0))
	_effects.append({
		"position_m": position_m,
		"age": 0.0,
		"life": lerpf(0.35, 1.2, clampf(severity, 0.0, 1.0)),
		"radius": visual_radius,
		"severity": clampf(severity, 0.0, 1.0),
	})
	queue_redraw()


func _process(delta: float) -> void:
	for effect in _effects:
		effect["age"] = float(effect["age"]) + delta
	_effects = _effects.filter(func(effect: Dictionary) -> bool: return float(effect["age"]) < float(effect["life"]))
	if not _effects.is_empty():
		queue_redraw()


func _draw() -> void:
	for effect in _effects:
		var t := float(effect["age"]) / float(effect["life"])
		var position_m: Vector2 = effect["position_m"]
		var center := position_m * render_scale
		var radius := float(effect["radius"]) * (0.35 + t)
		var alpha := 1.0 - t
		draw_circle(center, 8.0 + radius * 0.1, Color(1.0, 0.65, 0.25, alpha * 0.45))
		draw_arc(center, radius, 0.0, TAU, 96, Color(1.0, 0.85, 0.35, alpha), 3.0)
		draw_arc(center, radius * 1.45, 0.0, TAU, 96, Color(0.55, 0.8, 1.0, alpha * 0.55), 1.5)
