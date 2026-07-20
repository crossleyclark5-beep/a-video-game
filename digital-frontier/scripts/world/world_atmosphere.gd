class_name WorldAtmosphere
extends Node3D
## Pixel-diorama lighting with living atmosphere:
## hard readable shadows, soft lamp glow, light weather, slow time-of-day.

enum Phase {
	MORNING,
	AFTERNOON,
	EVENING,
}

@export var phase: Phase = Phase.AFTERNOON
@export var enable_shadows: bool = true
@export var enable_weather: bool = true
@export var auto_cycle_day: bool = true
## Seconds of real time per full day cycle (morning→afternoon→evening→morning).
@export var day_cycle_seconds: float = 420.0

var _env_node: WorldEnvironment
var _sun: DirectionalLight3D
var _weather: GPUParticles3D
var _cycle_t: float = 0.35  ## 0..1 through the day; afternoon start.
var _phase_hold: float = 0.0


func setup(existing_sun: DirectionalLight3D = null) -> void:
	_sun = existing_sun
	if _sun == null:
		_sun = DirectionalLight3D.new()
		_sun.name = "Sun"
		add_child(_sun)
	_configure_environment()
	_configure_sun()
	if enable_weather:
		_configure_weather()
	apply_phase(phase)


func _process(delta: float) -> void:
	if not auto_cycle_day or day_cycle_seconds <= 0.1:
		return
	_cycle_t = fposmod(_cycle_t + delta / day_cycle_seconds, 1.0)
	var next := _phase_from_cycle(_cycle_t)
	if next != phase:
		apply_phase(next)
	_update_weather_drift(delta)


func apply_phase(next: Phase) -> void:
	phase = next
	match phase:
		Phase.MORNING:
			_apply_palette(
				WorldPalette.SUN_DAY.lerp(WorldPalette.SKY_MORNING, 0.35),
				1.08,
				WorldPalette.AMBIENT_DAY.lightened(0.06),
				WorldPalette.SKY_MORNING,
				WorldPalette.SKY_MORNING.darkened(0.12),
				Vector3(-38, 50, 0),
				0.62,
			)
		Phase.AFTERNOON:
			_apply_palette(
				WorldPalette.SUN_DAY,
				1.18,
				WorldPalette.AMBIENT_DAY,
				WorldPalette.SKY_DAY,
				WorldPalette.SKY_DAY.darkened(0.18),
				Vector3(-48, 32, 0),
				0.68,
			)
		Phase.EVENING:
			_apply_palette(
				WorldPalette.SKY_EVENING,
				0.92,
				Color(0.48, 0.36, 0.42),
				WorldPalette.SKY_EVENING,
				WorldPalette.SKY_EVENING.darkened(0.22),
				Vector3(-26, 65, 0),
				0.78,
			)


func _phase_from_cycle(t: float) -> Phase:
	if t < 0.28:
		return Phase.MORNING
	if t < 0.62:
		return Phase.AFTERNOON
	return Phase.EVENING


func _configure_environment() -> void:
	_env_node = WorldEnvironment.new()
	_env_node.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = WorldPalette.SKY_DAY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = WorldPalette.AMBIENT_DAY
	env.ambient_light_energy = 0.58
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.02
	## Soft depth without washing out distant grassland POIs.
	env.fog_enabled = true
	env.fog_light_color = WorldPalette.SKY_DAY.lightened(0.1)
	env.fog_density = 0.00014
	env.fog_aerial_perspective = 0.05
	## Soft pixel glow — lamps / water sparkle, not cinematic bloom wash.
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_strength = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.85
	env.glow_hdr_scale = 1.2
	env.set_glow_level(1, 0.0)
	env.set_glow_level(2, 0.6)
	env.set_glow_level(3, 0.4)
	env.set_glow_level(4, 0.2)
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	_env_node.environment = env
	add_child(_env_node)


func _configure_sun() -> void:
	_sun.shadow_enabled = enable_shadows
	_sun.light_specular = 0.0
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	## Tiny blur keeps hard pixel edges readable while softening stair-step aliasing.
	_sun.shadow_blur = 0.35
	_sun.light_energy = 1.18
	_sun.light_color = WorldPalette.SUN_DAY
	_sun.directional_shadow_max_distance = 200.0
	_sun.shadow_opacity = 0.72
	_sun.directional_shadow_pancake_size = 2.0


func _configure_weather() -> void:
	## Sparse cube pollen / dust — cheap handheld weather read.
	_weather = GPUParticles3D.new()
	_weather.name = "WeatherMotes"
	_weather.amount = 48
	_weather.lifetime = 9.0
	_weather.preprocess = 4.0
	_weather.visibility_aabb = AABB(Vector3(-80, -5, -80), Vector3(160, 40, 160))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.35, 0.15, 0.2)
	mat.spread = 55.0
	mat.initial_velocity_min = 0.15
	mat.initial_velocity_max = 0.55
	mat.gravity = Vector3(0, -0.04, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.09
	mat.color = WorldPalette.quantize(Color(0.92, 0.88, 0.55, 0.55))
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(55, 12, 55)
	_weather.process_material = mat
	var draw := BoxMesh.new()
	draw.size = Vector3(0.08, 0.08, 0.08)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = WorldPalette.FLOWER_Y
	draw_mat.roughness = 1.0
	draw_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	draw_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	draw_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.albedo_color.a = 0.55
	_weather.draw_pass_1 = draw
	_weather.material_override = draw_mat
	_weather.position = Vector3(0, 8, 0)
	add_child(_weather)


func _update_weather_drift(delta: float) -> void:
	if _weather == null:
		return
	_phase_hold += delta
	## Slow drift so motes feel like breeze without tracking the player (cheap).
	_weather.position.x = sin(_phase_hold * 0.07) * 12.0
	_weather.position.z = cos(_phase_hold * 0.05) * 12.0
	if phase == Phase.EVENING:
		_weather.amount = 28
	elif phase == Phase.MORNING:
		_weather.amount = 56
	else:
		_weather.amount = 48


func _apply_palette(
	sun_color: Color,
	sun_energy: float,
	ambient: Color,
	sky: Color,
	fog: Color,
	sun_rot_deg: Vector3,
	shadow_opacity: float = 0.7,
) -> void:
	if _sun:
		_sun.light_color = WorldPalette.quantize(sun_color)
		_sun.light_energy = sun_energy
		_sun.rotation_degrees = sun_rot_deg
		_sun.shadow_opacity = shadow_opacity
	if _env_node and _env_node.environment:
		var env := _env_node.environment
		env.background_color = WorldPalette.quantize(sky)
		env.ambient_light_color = WorldPalette.quantize(ambient)
		env.fog_light_color = WorldPalette.quantize(fog)
		## Slightly warmer fog + glow at evening for atmosphere.
		if phase == Phase.EVENING:
			env.glow_intensity = 0.38
			env.fog_density = 0.00018
		elif phase == Phase.MORNING:
			env.glow_intensity = 0.32
			env.fog_density = 0.00016
		else:
			env.glow_intensity = 0.28
			env.fog_density = 0.00014
