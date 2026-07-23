class_name WorldAmbienceController
extends Node3D
## Soft ambient life — butterflies, bees, leaves, night motes.
## Few MultiMesh / particle nodes; never competes with gameplay density.


const FOLLOW_RADIUS := 28.0
const TICK := 0.4

var _player: Node3D = null
var _focus: Callable = Callable()
var _tick: float = 0.0
var _time: float = 0.0
var _day_swarm: MultiMeshInstance3D = null
var _night_motes: GPUParticles3D = null
var _leaf_drift: GPUParticles3D = null
var _rng := RandomNumberGenerator.new()


func setup(player: Node3D, focus_getter: Callable = Callable()) -> void:
	_player = player
	_focus = focus_getter
	_rng.randomize()
	name = "WorldAmbience"
	_build_day_swarm()
	_build_leaf_drift()
	_build_night_motes()
	if not EventBus.day_phase_changed.is_connected(_on_phase):
		EventBus.day_phase_changed.connect(_on_phase)
	if not EventBus.weather_changed.is_connected(_on_weather):
		EventBus.weather_changed.connect(_on_weather)
	_refresh_visibility()


func _process(delta: float) -> void:
	_time += delta
	_tick += delta
	if _tick < TICK:
		_nudge_swarm(delta)
		return
	_tick = 0.0
	_follow_focus()
	_refresh_visibility()
	_nudge_swarm(delta)


func _focus_pos() -> Vector3:
	if _focus.is_valid():
		return _focus.call()
	if _player and is_instance_valid(_player):
		return _player.global_position
	return global_position


func _follow_focus() -> void:
	var p := _focus_pos()
	global_position = Vector3(p.x, p.y + 1.2, p.z)


func _build_day_swarm() -> void:
	_day_swarm = MultiMeshInstance3D.new()
	_day_swarm.name = "DayInsects"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.04, 0.18)
	mm.mesh = mesh
	mm.instance_count = 14
	for i in 14:
		mm.set_instance_transform(i, _swarm_xf(i))
	_day_swarm.multimesh = mm
	_day_swarm.material_override = StylizedMesh.make_material(Color(0.95, 0.75, 0.35), 1.0, 0.0, 0.05, &"flat")
	_day_swarm.visibility_range_end = 55.0
	add_child(_day_swarm)


func _build_leaf_drift() -> void:
	_leaf_drift = GPUParticles3D.new()
	_leaf_drift.name = "LeafDrift"
	_leaf_drift.amount = 10
	_leaf_drift.lifetime = 5.5
	_leaf_drift.preprocess = 1.0
	_leaf_drift.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 16, 40))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(16, 3, 16)
	mat.direction = Vector3(1, 0.2, 0.3)
	mat.spread = 25.0
	mat.initial_velocity_min = 0.4
	mat.initial_velocity_max = 1.2
	mat.gravity = Vector3(0, -0.15, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.09
	mat.color = Color(0.45, 0.65, 0.28, 0.55)
	_leaf_drift.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.06
	draw.height = 0.08
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.45, 0.65, 0.28, 0.7)
	leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.material = leaf_mat
	_leaf_drift.draw_pass_1 = draw
	add_child(_leaf_drift)


func _build_night_motes() -> void:
	_night_motes = GPUParticles3D.new()
	_night_motes.name = "NightMotes"
	_night_motes.amount = 12
	_night_motes.lifetime = 6.0
	_night_motes.preprocess = 1.5
	_night_motes.visibility_aabb = AABB(Vector3(-18, -1, -18), Vector3(36, 12, 36))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(14, 2.5, 14)
	mat.direction = Vector3(0, 0.5, 0)
	mat.spread = 50.0
	mat.initial_velocity_min = 0.05
	mat.initial_velocity_max = 0.25
	mat.gravity = Vector3(0, 0.02, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.05
	mat.color = Color(0.55, 0.85, 0.95, 0.45)
	_night_motes.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.04
	draw.height = 0.05
	var mote_mat := StandardMaterial3D.new()
	mote_mat.albedo_color = Color(0.55, 0.85, 0.95, 0.65)
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(0.4, 0.7, 0.9)
	mote_mat.emission_energy_multiplier = 0.6
	draw.material = mote_mat
	_night_motes.draw_pass_1 = draw
	add_child(_night_motes)


func _swarm_xf(i: int) -> Transform3D:
	var a := float(i) * 1.7 + _time
	var r := 3.0 + float(i % 5) * 1.4
	var y := 0.6 + sin(a * 1.3 + float(i)) * 0.5
	var xf := Transform3D.IDENTITY
	xf = xf.scaled(Vector3(0.7 + float(i % 3) * 0.15, 0.7, 0.7))
	xf = xf.rotated(Vector3.UP, a)
	xf.origin = Vector3(cos(a) * r, y, sin(a * 0.9) * r)
	return xf


func _nudge_swarm(_delta: float) -> void:
	if _day_swarm == null or _day_swarm.multimesh == null:
		return
	if not _day_swarm.visible:
		return
	var mm := _day_swarm.multimesh
	for i in mm.instance_count:
		mm.set_instance_transform(i, _swarm_xf(i))


func _on_phase(_phase: int) -> void:
	_refresh_visibility()


func _on_weather(_weather: StringName) -> void:
	_refresh_visibility()
	if _leaf_drift and _leaf_drift.process_material is ParticleProcessMaterial:
		var mat := _leaf_drift.process_material as ParticleProcessMaterial
		var w := WorldWind.strength()
		mat.initial_velocity_min = 0.3 + w * 0.6
		mat.initial_velocity_max = 0.8 + w * 1.4


func _refresh_visibility() -> void:
	var phase := WorldAtmosphere.current_phase_index()
	var weather := WorldAtmosphere.current_weather_id()
	var rainy := weather == &"rain" or weather == &"storm"
	var night := phase == WorldAtmosphere.Phase.NIGHT
	if _day_swarm:
		## Birds/insects vanish in heavy rain; butterflies prefer day.
		_day_swarm.visible = not rainy and not night
	if _night_motes:
		## Crickets / owl-motes after dark (visual stand-in).
		_night_motes.visible = night and not rainy
		_night_motes.emitting = _night_motes.visible
	if _leaf_drift:
		_leaf_drift.visible = WorldWind.strength() >= 0.3
		_leaf_drift.emitting = _leaf_drift.visible
