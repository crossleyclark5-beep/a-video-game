class_name WorldAtmosphere
extends Node3D
## Pixel-diorama lighting with living atmosphere:
## hard readable shadows, soft lamp glow, weather, full day/night cycle.

enum Phase {
	MORNING,
	AFTERNOON,
	EVENING,
	NIGHT,
}

enum Weather {
	CLEAR,
	RAIN,
	FOG,
	STORM,
}

@export var phase: Phase = Phase.AFTERNOON
@export var weather: Weather = Weather.CLEAR
@export var enable_shadows: bool = true
@export var enable_weather: bool = true
@export var auto_cycle_day: bool = true
@export var auto_cycle_weather: bool = true
## Seconds of real time per full day cycle.
@export var day_cycle_seconds: float = 420.0
@export var weather_cycle_seconds: float = 160.0

var _env_node: WorldEnvironment
var _sun: DirectionalLight3D
var _weather: GPUParticles3D
var _cycle_t: float = 0.35  ## 0..1 through the day; afternoon start.
var _weather_t: float = 0.1
var _phase_hold: float = 0.0

## Static mirrors so ecosystem spawners can query without a node path.
static var _active_phase: int = Phase.AFTERNOON
static var _active_weather: StringName = &"clear"


static func current_phase_index() -> int:
	return _active_phase


static func current_weather_id() -> StringName:
	return _active_weather


static func phase_label(p: int) -> String:
	match p:
		Phase.MORNING: return "Morning"
		Phase.EVENING: return "Evening"
		Phase.NIGHT: return "Night"
		_: return "Day"


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
	apply_weather(weather)


func _process(delta: float) -> void:
	if auto_cycle_day and day_cycle_seconds > 0.1:
		_cycle_t = fposmod(_cycle_t + delta / day_cycle_seconds, 1.0)
		var next := _phase_from_cycle(_cycle_t)
		if next != phase:
			apply_phase(next)
	if auto_cycle_weather and weather_cycle_seconds > 0.1:
		_weather_t = fposmod(_weather_t + delta / weather_cycle_seconds, 1.0)
		var nw := _weather_from_cycle(_weather_t)
		if nw != weather:
			apply_weather(nw)
	_update_weather_drift(delta)


func apply_phase(next: Phase) -> void:
	phase = next
	_active_phase = int(phase)
	EventBus.day_phase_changed.emit(_active_phase)
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
		Phase.NIGHT:
			_apply_palette(
				Color(0.35, 0.45, 0.75),
				0.42,
				Color(0.18, 0.22, 0.38),
				Color(0.08, 0.1, 0.22),
				Color(0.12, 0.14, 0.28),
				Vector3(-20, 75, 0),
				0.55,
			)


func apply_weather(next: Weather) -> void:
	weather = next
	match weather:
		Weather.RAIN:
			_active_weather = &"rain"
		Weather.FOG:
			_active_weather = &"fog"
		Weather.STORM:
			_active_weather = &"storm"
		_:
			_active_weather = &"clear"
	EventBus.weather_changed.emit(_active_weather)
	_restyle_weather_particles()
	if _env_node and _env_node.environment:
		var env := _env_node.environment
		match weather:
			Weather.FOG:
				env.fog_density = 0.00055
			Weather.RAIN, Weather.STORM:
				env.fog_density = 0.00028
			_:
				env.fog_density = 0.00014 if phase != Phase.NIGHT else 0.0002


func _phase_from_cycle(t: float) -> Phase:
	if t < 0.22:
		return Phase.MORNING
	if t < 0.48:
		return Phase.AFTERNOON
	if t < 0.68:
		return Phase.EVENING
	return Phase.NIGHT


func _weather_from_cycle(t: float) -> Weather:
	## Mostly clear, with rain/fog/storm windows.
	if t < 0.55:
		return Weather.CLEAR
	if t < 0.72:
		return Weather.RAIN
	if t < 0.88:
		return Weather.FOG
	return Weather.STORM


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
	_weather.position.x = sin(_phase_hold * 0.07) * 12.0
	_weather.position.z = cos(_phase_hold * 0.05) * 12.0
	match weather:
		Weather.STORM:
			_weather.amount = 90
		Weather.RAIN:
			_weather.amount = 70
		Weather.FOG:
			_weather.amount = 40
		_:
			if phase == Phase.EVENING:
				_weather.amount = 28
			elif phase == Phase.MORNING:
				_weather.amount = 56
			elif phase == Phase.NIGHT:
				_weather.amount = 22
			else:
				_weather.amount = 48


func _restyle_weather_particles() -> void:
	if _weather == null:
		return
	var mat := _weather.process_material as ParticleProcessMaterial
	if mat == null:
		return
	match weather:
		Weather.RAIN, Weather.STORM:
			mat.direction = Vector3(0.15, -1.0, 0.1)
			mat.initial_velocity_min = 4.0
			mat.initial_velocity_max = 7.0
			mat.gravity = Vector3(0, -6.0, 0)
			mat.color = Color(0.65, 0.75, 0.95, 0.55)
		Weather.FOG:
			mat.direction = Vector3(0.2, 0.05, 0.15)
			mat.initial_velocity_min = 0.05
			mat.initial_velocity_max = 0.2
			mat.gravity = Vector3(0, 0.01, 0)
			mat.color = Color(0.85, 0.88, 0.92, 0.35)
		_:
			mat.direction = Vector3(0.35, 0.15, 0.2)
			mat.initial_velocity_min = 0.15
			mat.initial_velocity_max = 0.55
			mat.gravity = Vector3(0, -0.04, 0)
			mat.color = WorldPalette.quantize(Color(0.92, 0.88, 0.55, 0.55))


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
		match phase:
			Phase.EVENING:
				env.glow_intensity = 0.38
				env.fog_density = 0.00018
			Phase.MORNING:
				env.glow_intensity = 0.32
				env.fog_density = 0.00016
			Phase.NIGHT:
				env.glow_intensity = 0.45
				env.fog_density = 0.00022
			_:
				env.glow_intensity = 0.28
				env.fog_density = 0.00014
