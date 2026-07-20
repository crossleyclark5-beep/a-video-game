class_name WorldAtmosphere
extends Node3D
## Adventure-world lighting, sky, and time-of-day foundation.
## Handheld-friendly: one sun + ambient + soft fog; optional few fill lights.

enum Phase {
	MORNING,
	AFTERNOON,
	EVENING,
}

@export var phase: Phase = Phase.AFTERNOON
@export var enable_shadows: bool = true

var _env_node: WorldEnvironment
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D


func setup(existing_sun: DirectionalLight3D = null) -> void:
	_sun = existing_sun
	if _sun == null:
		_sun = DirectionalLight3D.new()
		_sun.name = "Sun"
		add_child(_sun)
	_configure_environment()
	_configure_sun()
	_configure_fill()
	apply_phase(phase)


func apply_phase(next: Phase) -> void:
	phase = next
	match phase:
		Phase.MORNING:
			_apply_palette(
				Color(0.95, 0.82, 0.65),
				1.05,
				Color(0.55, 0.65, 0.85),
				Color(0.55, 0.72, 0.95),
				Color(0.85, 0.55, 0.35),
				Vector3(-42, 55, 0),
			)
		Phase.AFTERNOON:
			_apply_palette(
				Color(1.0, 0.96, 0.88),
				1.2,
				Color(0.45, 0.55, 0.7),
				Color(0.4, 0.65, 0.95),
				Color(0.75, 0.82, 0.95),
				Vector3(-50, 35, 0),
			)
		Phase.EVENING:
			_apply_palette(
				Color(1.0, 0.55, 0.35),
				0.85,
				Color(0.35, 0.35, 0.55),
				Color(0.35, 0.4, 0.7),
				Color(0.95, 0.4, 0.25),
				Vector3(-28, 70, 0),
			)


func get_phase_label() -> String:
	match phase:
		Phase.MORNING: return "Morning"
		Phase.AFTERNOON: return "Afternoon"
		_: return "Evening"


func _configure_environment() -> void:
	_env_node = WorldEnvironment.new()
	_env_node.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.68, 0.92)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.55, 0.7)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.0
	## Soft distance haze — miniature diorama depth without heavy cost.
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.8, 0.92)
	env.fog_density = 0.0018
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.4
	env.glow_enabled = true
	env.glow_intensity = 0.18
	env.glow_bloom = 0.05
	env.glow_strength = 0.7
	_env_node.environment = env
	add_child(_env_node)


func _configure_sun() -> void:
	_sun.shadow_enabled = enable_shadows
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.shadow_blur = 1.5
	_sun.light_specular = 0.45


func _configure_fill() -> void:
	## Soft bounce fill — no shadows, low energy (handheld-safe).
	_fill = DirectionalLight3D.new()
	_fill.name = "FillLight"
	_fill.light_energy = 0.22
	_fill.light_color = Color(0.55, 0.65, 0.9)
	_fill.shadow_enabled = false
	_fill.rotation_degrees = Vector3(-25, -140, 0)
	add_child(_fill)


func _apply_palette(
	sun_color: Color,
	sun_energy: float,
	ambient: Color,
	sky: Color,
	fog: Color,
	sun_rot_deg: Vector3,
) -> void:
	if _sun:
		_sun.light_color = sun_color
		_sun.light_energy = sun_energy
		_sun.rotation_degrees = sun_rot_deg
	if _env_node and _env_node.environment:
		var env := _env_node.environment
		env.background_color = sky
		env.ambient_light_color = ambient
		env.fog_light_color = fog
