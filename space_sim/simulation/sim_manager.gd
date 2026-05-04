class_name SimManager
extends Node2D

const CelestialBody = preload("res://space_sim/simulation/celestial_body.gd")
const BodyFactory = preload("res://space_sim/simulation/body_factory.gd")
const CollisionSolver = preload("res://space_sim/simulation/collision_solver.gd")

signal body_added(body: CelestialBody)
signal body_removed(body: CelestialBody)
signal collision_event(event: Dictionary)

const G := 6.67430e-11 # m^3 kg^-1 s^-2, CODATA 2018 value.
const MAX_STEP_SECONDS := 900.0
const SOFTENING_METERS := 750.0

var render_scale := 1.0 / 1.5e6
var time_scale := 3600.0
var paused := false
var selected_body: CelestialBody = null

var bodies: Array[CelestialBody] = []
var factory := BodyFactory.new()
var collision_solver := CollisionSolver.new()


func _ready() -> void:
	collision_solver.body_factory = factory


func reset() -> void:
	for body in bodies:
		body.queue_free()
	bodies.clear()
	factory.reset_ids()


func add_body(body: CelestialBody) -> void:
	if body.get_parent() != self:
		add_child(body)
	body.set_render_scale(render_scale)
	if not bodies.has(body):
		bodies.append(body)
		body_added.emit(body)


func remove_body(body: CelestialBody) -> void:
	if not bodies.has(body):
		return
	bodies.erase(body)
	body_removed.emit(body)
	body.queue_free()


func create_body(body_name: String, position_m: Vector2, velocity_mps: Vector2, radius_m: float, material_type: String, is_fragment := false) -> CelestialBody:
	var body := factory.create_body(body_name, position_m, velocity_mps, radius_m, material_type, is_fragment)
	add_body(body)
	return body


func simulate_frame(real_delta: float) -> void:
	if paused:
		return
	var remaining := real_delta * time_scale
	while remaining > 0.0:
		var step := minf(remaining, MAX_STEP_SECONDS)
		_step_leapfrog(step)
		_resolve_collisions()
		remaining -= step
	for body in bodies:
		body.push_trail_point()
		body.sync_render_position()
		body.queue_redraw()


func _step_leapfrog(dt: float) -> void:
	# Kick-drift-kick leapfrog is symplectic for gravity and behaves better than
	# explicit Euler for long-running orbital motion at fast-forward scales.
	_compute_accelerations()
	for body in bodies:
		body.velocity += body.acceleration * (0.5 * dt)
		body.sim_position += body.velocity * dt
	_compute_accelerations()
	for body in bodies:
		body.velocity += body.acceleration * (0.5 * dt)


func _compute_accelerations() -> void:
	for body in bodies:
		body.acceleration = Vector2.ZERO
	for i in range(bodies.size()):
		var a := bodies[i]
		for j in range(i + 1, bodies.size()):
			var b := bodies[j]
			var delta := b.sim_position - a.sim_position
			var dist_sq := maxf(delta.length_squared(), SOFTENING_METERS * SOFTENING_METERS)
			var dist := sqrt(dist_sq)
			if dist <= 0.0:
				continue
			var direction := delta / dist
			var accel_a := G * b.mass / dist_sq
			var accel_b := G * a.mass / dist_sq
			a.acceleration += direction * accel_a
			b.acceleration -= direction * accel_b


func _resolve_collisions() -> void:
	if bodies.size() < 2:
		return
	var removed: Array[CelestialBody] = []
	var additions: Array[CelestialBody] = []
	for i in range(bodies.size()):
		var a := bodies[i]
		if removed.has(a):
			continue
		for j in range(i + 1, bodies.size()):
			var b := bodies[j]
			if removed.has(b):
				continue
			if a.sim_position.distance_to(b.sim_position) <= a.radius + b.radius:
				var result := collision_solver.resolve(a, b)
				collision_event.emit(result)
				for body in result.get("remove", []):
					if not removed.has(body):
						removed.append(body)
				for body in result.get("add", []):
					additions.append(body)
				if removed.has(a):
					break
	for body in removed:
		if bodies.has(body):
			bodies.erase(body)
			body_removed.emit(body)
			body.queue_free()
	for body in additions:
		add_body(body)


func pick_body(world_position_px: Vector2) -> CelestialBody:
	var best: CelestialBody = null
	var best_distance := INF
	for body in bodies:
		var distance := world_position_px.distance_to(body.position)
		var pick_radius := maxf(body.rendered_radius(), 10.0)
		if distance <= pick_radius and distance < best_distance:
			best = body
			best_distance = distance
	return best


func set_selected_body(new_selected_body: CelestialBody) -> void:
	selected_body = new_selected_body
	for body in bodies:
		body.selected = body == new_selected_body
		body.queue_redraw()
