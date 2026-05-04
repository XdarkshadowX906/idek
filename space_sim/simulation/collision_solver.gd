class_name CollisionSolver
extends RefCounted

const BodyFactory = preload("res://space_sim/simulation/body_factory.gd")

enum Outcome {
	MERGE,
	CRATER,
	FRAGMENT_EJECTION,
	CATASTROPHIC_SHATTER,
}

const MIN_FRAGMENT_RADIUS_M := 5.0e4
const MAX_FRAGMENTS := 6

var body_factory: BodyFactory


func _init(factory: BodyFactory = null) -> void:
	body_factory = factory


func resolve(a, b) -> Dictionary:
	var delta := b.sim_position - a.sim_position
	var distance := maxf(delta.length(), 1.0)
	var normal := delta / distance
	var relative_velocity := b.velocity - a.velocity
	var closing_speed := maxf(-relative_velocity.dot(normal), relative_velocity.length())
	var reduced_mass := (a.mass * b.mass) / maxf(a.mass + b.mass, 1.0)
	var impact_energy := 0.5 * reduced_mass * closing_speed * closing_speed
	var weaker_strength := minf(a.material_strength, b.material_strength)
	var smaller_radius := minf(a.radius, b.radius)
	var disruption_scale := weaker_strength * PI * smaller_radius * smaller_radius * smaller_radius
	var severity := impact_energy / maxf(disruption_scale, 1.0)

	var result := {
		"outcome": Outcome.CRATER,
		"remove": [],
		"add": [],
		"primary": a,
		"energy": impact_energy,
		"severity": severity,
		"position": a.sim_position.lerp(b.sim_position, 0.5),
	}

	if severity < 0.18 or closing_speed < 4.0:
		result["outcome"] = Outcome.MERGE
		_merge_into_larger(a, b, result)
	elif severity < 0.75:
		result["outcome"] = Outcome.CRATER
		_apply_crater_damage(a, b, normal, severity, impact_energy)
	elif severity < 2.2:
		result["outcome"] = Outcome.FRAGMENT_EJECTION
		_apply_fragment_ejection(a, b, normal, severity, impact_energy, result)
	else:
		result["outcome"] = Outcome.CATASTROPHIC_SHATTER
		_apply_catastrophic_shatter(a, b, normal, severity, impact_energy, result)

	return result


func _merge_into_larger(a, b, result: Dictionary) -> void:
	var primary = a if a.mass >= b.mass else b
	var secondary = b if primary == a else a
	var total_mass := primary.mass + secondary.mass
	var combined_velocity := ((primary.velocity * primary.mass) + (secondary.velocity * secondary.mass)) / total_mass
	var combined_position := ((primary.sim_position * primary.mass) + (secondary.sim_position * secondary.mass)) / total_mass
	var mixed_density := total_mass / ((primary.mass / primary.density) + (secondary.mass / secondary.density))

	primary.mass = total_mass
	primary.velocity = combined_velocity
	primary.sim_position = combined_position
	primary.density = mixed_density
	primary.radius = BodyFactory.radius_from_mass(total_mass, mixed_density)
	primary.add_heat(float(result["energy"]) * 0.25)
	primary.register_damage((secondary.sim_position - primary.sim_position).normalized(), minf(float(result["severity"]), 1.0))
	result["primary"] = primary
	result["remove"].append(secondary)


func _apply_crater_damage(a, b, normal: Vector2, severity: float, impact_energy: float) -> void:
	a.register_damage(normal, severity)
	b.register_damage(-normal, severity)
	a.add_heat(impact_energy * 0.08)
	b.add_heat(impact_energy * 0.08)
	_apply_bounce(a, b, normal, 0.18)


func _apply_fragment_ejection(a, b, normal: Vector2, severity: float, impact_energy: float, result: Dictionary) -> void:
	_apply_crater_damage(a, b, normal, severity, impact_energy)
	var source = a if a.mass <= b.mass else b
	var fragment_count := clampi(int(ceil(severity * 3.0)), 2, MAX_FRAGMENTS)
	var ejected_mass_total := source.mass * clampf(0.03 + severity * 0.04, 0.04, 0.18)
	source.mass -= ejected_mass_total
	source.radius = BodyFactory.radius_from_mass(source.mass, source.density)

	for i in range(fragment_count):
		var angle := normal.angle() + randf_range(-0.9, 0.9) + PI
		var direction := Vector2.RIGHT.rotated(angle)
		var fragment_mass := ejected_mass_total / float(fragment_count)
		var fragment_radius := maxf(BodyFactory.radius_from_mass(fragment_mass, source.density), MIN_FRAGMENT_RADIUS_M)
		var offset := direction * (source.radius + fragment_radius + 1.0)
		var speed := sqrt(maxf((impact_energy / maxf(source.mass, 1.0)) * 0.02, 1.0))
		var fragment := body_factory.create_fragment(source, source.sim_position + offset, source.velocity + direction * speed, fragment_radius, source.temperature + 80.0)
		result["add"].append(fragment)


func _apply_catastrophic_shatter(a, b, normal: Vector2, severity: float, impact_energy: float, result: Dictionary) -> void:
	var victim = a if a.mass <= b.mass else b
	var survivor = b if victim == a else a
	survivor.register_damage(-normal if victim == a else normal, 1.0)
	survivor.add_heat(impact_energy * 0.12)
	result["remove"].append(victim)
	result["primary"] = survivor

	var fragment_count := clampi(int(ceil(3.0 + severity)), 4, MAX_FRAGMENTS)
	var retained_mass := victim.mass * 0.18
	var fragment_mass_total := victim.mass - retained_mass
	for i in range(fragment_count):
		var direction := Vector2.RIGHT.rotated((TAU * float(i) / float(fragment_count)) + randf_range(-0.28, 0.28))
		var fragment_mass := fragment_mass_total / float(fragment_count)
		var fragment_radius := maxf(BodyFactory.radius_from_mass(fragment_mass, victim.density), MIN_FRAGMENT_RADIUS_M)
		var speed := sqrt(maxf((impact_energy / maxf(victim.mass, 1.0)) * 0.08, 1.0))
		var fragment := body_factory.create_fragment(victim, victim.sim_position + direction * (victim.radius + fragment_radius), victim.velocity + direction * speed, fragment_radius, victim.temperature + 180.0)
		result["add"].append(fragment)

	var accreted_mass := retained_mass
	var total_mass := survivor.mass + accreted_mass
	survivor.velocity = ((survivor.velocity * survivor.mass) + (victim.velocity * accreted_mass)) / total_mass
	survivor.mass = total_mass
	survivor.radius = BodyFactory.radius_from_mass(survivor.mass, survivor.density)


func _apply_bounce(a, b, normal: Vector2, restitution: float) -> void:
	var relative_velocity := b.velocity - a.velocity
	var normal_speed := relative_velocity.dot(normal)
	if normal_speed > 0.0:
		return
	var impulse := -(1.0 + restitution) * normal_speed / ((1.0 / a.mass) + (1.0 / b.mass))
	a.velocity -= normal * impulse / a.mass
	b.velocity += normal * impulse / b.mass
