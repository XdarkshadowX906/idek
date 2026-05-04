class_name SimUI
extends CanvasLayer

const MaterialDB = preload("res://space_sim/simulation/material_db.gd")
const CelestialBody = preload("res://space_sim/simulation/celestial_body.gd")

signal pause_toggled(paused: bool)
signal follow_toggled(enabled: bool)
signal time_scale_changed(scale: float)
signal material_changed(material_type: String)

@onready var pause_button: CheckButton = $Root/Panel/Margin/VBox/PauseCheck
@onready var follow_button: CheckButton = $Root/Panel/Margin/VBox/FollowCheck
@onready var time_slider: HSlider = $Root/Panel/Margin/VBox/TimeRow/TimeSlider
@onready var material_option: OptionButton = $Root/Panel/Margin/VBox/MaterialRow/MaterialOption
@onready var stats_label: Label = $Root/Panel/Margin/VBox/BodyStatsLabel
@onready var help_label: Label = $Root/Panel/Margin/VBox/ControlsLabel
@onready var status_label: Label = $Root/Panel/Margin/VBox/StatusLabel

var _selected_body: CelestialBody


func _ready() -> void:
	pause_button.toggled.connect(func(pressed: bool) -> void:
		pause_button.text = "Resume" if pressed else "Pause"
		pause_toggled.emit(pressed)
	)
	follow_button.toggled.connect(func(pressed: bool) -> void:
		follow_toggled.emit(pressed)
	)
	time_slider.value_changed.connect(func(value: float) -> void:
		time_scale_changed.emit(pow(10.0, value))
	)
	for material_type in MaterialDB.get_types():
		material_option.add_item(material_type)
	material_option.item_selected.connect(func(index: int) -> void:
		material_changed.emit(material_option.get_item_text(index))
	)
	help_label.text = "LMB select | Hold empty space to grow body | Drag to set launch velocity | WASD/MMB pan | Wheel zoom"
	set_selected_body(null)
	set_time_scale(1.0)


func set_selected_body(body: CelestialBody) -> void:
	_selected_body = body
	_refresh_stats()


func set_time_scale(scale: float) -> void:
	status_label.text = "Time scale: %.1fx" % scale


func set_paused(paused: bool) -> void:
	pause_button.set_pressed_no_signal(paused)
	pause_button.text = "Resume" if paused else "Pause"


func set_follow_enabled(enabled: bool) -> void:
	follow_button.set_pressed_no_signal(enabled)


func set_material(material_type: String) -> void:
	for index in range(material_option.item_count):
		if material_option.get_item_text(index) == material_type:
			material_option.select(index)
			return


func _process(_delta: float) -> void:
	if is_instance_valid(_selected_body):
		_refresh_stats()


func _refresh_stats() -> void:
	if not is_instance_valid(_selected_body):
		stats_label.text = "Selected body: none"
		return
	var b := _selected_body
	stats_label.text = "\n".join([
		"Selected: %s (#%d)" % [b.body_name, b.body_id],
		"Material: %s%s" % [b.material_type, " fragment" if b.is_fragment else ""],
		"Mass: %.3e kg" % b.mass,
		"Radius: %.1f m" % b.radius,
		"Density: %.0f kg/m^3" % b.density,
		"Speed: %.2f m/s" % b.velocity.length(),
		"Acceleration: %.3e m/s^2" % b.acceleration.length(),
		"Temperature: %.1f K" % b.temperature,
		"Craters: %d" % b.crater_data.size(),
	])
