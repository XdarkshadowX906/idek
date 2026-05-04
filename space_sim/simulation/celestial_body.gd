class_name CelestialBody
extends Node2D

const MAX_TRAIL_POINTS := 160
const KELVIN_GLOW_THRESHOLD := 900.0

var body_id: int = -1
var body_name: String = "Body"
var sim_position: Vector2 = Vector2.ZERO # meters
var velocity: Vector2 = Vector2.ZERO # meters / second
var acceleration: Vector2 = Vector2.ZERO # meters / second^2
var mass: float = 1.0 # kilograms
var radius: float = 1.0 # meters
var density: float = 1000.0 # kilograms / meter^3
var material_type: String = "rocky"
var material_strength: float = 1.0e7 # pascals
var heat_capacity: float = 800.0 # joules / kilogram kelvin
var temperature: float = 240.0 # kelvin
var is_fragment: bool = false
var crater_data: Array[Dictionary] = []
var trail_history: Array[Vector2] = []

var render_scale := 1.0
var selected := false
var base_color := Color.WHITE
var impact_flash := 0.0

func configure(data: Dictionary) -> void:
	body_id = int(data.get("id", body_id))
	body_name = str(data.get("name", body_name))
	sim_position = data.get("position", sim_position)
	velocity = data.get("velocity", velocity)
	acceleration = data.get("acceleration", acceleration)
	mass = float(data.get("mass", mass))
	radius = float(data.get("radius", radius))
	density = float(data.get("density", density))
	material_type = str(data.get("material_type", material_type))
	material_strength = float(data.get("material_strength", material_strength))
	heat_capacity = float(data.get("heat_capacity", heat_capacity))
	temperature = float(data.get("temperature", temperature))
	is_fragment = bool(data.get("is_fragment", is_fragment))
	base_color = data.get("color", base_color)
	trail_history.clear()
	queue_redraw()


func set_render_scale(new_scale: float) -> void:
	render_scale = new_scale
	position = sim_position * render_scale
	queue_redraw()


func sync_render_position() -> void:
	position = sim_position * render_scale


func rendered_radius() -> float:
	return max(radius * render_scale, 4.0 if not is_fragment else 2.0)


func push_trail_point() -> void:
	if trail_history.is_empty() or trail_history[trail_history.size() - 1].distance_to(sim_position) > radius * 0.25:
		trail_history.append(sim_position)
		if trail_history.size() > MAX_TRAIL_POINTS:
			trail_history.pop_front()


func register_damage(local_direction: Vector2, severity: float) -> void:
	crater_data.append({
		"direction": local_direction.normalized() if local_direction.length_squared() > 0.0 else Vector2.RIGHT,
		"severity": clampf(severity, 0.05, 1.0),
	})
	if crater_data.size() > 18:
		crater_data.pop_front()
	impact_flash = 1.0
	queue_redraw()


func add_heat(energy_joules: float) -> void:
	if mass <= 0.0 or heat_capacity <= 0.0:
		return
	temperature += energy_joules / (mass * heat_capacity)
	queue_redraw()


func _process(delta: float) -> void:
	if impact_flash > 0.0:
		impact_flash = maxf(impact_flash - delta * 2.8, 0.0)
		queue_redraw()


func _draw() -> void:
	var r := rendered_radius()
	_draw_trail()
	var shade_offset := Vector2(-r * 0.28, -r * 0.35)
	var color := base_color
	if temperature > KELVIN_GLOW_THRESHOLD:
		var heat_amount := clampf((temperature - KELVIN_GLOW_THRESHOLD) / 1800.0, 0.0, 1.0)
		color = color.lerp(Color(1.0, 0.35, 0.08), heat_amount)
	draw_circle(Vector2.ZERO, r, color.darkened(0.35))
	draw_circle(shade_offset, r * 0.82, color)
	draw_circle(shade_offset + Vector2(-r * 0.22, -r * 0.22), r * 0.28, color.lightened(0.45))
	for crater in crater_data:
		var dir: Vector2 = crater["direction"]
		var severity: float = crater["severity"]
		var crater_pos := dir * r * 0.48
		draw_circle(crater_pos, r * lerpf(0.07, 0.2, severity), Color(0.04, 0.03, 0.025, 0.7))
	if selected:
		draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 96, Color(0.4, 0.85, 1.0), 2.0)
	if impact_flash > 0.0:
		draw_circle(Vector2.ZERO, r * (1.0 + impact_flash * 0.35), Color(1.0, 0.75, 0.35, impact_flash * 0.45))


func _draw_trail() -> void:
	if trail_history.size() < 2:
		return
	for i in range(1, trail_history.size()):
		var a := (trail_history[i - 1] - sim_position) * render_scale
		var b := (trail_history[i] - sim_position) * render_scale
		var alpha := float(i) / float(trail_history.size()) * 0.35
		draw_line(a, b, Color(0.55, 0.8, 1.0, alpha), 1.0)
