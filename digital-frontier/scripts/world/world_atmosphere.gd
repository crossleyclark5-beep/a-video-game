class_name WorldAtmosphere
extends Node3D
## Pixel-diorama lighting: one hard sun, discrete sky colors, no AAA bloom.

enum Phase {
	MORNING,
	AFTERNOON,
	EVENING,
}

@export var phase: Phase = Phase.AFTERNOON
@export var enable_shadows: bool = true

var _env_node: WorldEnvironment
var _sun: DirectionalLight3D


func setup(existing_sun: DirectionalLight3D = null) -> void:
	_sun = existing_sun
	if _sun == null:
		_sun = DirectionalLight3D.new()
		_sun.name = "Sun"
		add_child(_sun)
	_configure_environment()
	_configure_sun()
	apply_phase(phase)


func apply_phase(next: Phase) -> void:
	phase = next
	match phase:
		Phase.MORNING:
			_apply_palette(
				WorldPalette.SUN_DAY.lerp(WorldPalette.SKY_MORNING, 0.35),
				1.05,
				WorldPalette.AMBIENT_DAY.lightened(0.05),
				WorldPalette.SKY_MORNING,
				WorldPalette.SKY_MORNING.darkened(0.15),
				Vector3(-38, 50, 0),
			)
		Phase.AFTERNOON:
			_apply_palette(
				WorldPalette.SUN_DAY,
				1.15,
				WorldPalette.AMBIENT_DAY,
				WorldPalette.SKY_DAY,
				WorldPalette.SKY_DAY.darkened(0.2),
				Vector3(-48, 32, 0),
			)
		Phase.EVENING:
			_apply_palette(
				WorldPalette.SKY_EVENING,
				0.9,
				Color(0.45, 0.35, 0.45),
				WorldPalette.SKY_EVENING,
				WorldPalette.SKY_EVENING.darkened(0.25),
				Vector3(-26, 65, 0),
			)


func _configure_environment() -> void:
	_env_node = WorldEnvironment.new()
	_env_node.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = WorldPalette.SKY_DAY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = WorldPalette.AMBIENT_DAY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	## Soft depth without cinematic aerial mush.
	env.fog_enabled = true
	env.fog_light_color = WorldPalette.SKY_DAY.lightened(0.1)
	env.fog_density = 0.0012
	env.fog_aerial_perspective = 0.0
	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	_env_node.environment = env
	add_child(_env_node)


func _configure_sun() -> void:
	_sun.shadow_enabled = enable_shadows
	_sun.light_specular = 0.0
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.shadow_blur = 0.0
	_sun.light_energy = 1.15
	_sun.light_color = WorldPalette.SUN_DAY


func _apply_palette(
	sun_color: Color,
	sun_energy: float,
	ambient: Color,
	sky: Color,
	fog: Color,
	sun_rot_deg: Vector3,
) -> void:
	if _sun:
		_sun.light_color = WorldPalette.quantize(sun_color)
		_sun.light_energy = sun_energy
		_sun.rotation_degrees = sun_rot_deg
	if _env_node and _env_node.environment:
		var env := _env_node.environment
		env.background_color = WorldPalette.quantize(sky)
		env.ambient_light_color = WorldPalette.quantize(ambient)
		env.fog_light_color = WorldPalette.quantize(fog)
