class_name HabitatEnvironment
extends Node3D
## Builds a cozy nighttime creature habitat from modular props.
##
## No temporary hardcoded “one-off” room — stations and decor hooks are
## registered so later homes / seasonal packs can swap layouts.

signal built

const FLOOR_COLOR := Color(0.28, 0.2, 0.16)
const WALL_COLOR := Color(0.22, 0.26, 0.38)
const TRIM_COLOR := Color(0.45, 0.35, 0.28)
const RUG_COLOR := Color(0.35, 0.22, 0.32)
const BED_COLOR := Color(0.4, 0.45, 0.7)
const WOOD_COLOR := Color(0.38, 0.26, 0.18)

var time_of_day: HabitatTimeOfDay = HabitatTimeOfDay.new()

## Named marker positions for companion AI + player care.
var station_markers: Dictionary = {}  ## StringName -> Marker3D
var decor_hooks: Array[Marker3D] = []

var _window_mat: StandardMaterial3D
var _lamp_lights: Array[OmniLight3D] = []
var _ambient: WorldEnvironment
var _window_glow: MeshInstance3D
var _dust: GPUParticles3D
var _moon_light: DirectionalLight3D


func build() -> void:
	_clear_children()
	station_markers.clear()
	decor_hooks.clear()
	_lamp_lights.clear()

	_build_shell()
	_build_furniture()
	_build_stations()
	_build_decor_hooks()
	_build_lighting()
	_build_ambiance()
	_apply_time_palette()
	built.emit()


func _process(delta: float) -> void:
	time_of_day.advance(delta)
	_pulse_lamps(delta)
	if time_of_day.cycle_enabled:
		_apply_time_palette()


func get_station_position(station_id: StringName) -> Vector3:
	var marker: Marker3D = station_markers.get(station_id) as Marker3D
	if marker:
		return marker.global_position
	return global_position


func get_floor_bounds() -> Rect2:
	## Local XZ walkable area for companion wandering.
	return Rect2(Vector2(-2.4, -2.0), Vector2(4.8, 3.6))


func set_phase(phase: HabitatTimeOfDay.Phase) -> void:
	time_of_day.phase = phase
	time_of_day.cycle_enabled = false
	_apply_time_palette()


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _build_shell() -> void:
	## Floor
	StylizedMesh.add_box(self, Vector3(6.0, 0.12, 5.0), FLOOR_COLOR, Vector3(0, -0.06, 0), "Floor", true)
	## Back wall
	StylizedMesh.add_box(self, Vector3(6.0, 3.2, 0.18), WALL_COLOR, Vector3(0, 1.5, -2.45), "WallBack", true)
	## Side walls
	StylizedMesh.add_box(self, Vector3(0.18, 3.2, 5.0), WALL_COLOR, Vector3(-3.0, 1.5, 0), "WallLeft", true)
	StylizedMesh.add_box(self, Vector3(0.18, 3.2, 5.0), WALL_COLOR, Vector3(3.0, 1.5, 0), "WallRight", true)
	## Ceiling
	StylizedMesh.add_box(self, Vector3(6.0, 0.12, 5.0), Color(0.18, 0.2, 0.28), Vector3(0, 3.1, 0), "Ceiling")
	## Baseboards
	StylizedMesh.add_box(self, Vector3(5.9, 0.12, 0.08), TRIM_COLOR, Vector3(0, 0.06, -2.34), "BaseBack")
	## Rug
	StylizedMesh.add_box(self, Vector3(2.4, 0.04, 1.6), RUG_COLOR, Vector3(0.2, 0.02, 0.2), "Rug")
	## Window frame + night pane
	StylizedMesh.add_box(self, Vector3(1.8, 1.4, 0.1), TRIM_COLOR, Vector3(-1.2, 1.8, -2.35), "WindowFrame")
	_window_glow = StylizedMesh.add_box(self, Vector3(1.5, 1.1, 0.05), Color(0.3, 0.45, 0.9), Vector3(-1.2, 1.8, -2.28), "WindowPane")
	_window_mat = StylizedMesh.make_material(Color(0.3, 0.5, 0.95))
	_window_mat.emission_enabled = true
	_window_mat.emission = Color(0.25, 0.4, 0.9)
	_window_mat.emission_energy_multiplier = 0.45
	_window_glow.material_override = _window_mat
	## Moon disc outside window
	var moon := StylizedMesh.add_sphere(self, 0.28, Color(0.85, 0.9, 1.0), Vector3(-1.55, 2.15, -2.55), "Moon")
	var moon_mat := StylizedMesh.make_material(Color(0.9, 0.93, 1.0), 1.0)
	moon_mat.emission_enabled = true
	moon_mat.emission = Color(0.75, 0.85, 1.0)
	moon_mat.emission_energy_multiplier = 0.55
	moon.material_override = moon_mat


func _build_furniture() -> void:
	## Bed (left rear)
	StylizedMesh.add_box(self, Vector3(1.6, 0.28, 1.1), WOOD_COLOR, Vector3(-1.7, 0.2, -1.5), "BedFrame")
	StylizedMesh.add_box(self, Vector3(1.45, 0.22, 0.95), BED_COLOR, Vector3(-1.7, 0.42, -1.5), "Mattress")
	StylizedMesh.add_box(self, Vector3(0.45, 0.18, 0.55), Color(0.75, 0.8, 0.95), Vector3(-2.15, 0.58, -1.5), "Pillow")
	StylizedMesh.add_box(self, Vector3(0.9, 0.12, 0.85), Color(0.55, 0.35, 0.55), Vector3(-1.4, 0.55, -1.5), "Blanket")
	## Nightstand + lamp body
	StylizedMesh.add_box(self, Vector3(0.45, 0.55, 0.4), WOOD_COLOR, Vector3(-0.55, 0.28, -1.7), "Nightstand")
	StylizedMesh.add_cylinder(self, 0.08, 0.35, Color(0.85, 0.75, 0.55), Vector3(-0.55, 0.75, -1.7), "LampStem")
	var shade := StylizedMesh.add_cylinder(self, 0.22, 0.2, Color(0.95, 0.85, 0.55), Vector3(-0.55, 0.95, -1.7), "LampShade")
	var shade_mat := StylizedMesh.make_material(Color(0.95, 0.82, 0.5), 0.6)
	shade_mat.emission_enabled = true
	shade_mat.emission = Color(0.95, 0.75, 0.4)
	shade_mat.emission_energy_multiplier = 1.2
	if shade is MeshInstance3D:
		(shade as MeshInstance3D).material_override = shade_mat
	## Shelf with tiny decor
	StylizedMesh.add_box(self, Vector3(1.4, 0.08, 0.35), WOOD_COLOR, Vector3(1.6, 1.6, -2.2), "Shelf")
	StylizedMesh.add_box(self, Vector3(0.2, 0.28, 0.15), Color(0.7, 0.4, 0.35), Vector3(1.2, 1.8, -2.2), "BookA")
	StylizedMesh.add_box(self, Vector3(0.18, 0.32, 0.15), Color(0.35, 0.55, 0.7), Vector3(1.4, 1.82, -2.2), "BookB")
	StylizedMesh.add_sphere(self, 0.12, Color(0.4, 0.85, 0.7), Vector3(1.9, 1.78, -2.15), "PlantPot")
	## Soft wall panels
	StylizedMesh.add_box(self, Vector3(1.2, 0.9, 0.04), Color(0.3, 0.34, 0.48), Vector3(1.5, 1.2, -2.35), "Poster")


func _build_stations() -> void:
	_add_station(&"bed", Vector3(-1.7, 0.0, -1.15))
	_add_station(&"food", Vector3(1.8, 0.0, 0.9))
	_add_station(&"toy", Vector3(0.3, 0.0, 1.2))
	_add_station(&"train", Vector3(1.7, 0.0, -0.8))
	_add_station(&"idle_center", Vector3(0.0, 0.0, 0.15))

	## Food bowl visual
	StylizedMesh.add_cylinder(self, 0.28, 0.12, Color(0.55, 0.55, 0.6), Vector3(1.8, 0.08, 0.9), "FoodBowl")
	var food := StylizedMesh.add_cylinder(self, 0.18, 0.06, Color(0.85, 0.55, 0.3), Vector3(1.8, 0.14, 0.9), "Food")
	var food_mat := StylizedMesh.make_material(Color(0.9, 0.55, 0.25), 0.7)
	food_mat.emission_enabled = true
	food_mat.emission = Color(0.8, 0.4, 0.15)
	food_mat.emission_energy_multiplier = 0.4
	if food is MeshInstance3D:
		(food as MeshInstance3D).material_override = food_mat

	## Toy ball
	var ball := StylizedMesh.add_sphere(self, 0.18, Color(0.95, 0.45, 0.55), Vector3(0.3, 0.18, 1.2), "ToyBall")
	var ball_mat := StylizedMesh.make_material(Color(0.95, 0.4, 0.5), 0.5)
	ball_mat.emission_enabled = true
	ball_mat.emission = Color(0.9, 0.3, 0.4)
	ball_mat.emission_energy_multiplier = 0.6
	ball.material_override = ball_mat

	## Training mat
	StylizedMesh.add_box(self, Vector3(1.1, 0.05, 1.1), Color(0.25, 0.45, 0.4), Vector3(1.7, 0.03, -0.8), "TrainMat")
	StylizedMesh.add_cylinder(self, 0.12, 0.55, Color(0.7, 0.75, 0.8), Vector3(2.1, 0.3, -0.8), "TrainPost")


func _build_decor_hooks() -> void:
	## Empty markers for future decoration placement / NFC unlocks.
	for i in 4:
		var hook := Marker3D.new()
		hook.name = "DecorHook_%d" % i
		hook.position = Vector3(-2.2 + float(i) * 1.1, 0.0, 1.6)
		add_child(hook)
		decor_hooks.append(hook)


func _build_lighting() -> void:
	_ambient = WorldEnvironment.new()
	_ambient.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.28, 0.4)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	_ambient.environment = env
	add_child(_ambient)

	_moon_light = DirectionalLight3D.new()
	_moon_light.name = "MoonLight"
	_moon_light.light_color = Color(0.45, 0.55, 0.95)
	_moon_light.light_energy = 0.35
	_moon_light.light_specular = 0.0
	_moon_light.rotation_degrees = Vector3(-35, 40, 0)
	_moon_light.shadow_enabled = false
	add_child(_moon_light)

	_add_omni(Vector3(-0.55, 1.15, -1.7), Color(1.0, 0.75, 0.4), 0.9, 4.0, "BedLamp")
	_add_omni(Vector3(1.8, 0.6, 0.9), Color(0.95, 0.55, 0.3), 0.35, 2.2, "BowlGlow")
	_add_omni(Vector3(0.0, 2.4, 0.0), Color(0.55, 0.65, 0.95), 0.3, 5.5, "CeilingSoft")
	_add_omni(Vector3(-1.2, 1.8, -2.0), Color(0.4, 0.55, 1.0), 0.45, 3.0, "WindowSpill")


func _build_ambiance() -> void:
	_dust = GPUParticles3D.new()
	_dust.name = "DustMotes"
	_dust.amount = 14
	_dust.lifetime = 6.0
	_dust.preprocess = 2.0
	_dust.visibility_aabb = AABB(Vector3(-3, 0, -2.5), Vector3(6, 3.2, 5))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(2.5, 1.2, 2.0)
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.02
	mat.initial_velocity_max = 0.08
	mat.gravity = Vector3(0, 0.02, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.05
	mat.color = Color(0.85, 0.9, 1.0, 0.35)
	_dust.process_material = mat
	var draw := BoxMesh.new()
	draw.size = Vector3(0.04, 0.04, 0.04)
	var draw_mat := StylizedMesh.make_material(Color(0.9, 0.95, 1.0, 0.45))
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.material = draw_mat
	_dust.draw_pass_1 = draw
	_dust.position = Vector3(0, 1.2, 0)
	add_child(_dust)


func _add_station(id: StringName, pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = "Station_%s" % String(id)
	marker.position = pos
	add_child(marker)
	station_markers[id] = marker


func _add_omni(pos: Vector3, color: Color, energy: float, range_m: float, node_name: String) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.shadow_enabled = false
	add_child(light)
	_lamp_lights.append(light)


func _apply_time_palette() -> void:
	if _ambient and _ambient.environment:
		_ambient.environment.ambient_light_color = time_of_day.get_ambient_color()
		_ambient.environment.background_color = time_of_day.get_ambient_color().darkened(0.55)
	if _window_mat:
		var glow := time_of_day.get_window_glow()
		_window_mat.albedo_color = glow
		_window_mat.emission = glow
	var lamp_e := time_of_day.get_lamp_energy()
	for i in _lamp_lights.size():
		## Keep relative intensities; scale by time phase.
		var base := 1.0 if i == 0 else (0.4 if i == 1 else 0.35)
		_lamp_lights[i].light_energy = base * lamp_e
	if _moon_light:
		_moon_light.light_energy = 0.45 if time_of_day.phase == HabitatTimeOfDay.Phase.NIGHT else 0.15


func _pulse_lamps(delta: float) -> void:
	if _lamp_lights.is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	## Soft breathing on the bedside lamp.
	_lamp_lights[0].light_energy = time_of_day.get_lamp_energy() * (1.0 + sin(t * 1.4) * 0.08)
	## Tiny unused delta keep for future flicker weather.
	if delta < 0.0:
		pass
