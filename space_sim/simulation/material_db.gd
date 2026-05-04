extends RefCounted
class_name MaterialDB

const ROCKY := "rocky"
const METAL_RICH := "metal_rich"
const ICY := "icy"

# SI-style material values. Strength is an approximate bulk disruption threshold
# used by the gameplay collision solver, not a full material science model.
const MATERIALS := {
	"rocky": {
		"display_name": "Rocky",
		"density": 3300.0,
		"strength": 4.0e6,
		"heat_capacity": 900.0,
		"color": Color(0.64, 0.42, 0.25),
	},
	"metal_rich": {
		"display_name": "Metal Rich",
		"density": 7800.0,
		"strength": 1.0e7,
		"heat_capacity": 460.0,
		"color": Color(0.62, 0.64, 0.68),
	},
	"icy": {
		"display_name": "Icy",
		"density": 920.0,
		"strength": 8.0e5,
		"heat_capacity": 2050.0,
		"color": Color(0.66, 0.86, 1.0),
	},
}


static func get_material(material_type: String) -> Dictionary:
	if MATERIALS.has(material_type):
		return MATERIALS[material_type]
	return MATERIALS[ROCKY]


static func get_density(material_type: String) -> float:
	return float(get_material(material_type)["density"])


static func get_strength(material_type: String) -> float:
	return float(get_material(material_type)["strength"])


static func get_heat_capacity(material_type: String) -> float:
	return float(get_material(material_type)["heat_capacity"])


static func get_color(material_type: String) -> Color:
	return get_material(material_type)["color"]


static func get_types() -> Array[String]:
	return [ROCKY, METAL_RICH, ICY]
