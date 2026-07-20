class_name CompanionVisual
extends Node3D
## Stylized digital-fantasy companion placeholder (Sparkbit silhouette).
##
## Unique floating-spirit look — not a realistic animal. Anim API is stable so
## authored meshes / skins can replace the procedural build later.

enum Anim {
	IDLE,
	WALK,
	SLEEP,
	EAT,
	HAPPY,
	SAD,
	HUNGRY,
	STRETCH,
	PET,
}

@export var body_color := Color(0.42, 0.78, 0.92)
@export var accent_color := Color(0.98, 0.55, 0.42)
@export var core_color := Color(0.75, 0.95, 1.0)

signal anim_changed(anim: Anim)

var _anim: Anim = Anim.IDLE
var _time: float = 0.0
var _walk_amount: float = 0.0
var _blink_timer: float = 2.2
var _look_yaw: float = 0.0
var _look_target: float = 0.0
var _look_timer: float = 1.5
var _feedback_flash: float = 0.0

var _root: Node3D
var _body: MeshInstance3D
var _core: MeshInstance3D
var _crest: MeshInstance3D
var _fin_l: MeshInstance3D
var _fin_r: MeshInstance3D
var _eye_l: MeshInstance3D
var _eye_r: MeshInstance3D
var _cheek_l: MeshInstance3D
var _cheek_r: MeshInstance3D
var _tail: MeshInstance3D
var _orbit_a: Node3D
var _orbit_b: Node3D
var _leg_fl: MeshInstance3D
var _leg_fr: MeshInstance3D
var _leg_bl: MeshInstance3D
var _leg_br: MeshInstance3D
var _aura: OmniLight3D
var _body_mat: StandardMaterial3D
var _core_mat: StandardMaterial3D
var _heart_burst: GPUParticles3D


func _ready() -> void:
	_build()


func apply_species_colors(species: CreatureData) -> void:
	if species == null:
		return
	body_color = species.body_color
	accent_color = species.accent_color
	core_color = species.core_color
	if _body_mat:
		_body_mat.albedo_color = body_color
		_body_mat.emission = body_color
	if _core_mat:
		_core_mat.albedo_color = core_color
		_core_mat.emission = core_color
	if _aura:
		_aura.light_color = core_color


func set_anim(anim: Anim) -> void:
	if _anim == anim:
		return
	_anim = anim
	anim_changed.emit(anim)


func get_anim() -> Anim:
	return _anim


func set_walk_amount(amount: float) -> void:
	_walk_amount = clampf(amount, 0.0, 1.0)
	if _walk_amount > 0.12 and _anim != Anim.SLEEP and _anim != Anim.EAT and _anim != Anim.STRETCH and _anim != Anim.PET:
		set_anim(Anim.WALK)
	elif _anim == Anim.WALK and _walk_amount <= 0.08:
		set_anim(Anim.IDLE)


func set_mood_tint(color: Color) -> void:
	if _body_mat == null:
		return
	_body_mat.albedo_color = body_color.lerp(color, 0.28)
	_body_mat.emission = color.lerp(body_color, 0.4)
	_body_mat.emission_energy_multiplier = 0.4
	if _aura:
		_aura.light_color = color.lerp(core_color, 0.35)


func play_feedback_burst(kind: StringName = &"heart") -> void:
	_feedback_flash = 0.45
	if _heart_burst:
		_heart_burst.restart()
	EventBus.sfx_play_requested.emit(StringName("creature_%s" % String(kind)), global_position)


func _process(delta: float) -> void:
	_time += delta
	_blink_timer -= delta
	_look_timer -= delta
	_feedback_flash = maxf(0.0, _feedback_flash - delta)
	if _blink_timer <= 0.0:
		_do_blink()
		_blink_timer = randf_range(1.8, 4.2)
	if _look_timer <= 0.0 and (_anim == Anim.IDLE or _anim == Anim.HUNGRY):
		_look_target = randf_range(-28.0, 28.0)
		_look_timer = randf_range(1.4, 3.2)
	_look_yaw = lerpf(_look_yaw, _look_target, clampf(delta * 2.5, 0.0, 1.0))
	_animate(delta)
	if _orbit_a:
		_orbit_a.rotation.y = _time * 1.4
		_orbit_b.rotation.y = -_time * 1.1
	if _aura:
		_aura.light_energy = 0.55 + sin(_time * 2.0) * 0.08 + _feedback_flash * 0.8


func _build() -> void:
	_root = Node3D.new()
	_root.name = "Root"
	add_child(_root)

	_body_mat = _emit_mat(body_color, 0.45)
	_core_mat = _emit_mat(core_color, 1.8)

	## Pear body — digital spirit silhouette (taller than a blob).
	_body = _sphere(0.34, body_color, Vector3(0, 0.48, 0), "Body")
	_body.scale = Vector3(0.95, 1.15, 0.9)
	_body.material_override = _body_mat

	## Glowing data-core in the chest.
	_core = _sphere(0.12, core_color, Vector3(0, 0.5, 0.22), "Core")
	_core.material_override = _core_mat

	## Antenna crest — unique silhouette read from 2.5D camera.
	_crest = _sphere(0.1, accent_color, Vector3(0, 0.92, 0), "Crest")
	_crest.scale = Vector3(0.55, 1.4, 0.55)
	var crest_mat := _emit_mat(accent_color, 1.2)
	_crest.material_override = crest_mat
	var crest_tip := _sphere(0.07, core_color, Vector3(0, 1.12, 0), "CrestTip")
	crest_tip.material_override = _emit_mat(core_color, 2.0)

	## Soft fin-cheeks (not animal ears — digital fins).
	_fin_l = _sphere(0.14, accent_color, Vector3(-0.34, 0.62, 0.0), "FinL")
	_fin_l.scale = Vector3(0.55, 1.1, 0.35)
	_fin_r = _sphere(0.14, accent_color, Vector3(0.34, 0.62, 0.0), "FinR")
	_fin_r.scale = Vector3(0.55, 1.1, 0.35)

	_eye_l = _sphere(0.055, Color(0.08, 0.1, 0.16), Vector3(-0.11, 0.58, 0.28), "EyeL")
	_eye_r = _sphere(0.055, Color(0.08, 0.1, 0.16), Vector3(0.11, 0.58, 0.28), "EyeR")
	_sphere(0.02, Color(1, 1, 1), Vector3(-0.09, 0.6, 0.32), "HiliteL")
	_sphere(0.02, Color(1, 1, 1), Vector3(0.13, 0.6, 0.32), "HiliteR")

	_cheek_l = _sphere(0.045, Color(1.0, 0.55, 0.55), Vector3(-0.2, 0.48, 0.26), "CheekL")
	_cheek_r = _sphere(0.045, Color(1.0, 0.55, 0.55), Vector3(0.2, 0.48, 0.26), "CheekR")

	## Comet-tail of soft cubes (digital, not fox).
	_tail = _sphere(0.1, accent_color, Vector3(0, 0.4, -0.38), "Tail")
	_tail.scale = Vector3(0.7, 0.7, 1.3)
	_tail.material_override = _emit_mat(accent_color, 0.7)

	## Orbiting bit-shards — fantasy digital identity.
	_orbit_a = Node3D.new()
	_orbit_a.name = "OrbitA"
	_orbit_a.position = Vector3(0, 0.55, 0)
	_root.add_child(_orbit_a)
	var bit_a := _box(Vector3(0.06, 0.06, 0.06), core_color, Vector3(0.48, 0.05, 0), "BitA")
	_orbit_a.add_child(bit_a)
	bit_a.material_override = _emit_mat(core_color, 1.5)

	_orbit_b = Node3D.new()
	_orbit_b.name = "OrbitB"
	_orbit_b.position = Vector3(0, 0.55, 0)
	_root.add_child(_orbit_b)
	var bit_b := _box(Vector3(0.05, 0.05, 0.05), accent_color, Vector3(-0.42, -0.08, 0.1), "BitB")
	_orbit_b.add_child(bit_b)
	bit_b.material_override = _emit_mat(accent_color, 1.2)

	_leg_fl = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(-0.12, 0.1, 0.12), "LegFL")
	_leg_fr = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(0.12, 0.1, 0.12), "LegFR")
	_leg_bl = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(-0.12, 0.1, -0.12), "LegBL")
	_leg_br = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(0.12, 0.1, -0.12), "LegBR")

	_aura = OmniLight3D.new()
	_aura.name = "CompanionAura"
	_aura.position = Vector3(0, 0.55, 0)
	_aura.light_color = core_color
	_aura.light_energy = 0.6
	_aura.omni_range = 2.4
	_aura.shadow_enabled = false
	add_child(_aura)

	_build_heart_particles()


func _build_heart_particles() -> void:
	_heart_burst = GPUParticles3D.new()
	_heart_burst.name = "FeedbackBurst"
	_heart_burst.emitting = false
	_heart_burst.one_shot = true
	_heart_burst.explosiveness = 0.9
	_heart_burst.amount = 10
	_heart_burst.lifetime = 0.7
	_heart_burst.position = Vector3(0, 0.9, 0)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 0.4
	mat.initial_velocity_max = 0.9
	mat.gravity = Vector3(0, 0.6, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.08
	mat.color = Color(1.0, 0.45, 0.55, 0.9)
	_heart_burst.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.04
	draw.height = 0.08
	var draw_mat := _emit_mat(Color(1.0, 0.5, 0.6), 1.5)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.material = draw_mat
	_heart_burst.draw_pass_1 = draw
	add_child(_heart_burst)


func _emit_mat(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StylizedMesh.make_material(color, 0.55)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


func _sphere(radius: float, color: Color, pos: Vector3, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 14
	mesh.rings = 8
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 0.6)
	mi.position = pos
	_root.add_child(mi)
	return mi


func _box(size: Vector3, color: Color, pos: Vector3, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 0.5)
	mi.position = pos
	return mi


func _capsule(radius: float, height: float, color: Color, pos: Vector3, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 0.7)
	mi.position = pos
	_root.add_child(mi)
	return mi


func _do_blink() -> void:
	if _eye_l == null or _anim == Anim.SLEEP:
		return
	var tween := create_tween()
	tween.tween_property(_eye_l, "scale:y", 0.12, 0.05)
	tween.parallel().tween_property(_eye_r, "scale:y", 0.12, 0.05)
	tween.tween_property(_eye_l, "scale:y", 1.0, 0.07)
	tween.parallel().tween_property(_eye_r, "scale:y", 1.0, 0.07)


func _animate(_delta: float) -> void:
	if _root == null:
		return
	match _anim:
		Anim.IDLE:
			_animate_idle()
		Anim.WALK:
			_animate_walk()
		Anim.SLEEP:
			_animate_sleep()
		Anim.EAT:
			_animate_eat()
		Anim.HAPPY:
			_animate_happy()
		Anim.SAD:
			_animate_sad()
		Anim.HUNGRY:
			_animate_hungry()
		Anim.STRETCH:
			_animate_stretch()
		Anim.PET:
			_animate_pet()


func _animate_idle() -> void:
	_root.position.y = sin(_time * 2.1) * 0.03
	_root.rotation_degrees = Vector3(0, _look_yaw * 0.35, 0)
	_body.scale = Vector3(0.95, 1.15, 0.9) * (1.0 + sin(_time * 2.3) * 0.025)
	_fin_l.rotation_degrees.z = 12.0 + sin(_time * 1.6) * 10.0
	_fin_r.rotation_degrees.z = -12.0 - sin(_time * 1.6) * 10.0
	_crest.rotation_degrees.z = sin(_time * 1.8) * 6.0
	_tail.rotation_degrees.y = sin(_time * 2.8) * 16.0
	_reset_legs(0.12)
	_set_eyes_open(true)
	_orbit_visible(true)


func _animate_walk() -> void:
	var speed := 10.0
	var swing := sin(_time * speed) * 26.0 * _walk_amount
	_root.position.y = absf(sin(_time * speed)) * 0.06 * _walk_amount
	_root.rotation_degrees = Vector3(0, 0, 0)
	_leg_fl.rotation_degrees.x = swing
	_leg_br.rotation_degrees.x = swing
	_leg_fr.rotation_degrees.x = -swing
	_leg_bl.rotation_degrees.x = -swing
	_tail.rotation_degrees.y = sin(_time * speed) * 22.0
	_fin_l.rotation_degrees.z = 18.0
	_fin_r.rotation_degrees.z = -18.0
	_set_eyes_open(true)
	_orbit_visible(true)


func _animate_sleep() -> void:
	_root.position.y = lerpf(_root.position.y, -0.05, 0.1)
	_root.rotation_degrees = Vector3(0, 0, lerpf(_root.rotation_degrees.z, 58.0, 0.08))
	_body.scale = Vector3(0.95, 1.15, 0.9) * (1.0 + sin(_time * 1.1) * 0.035)
	_set_eyes_open(false)
	_reset_legs(0.2)
	_orbit_visible(false)


func _animate_eat() -> void:
	_root.position.y = sin(_time * 8.0) * 0.02
	_root.rotation_degrees.x = 16.0 + sin(_time * 8.0) * 5.0
	_body.scale = Vector3(0.95, 1.15 + sin(_time * 8.0) * 0.04, 0.9)
	_set_eyes_open(true)
	_orbit_visible(true)


func _animate_happy() -> void:
	_root.position.y = absf(sin(_time * 7.5)) * 0.2
	_root.rotation_degrees.y = sin(_time * 5.5) * 22.0
	_fin_l.rotation_degrees.z = 30.0
	_fin_r.rotation_degrees.z = -30.0
	_crest.rotation_degrees.z = sin(_time * 8.0) * 12.0
	_tail.rotation_degrees.y = sin(_time * 14.0) * 40.0
	_cheek_l.scale = Vector3.ONE * (1.0 + sin(_time * 6.0) * 0.15)
	_cheek_r.scale = _cheek_l.scale
	_set_eyes_open(true)
	_orbit_visible(true)


func _animate_sad() -> void:
	_root.position.y = sin(_time * 1.1) * 0.01
	_root.rotation_degrees = Vector3(14.0, 0, 0)
	_fin_l.rotation_degrees.z = -18.0
	_fin_r.rotation_degrees.z = 18.0
	_crest.rotation_degrees.x = 20.0
	_body.scale = Vector3(1.02, 1.05, 1.02)
	_set_eyes_open(true)
	_orbit_visible(false)


func _animate_hungry() -> void:
	## Sniff / search — lean forward, glance side to side.
	_root.position.y = sin(_time * 3.0) * 0.02
	_root.rotation_degrees = Vector3(18.0, _look_yaw * 0.8, 0)
	_body.scale = Vector3(0.95, 1.1, 0.95)
	_crest.rotation_degrees.x = -10.0 + sin(_time * 4.0) * 8.0
	_set_eyes_open(true)
	_orbit_visible(true)


func _animate_stretch() -> void:
	_root.position.y = 0.06
	_root.rotation_degrees.x = -20.0 + sin(_time * 2.0) * 4.0
	_body.scale = Vector3(1.05, 1.0, 1.15)
	_fin_l.rotation_degrees.z = 22.0
	_fin_r.rotation_degrees.z = -22.0
	_set_eyes_open(true)
	_orbit_visible(true)


func _animate_pet() -> void:
	_root.position.y = absf(sin(_time * 5.0)) * 0.08
	_root.rotation_degrees.y = sin(_time * 3.0) * 10.0
	_fin_l.rotation_degrees.z = 25.0
	_fin_r.rotation_degrees.z = -25.0
	_cheek_l.scale = Vector3.ONE * 1.25
	_cheek_r.scale = Vector3.ONE * 1.25
	_set_eyes_open(true)
	_orbit_visible(true)


func _reset_legs(lerp_w: float) -> void:
	for leg in [_leg_fl, _leg_fr, _leg_bl, _leg_br]:
		if leg:
			leg.rotation_degrees.x = lerpf(leg.rotation_degrees.x, 0.0, lerp_w)


func _set_eyes_open(open: bool) -> void:
	if _eye_l == null:
		return
	var sy := 1.0 if open else 0.12
	_eye_l.scale.y = lerpf(_eye_l.scale.y, sy, 0.2)
	_eye_r.scale.y = lerpf(_eye_r.scale.y, sy, 0.2)


func _orbit_visible(on: bool) -> void:
	if _orbit_a:
		_orbit_a.visible = on
	if _orbit_b:
		_orbit_b.visible = on
