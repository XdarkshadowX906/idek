extends Node2D

const SimManager = preload("res://space_sim/simulation/sim_manager.gd")
const MaterialDB = preload("res://space_sim/simulation/material_db.gd")
const SimUI = preload("res://space_sim/ui/sim_ui.gd")

const METERS_PER_PIXEL := 1.0e6
const CREATE_MIN_RADIUS_M := 450000.0
const CREATE_MAX_RADIUS_M := 3200000.0
const CREATE_RADIUS_RATE_MPS := 380000.0
const VELOCITY_DRAG_SCALE := 10500.0
const SELECT_SCREEN_RADIUS_PX := 18.0
const KEYBOARD_PAN_SPEED := 520.0
const TIME_SCALE_MULTIPLIER := 2.0

@onready var sim_manager: SimManager = $SimManager
@onready var camera: Camera2D = $Camera2D
@onready var impact_effects = $ImpactEffects
@onready var ui: SimUI = $HUD

var _selected_body: CelestialBody = null
var _follow_selected := false
var _panning := false
var _creating := false
var _create_origin_screen := Vector2.ZERO
var _create_origin_world := Vector2.ZERO
var _create_radius_m := CREATE_MIN_RADIUS_M
var _create_material := MaterialDB.ROCKY


func _ready() -> void:
	sim_manager.render_scale = 1.0 / METERS_PER_PIXEL
	sim_manager.collision_event.connect(_on_collision_event)
	impact_effects.set_render_scale(sim_manager.render_scale)
	ui.pause_toggled.connect(_on_pause_toggled)
	ui.time_scale_changed.connect(_on_time_scale_changed)
	ui.follow_toggled.connect(_on_follow_toggled)
	ui.material_changed.connect(_on_material_changed)
	_spawn_starting_bodies()
	ui.set_selected_body(_selected_body)
	ui.set_paused(sim_manager.paused)
	ui.set_time_scale(sim_manager.time_scale)


func _process(delta: float) -> void:
	sim_manager.simulate_frame(delta)
	_apply_keyboard_pan(delta)
	if _follow_selected and is_instance_valid(_selected_body):
		camera.global_position = _selected_body.global_position
	if _creating:
		_create_radius_m = min(_create_radius_m + CREATE_RADIUS_RATE_MPS * delta, CREATE_MAX_RADIUS_M)
	queue_redraw()
	ui.set_selected_body(_selected_body if is_instance_valid(_selected_body) else null)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_at_mouse(0.86)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_at_mouse(1.16)
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = event.pressed
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var body = _pick_body(event.position)
			if body:
				_select_body(body)
			else:
				_begin_creation(event.position)
		elif _creating:
			_finish_creation(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_select_body(null)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _panning:
		camera.global_position -= event.relative / camera.zoom.x


func _apply_keyboard_pan(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction.length_squared() > 0.0:
		camera.global_position += direction.normalized() * KEYBOARD_PAN_SPEED * delta / camera.zoom.x


func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_SPACE:
			sim_manager.paused = not sim_manager.paused
			ui.set_paused(sim_manager.paused)
		KEY_F:
			_follow_selected = not _follow_selected
			ui.set_follow_enabled(_follow_selected)
		KEY_1:
			_set_time_scale(1.0)
		KEY_2:
			_set_time_scale(60.0)
		KEY_3:
			_set_time_scale(600.0)
		KEY_4:
			_set_time_scale(3600.0)
		KEY_R:
			camera.global_position = Vector2.ZERO
			camera.zoom = Vector2.ONE
		KEY_BRACKETLEFT:
			_set_time_scale(maxf(sim_manager.time_scale / TIME_SCALE_MULTIPLIER, 1.0))
		KEY_BRACKETRIGHT:
			_set_time_scale(minf(sim_manager.time_scale * TIME_SCALE_MULTIPLIER, 100000.0))
		KEY_TAB:
			_cycle_material()


func _zoom_at_mouse(multiplier: float) -> void:
	var before := get_global_mouse_position()
	camera.zoom = (camera.zoom / multiplier).clamp(Vector2(0.08, 0.08), Vector2(10.0, 10.0))
	var after := get_global_mouse_position()
	camera.global_position += before - after


func _begin_creation(screen_pos: Vector2) -> void:
	_creating = true
	_create_origin_screen = screen_pos
	_create_origin_world = get_global_mouse_position()
	_create_radius_m = CREATE_MIN_RADIUS_M


func _finish_creation(screen_pos: Vector2) -> void:
	_creating = false
	var drag_screen := screen_pos - _create_origin_screen
	var velocity := drag_screen * VELOCITY_DRAG_SCALE
	var body_name := "%s body %d" % [_create_material, sim_manager.bodies.size() + 1]
	var body = sim_manager.create_body(
		body_name,
		_create_origin_world / sim_manager.render_scale,
		velocity,
		_create_radius_m,
		_create_material,
		false
	)
	_select_body(body)


func _pick_body(screen_pos: Vector2) -> CelestialBody:
	var world_pos := camera.get_canvas_transform().affine_inverse() * screen_pos
	var best_body: CelestialBody = null
	var best_distance := INF
	for body in sim_manager.bodies:
		var dist := body.global_position.distance_to(world_pos)
		var hit_radius: float = max(body.rendered_radius(), SELECT_SCREEN_RADIUS_PX / camera.zoom.x)
		if dist <= hit_radius and dist < best_distance:
			best_body = body
			best_distance = dist
	return best_body


func _select_body(body: CelestialBody) -> void:
	if is_instance_valid(_selected_body):
		_selected_body.selected = false
		_selected_body.queue_redraw()
	_selected_body = body
	if is_instance_valid(_selected_body):
		_selected_body.selected = true
		_selected_body.queue_redraw()
	sim_manager.set_selected_body(_selected_body)
	ui.set_selected_body(_selected_body)


func _spawn_starting_bodies() -> void:
	var primary = sim_manager.create_body(
		"Rocky Proto-Planet",
		Vector2(-9.0e6, 0.0),
		Vector2(0.0, 18.0),
		2.5e6,
		MaterialDB.ROCKY,
		false
	)
	var secondary = sim_manager.create_body(
		"Icy Proto-Planet",
		Vector2(9.0e6, 0.0),
		Vector2(0.0, -18.0),
		2.0e6,
		MaterialDB.ICY,
		false
	)
	_select_body(primary)


func _set_time_scale(value: float) -> void:
	sim_manager.time_scale = value
	ui.set_time_scale(value)


func _on_pause_toggled(paused: bool) -> void:
	sim_manager.paused = paused


func _on_time_scale_changed(scale: float) -> void:
	sim_manager.time_scale = scale
	ui.set_time_scale(scale)


func _on_follow_toggled(enabled: bool) -> void:
	_follow_selected = enabled


func _on_material_changed(material_type: String) -> void:
	_create_material = material_type


func _cycle_material() -> void:
	var types := MaterialDB.get_types()
	var current_index := types.find(_create_material)
	_create_material = types[(current_index + 1) % types.size()]
	ui.set_material(_create_material)


func _on_collision_event(event: Dictionary) -> void:
	impact_effects.spawn_impact(event.get("position", Vector2.ZERO), float(event.get("energy", 0.0)), float(event.get("severity", 0.0)))


func _draw() -> void:
	if not _creating:
		return
	var origin := _create_origin_world
	var mouse := get_global_mouse_position()
	var radius_px := max(_create_radius_m * sim_manager.render_scale, 4.0)
	draw_circle(origin, radius_px, MaterialDB.get_color(_create_material).darkened(0.25))
	draw_arc(origin, radius_px + 3.0, 0.0, TAU, 64, Color(0.9, 0.95, 1.0, 0.8), 2.0)
	draw_line(origin, mouse, Color(0.4, 1.0, 0.65), 2.0)
	draw_string(ThemeDB.fallback_font, mouse + Vector2(12.0, -8.0), "release: set velocity", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14.0, Color(0.9, 1.0, 0.9))
