class_name BodyFactory
extends RefCounted

const CelestialBody = preload("res://space_sim/simulation/celestial_body.gd")
const MaterialDB = preload("res://space_sim/simulation/material_db.gd")

const DEFAULT_TEMPERATURE_K := 285.0

var _next_id := 1


func reset_ids() -> void:
	_next_id = 1


func create_body(body_name: String, position_m: Vector2, velocity_mps: Vector2, radius_m: float, material_type: String, is_fragment := false) -> CelestialBody:
	var material := MaterialDB.get_material(material_type)
	var density: float = material["density"]
	var mass := mass_from_radius(radius_m, density)
	var body := CelestialBody.new()
	body.body_id = _next_id
	_next_id += 1
	body.body_name = body_name
	body.name = "Body%d_%s" % [body.body_id, body_name.replace(" ", "_")]
	body.sim_position = position_m
	body.velocity = velocity_mps
	body.acceleration = Vector2.ZERO
	body.mass = mass
	body.radius = radius_m
	body.density = density
	body.material_type = material_type
	body.material_strength = material["strength"]
	body.heat_capacity = material["heat_capacity"]
	body.temperature = DEFAULT_TEMPERATURE_K
	body.is_fragment = is_fragment
	body.base_color = material["color"]
	body.trail_history.clear()
	return body


func create_fragment(parent: CelestialBody, position_m: Vector2, velocity_mps: Vector2, radius_m: float, temperature_k: float) -> CelestialBody:
	var body := create_body("%s fragment" % parent.body_name, position_m, velocity_mps, radius_m, str(parent.material_type), true)
	body.temperature = temperature_k
	body.crater_data = parent.crater_data.duplicate(true)
	return body


static func mass_from_radius(radius_m: float, density_kg_m3: float) -> float:
	# The 2D view represents spherical bodies, so mass uses sphere volume.
	return (4.0 / 3.0) * PI * radius_m * radius_m * radius_m * density_kg_m3


static func radius_from_mass(mass_kg: float, density_kg_m3: float) -> float:
	return pow((3.0 * mass_kg) / (4.0 * PI * density_kg_m3), 1.0 / 3.0)
