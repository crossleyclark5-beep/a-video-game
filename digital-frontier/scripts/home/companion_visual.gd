class_name CompanionVisual
extends Node3D
## Handheld mascot visuals — Emberling (orange dino) + legacy Sparkbit profile.
## Crisp low-poly silhouette, big readable eyes, procedural anims (no heavy clips).

enum Anim {
	IDLE,
	WALK,
	RUN,
	SLEEP,
	EAT,
	HAPPY,
	SAD,
	HUNGRY,
	CURIOUS,
	DISCOVERY,
	STRETCH,
	PET,
}

@export var body_color := Color(0.96, 0.52, 0.22)
@export var accent_color := Color(0.98, 0.78, 0.28)
@export var core_color := Color(1.0, 0.92, 0.75)

signal anim_changed(anim: Anim)

var _anim: Anim = Anim.IDLE
var _time: float = 0.0
var _walk_amount: float = 0.0
var _blink_timer: float = 2.2
var _look_yaw: float = 0.0
var _look_target: float = 0.0
var _look_timer: float = 1.5
var _feedback_flash: float = 0.0
var _profile: StringName = &"emberling"
var _stage: int = 0

var _root: Node3D
var _body: MeshInstance3D
var _belly: MeshInstance3D
var _head: MeshInstance3D
var _snout: MeshInstance3D
var _core: MeshInstance3D
var _crest: MeshInstance3D
var _spike_a: MeshInstance3D
var _spike_b: MeshInstance3D
var _spike_c: MeshInstance3D
var _arm_l: MeshInstance3D
var _arm_r: MeshInstance3D
var _fin_l: MeshInstance3D
var _fin_r: MeshInstance3D
var _eye_l: MeshInstance3D
var _eye_r: MeshInstance3D
var _cheek_l: MeshInstance3D
var _cheek_r: MeshInstance3D
var _tail: MeshInstance3D
var _tail_tip: MeshInstance3D
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
	## Prefer live manager state when available.
	var species := CreatureManager.get_species_data() if CreatureManager else null
	if species:
		apply_from_creature(species, CreatureManager.get_evolution_stage())
	else:
		_build_profile(_profile, _stage)


func apply_species_colors(species: CreatureData) -> void:
	apply_from_creature(species, CreatureManager.get_evolution_stage() if CreatureManager else _stage)


func apply_from_creature(species: CreatureData, stage: int = 0) -> void:
	if species == null:
		return
	body_color = species.body_color
	accent_color = species.accent_color
	core_color = species.core_color
	var profile := species.visual_profile_id
	if profile == &"":
		profile = &"emberling"
	var need_rebuild := _root == null or profile != _profile or stage != _stage
	_profile = profile
	_stage = clampi(stage, 0, 2)
	if need_rebuild:
		_clear_build()
		_build_profile(_profile, _stage)
	_tint_materials()


func refresh_from_manager() -> void:
	var species := CreatureManager.get_species_data()
	if species:
		apply_from_creature(species, CreatureManager.get_evolution_stage())


func set_anim(anim: Anim) -> void:
	if _anim == anim:
		return
	_anim = anim
	anim_changed.emit(anim)


func get_anim() -> Anim:
	return _anim


func set_walk_amount(amount: float) -> void:
	_walk_amount = clampf(amount, 0.0, 1.0)
	if _anim == Anim.SLEEP or _anim == Anim.EAT or _anim == Anim.STRETCH or _anim == Anim.PET:
		return
	if _anim == Anim.DISCOVERY or _anim == Anim.CURIOUS or _anim == Anim.HAPPY:
		return
	if _walk_amount > 0.72:
		set_anim(Anim.RUN)
	elif _walk_amount > 0.12:
		set_anim(Anim.WALK)
	elif _anim == Anim.WALK or _anim == Anim.RUN:
		set_anim(Anim.IDLE)


func set_mood_tint(color: Color) -> void:
	if _body_mat == null:
		return
	_body_mat.albedo_color = body_color.lerp(color, 0.28)
	_body_mat.emission = color.lerp(body_color, 0.4)
	_body_mat.emission_energy_multiplier = 0.35
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
	if _look_timer <= 0.0 and (_anim == Anim.IDLE or _anim == Anim.HUNGRY or _anim == Anim.CURIOUS):
		_look_target = randf_range(-28.0, 28.0)
		_look_timer = randf_range(1.4, 3.2)
	_look_yaw = lerpf(_look_yaw, _look_target, clampf(delta * 2.5, 0.0, 1.0))
	_animate(delta)
	if _orbit_a:
		_orbit_a.rotation.y = _time * 1.4
		_orbit_b.rotation.y = -_time * 1.1
	if _aura:
		_aura.light_energy = 0.5 + sin(_time * 2.0) * 0.08 + _feedback_flash * 0.8


func _clear_build() -> void:
	for child in get_children():
		child.queue_free()
	_root = null
	_body = null
	_belly = null
	_head = null
	_snout = null
	_core = null
	_crest = null
	_spike_a = null
	_spike_b = null
	_spike_c = null
	_arm_l = null
	_arm_r = null
	_fin_l = null
	_fin_r = null
	_eye_l = null
	_eye_r = null
	_cheek_l = null
	_cheek_r = null
	_tail = null
	_tail_tip = null
	_orbit_a = null
	_orbit_b = null
	_leg_fl = null
	_leg_fr = null
	_leg_bl = null
	_leg_br = null
	_aura = null
	_heart_burst = null


func _build_profile(profile: StringName, stage: int) -> void:
	_root = Node3D.new()
	_root.name = "Root"
	add_child(_root)
	_body_mat = _emit_mat(body_color, 0.35)
	_core_mat = _emit_mat(core_color, 1.4)
	if profile == &"sparkbit":
		_build_sparkbit()
	else:
		_build_emberling(stage)
	_build_heart_particles()
	_build_aura()


func _build_emberling(stage: int) -> void:
	## Classic companion-dino silhouette: oversized head, cream belly, stubby arms,
	## thick biped legs, friendly snout. Original Emberling — not franchise IP.
	var s := 1.0 + float(stage) * 0.16
	_root.scale = Vector3(s, s, s)

	var cream := core_color
	var claw := Color(0.95, 0.92, 0.85)
	var eye_green := Color(0.22, 0.72, 0.28)

	## Compact oval torso (smaller than the head — chibi read).
	_body = _sphere(0.26, body_color, Vector3(0, 0.36, 0.02), "Body")
	_body.scale = Vector3(1.15, 1.05, 1.0)
	_body.material_override = _body_mat

	## Cream belly — strong contrast on a small screen.
	_belly = _sphere(0.18, cream, Vector3(0, 0.34, 0.14), "Belly")
	_belly.scale = Vector3(1.05, 1.15, 0.55)
	_belly.material_override = _emit_mat(cream, 0.15)

	## Big rounded head (signature silhouette).
	_head = _sphere(0.34, body_color, Vector3(0, 0.78, 0.06), "Head")
	_head.scale = Vector3(1.12, 1.0, 1.05)
	_head.material_override = _body_mat

	## Soft muzzle + cream lower jaw.
	_snout = _sphere(0.14, body_color.lightened(0.05), Vector3(0, 0.68, 0.30), "Snout")
	_snout.scale = Vector3(1.05, 0.75, 1.15)
	var jaw := _sphere(0.11, cream, Vector3(0, 0.62, 0.28), "Jaw")
	jaw.scale = Vector3(0.95, 0.55, 1.0)
	jaw.material_override = _emit_mat(cream, 0.12)

	## Tiny teeth hint (readable smile).
	var tooth_l := _box(Vector3(0.04, 0.05, 0.03), claw, Vector3(-0.05, 0.64, 0.38), "ToothL")
	_root.add_child(tooth_l)
	var tooth_r := _box(Vector3(0.04, 0.05, 0.03), claw, Vector3(0.05, 0.64, 0.38), "ToothR")
	_root.add_child(tooth_r)

	## Large green eyes — friendly + readable at handheld distance.
	_eye_l = _sphere(0.09, eye_green, Vector3(-0.12, 0.84, 0.28), "EyeL")
	_eye_r = _sphere(0.09, eye_green, Vector3(0.12, 0.84, 0.28), "EyeR")
	_eye_l.material_override = _emit_mat(eye_green, 0.35)
	_eye_r.material_override = _emit_mat(eye_green, 0.35)
	_sphere(0.035, Color(0.05, 0.08, 0.1), Vector3(-0.12, 0.84, 0.35), "PupilL")
	_sphere(0.035, Color(0.05, 0.08, 0.1), Vector3(0.12, 0.84, 0.35), "PupilR")
	_sphere(0.02, Color(1, 1, 1), Vector3(-0.10, 0.87, 0.36), "HiliteL")
	_sphere(0.02, Color(1, 1, 1), Vector3(0.14, 0.87, 0.36), "HiliteR")

	## Soft cheeks
	_cheek_l = _sphere(0.055, Color(1.0, 0.48, 0.32), Vector3(-0.22, 0.72, 0.22), "CheekL")
	_cheek_r = _sphere(0.055, Color(1.0, 0.48, 0.32), Vector3(0.22, 0.72, 0.22), "CheekR")

	## Nostrils
	_sphere(0.02, body_color.darkened(0.2), Vector3(-0.04, 0.72, 0.40), "NostrilL")
	_sphere(0.02, body_color.darkened(0.2), Vector3(0.04, 0.72, 0.40), "NostrilR")

	## Stubby arms + claw tips
	_arm_l = _capsule(0.055, 0.13, body_color.darkened(0.04), Vector3(-0.30, 0.42, 0.06), "ArmL")
	_arm_r = _capsule(0.055, 0.13, body_color.darkened(0.04), Vector3(0.30, 0.42, 0.06), "ArmR")
	_arm_l.rotation_degrees.z = 18.0
	_arm_r.rotation_degrees.z = -18.0
	var claw_l := _box(Vector3(0.08, 0.035, 0.06), claw, Vector3(-0.36, 0.34, 0.10), "ClawL")
	_root.add_child(claw_l)
	var claw_r := _box(Vector3(0.08, 0.035, 0.06), claw, Vector3(0.36, 0.34, 0.10), "ClawR")
	_root.add_child(claw_r)

	## Thick biped legs + big feet
	_leg_fl = _capsule(0.085, 0.20, body_color.darkened(0.1), Vector3(-0.12, 0.14, 0.04), "LegL")
	_leg_fr = _capsule(0.085, 0.20, body_color.darkened(0.1), Vector3(0.12, 0.14, 0.04), "LegR")
	_leg_bl = _sphere(0.09, body_color.darkened(0.12), Vector3(-0.12, 0.05, 0.02), "FootL")
	_leg_br = _sphere(0.09, body_color.darkened(0.12), Vector3(0.12, 0.05, 0.02), "FootR")
	_leg_bl.scale = Vector3(1.35, 0.5, 1.7)
	_leg_br.scale = Vector3(1.35, 0.5, 1.7)
	## Toe claws
	for side_i in [-1, 1]:
		var side := float(side_i)
		for i in 3:
			var ox: float = side * (0.08 + float(i) * 0.04)
			var oz: float = 0.10 - float(i) * 0.02
			var toe := _box(Vector3(0.035, 0.03, 0.05), claw, Vector3(ox, 0.03, oz), "Toe_%d_%d" % [side_i, i])
			_root.add_child(toe)

	## Thick friendly tail
	_tail = _sphere(0.13, body_color, Vector3(0, 0.34, -0.28), "Tail")
	_tail.scale = Vector3(0.85, 0.75, 1.35)
	_tail.material_override = _body_mat
	_tail_tip = _sphere(0.08, body_color.darkened(0.05), Vector3(0, 0.30, -0.48), "TailTip")
	_tail_tip.material_override = _body_mat

	## Tiny head nubs — grow a bit with evolution.
	_spike_a = _sphere(0.06, body_color.darkened(0.08), Vector3(-0.18, 1.02, 0.0), "NubL")
	_spike_a.scale = Vector3(0.55, 0.7 + 0.15 * stage, 0.5)
	_spike_b = _sphere(0.06, body_color.darkened(0.08), Vector3(0.18, 1.02, 0.0), "NubR")
	_spike_b.scale = Vector3(0.55, 0.7 + 0.15 * stage, 0.5)
	if stage >= 1:
		_spike_c = _sphere(0.05, body_color.darkened(0.1), Vector3(0, 1.08, -0.04), "NubMid")
		_spike_c.scale = Vector3(0.45, 0.85, 0.45)
	if stage >= 2:
		var pad_l := _sphere(0.08, body_color.darkened(0.06), Vector3(-0.28, 0.48, 0.0), "ShoulderL")
		pad_l.scale = Vector3(1.1, 0.7, 0.9)
		var pad_r := _sphere(0.08, body_color.darkened(0.06), Vector3(0.28, 0.48, 0.0), "ShoulderR")
		pad_r.scale = Vector3(1.1, 0.7, 0.9)

	## Brow ridges for expression posing
	_fin_l = _sphere(0.05, body_color.darkened(0.1), Vector3(-0.14, 0.96, 0.16), "BrowL")
	_fin_l.scale = Vector3(0.9, 0.35, 0.55)
	_fin_r = _sphere(0.05, body_color.darkened(0.1), Vector3(0.14, 0.96, 0.16), "BrowR")
	_fin_r.scale = Vector3(0.9, 0.35, 0.55)

	_crest = _spike_a
	_core = _belly


func _build_sparkbit() -> void:
	## Legacy cyan spirit — kept for old saves / profile id.
	_body = _sphere(0.34, body_color, Vector3(0, 0.48, 0), "Body")
	_body.scale = Vector3(0.95, 1.15, 0.9)
	_body.material_override = _body_mat
	_core = _sphere(0.12, core_color, Vector3(0, 0.5, 0.22), "Core")
	_core.material_override = _core_mat
	_crest = _sphere(0.1, accent_color, Vector3(0, 0.92, 0), "Crest")
	_crest.scale = Vector3(0.55, 1.4, 0.55)
	_crest.material_override = _emit_mat(accent_color, 1.2)
	_fin_l = _sphere(0.14, accent_color, Vector3(-0.34, 0.62, 0.0), "FinL")
	_fin_l.scale = Vector3(0.55, 1.1, 0.35)
	_fin_r = _sphere(0.14, accent_color, Vector3(0.34, 0.62, 0.0), "FinR")
	_fin_r.scale = Vector3(0.55, 1.1, 0.35)
	_eye_l = _sphere(0.055, Color(0.08, 0.1, 0.16), Vector3(-0.11, 0.58, 0.28), "EyeL")
	_eye_r = _sphere(0.055, Color(0.08, 0.1, 0.16), Vector3(0.11, 0.58, 0.28), "EyeR")
	_cheek_l = _sphere(0.045, Color(1.0, 0.55, 0.55), Vector3(-0.2, 0.48, 0.26), "CheekL")
	_cheek_r = _sphere(0.045, Color(1.0, 0.55, 0.55), Vector3(0.2, 0.48, 0.26), "CheekR")
	_tail = _sphere(0.1, accent_color, Vector3(0, 0.4, -0.38), "Tail")
	_tail.scale = Vector3(0.7, 0.7, 1.3)
	_orbit_a = Node3D.new()
	_orbit_a.name = "OrbitA"
	_orbit_a.position = Vector3(0, 0.55, 0)
	_root.add_child(_orbit_a)
	var bit_a := _box(Vector3(0.06, 0.06, 0.06), core_color, Vector3(0.48, 0.05, 0), "BitA")
	_orbit_a.add_child(bit_a)
	_orbit_b = Node3D.new()
	_orbit_b.name = "OrbitB"
	_orbit_b.position = Vector3(0, 0.55, 0)
	_root.add_child(_orbit_b)
	var bit_b := _box(Vector3(0.05, 0.05, 0.05), accent_color, Vector3(-0.42, -0.08, 0.1), "BitB")
	_orbit_b.add_child(bit_b)
	_leg_fl = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(-0.12, 0.1, 0.12), "LegFL")
	_leg_fr = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(0.12, 0.1, 0.12), "LegFR")
	_leg_bl = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(-0.12, 0.1, -0.12), "LegBL")
	_leg_br = _capsule(0.05, 0.16, body_color.darkened(0.12), Vector3(0.12, 0.1, -0.12), "LegBR")


func _build_aura() -> void:
	## Soft presence only — no AAA bloom orb.
	_aura = OmniLight3D.new()
	_aura.name = "CompanionAura"
	_aura.position = Vector3(0, 0.55, 0)
	_aura.light_color = core_color
	_aura.light_energy = 0.18
	_aura.omni_range = 1.4
	_aura.shadow_enabled = false
	add_child(_aura)


func _build_heart_particles() -> void:
	_heart_burst = GPUParticles3D.new()
	_heart_burst.name = "FeedbackBurst"
	_heart_burst.emitting = false
	_heart_burst.one_shot = true
	_heart_burst.explosiveness = 0.9
	_heart_burst.amount = 10
	_heart_burst.lifetime = 0.7
	_heart_burst.position = Vector3(0, 0.95, 0)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 0.4
	mat.initial_velocity_max = 0.9
	mat.gravity = Vector3(0, 0.6, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.08
	mat.color = Color(1.0, 0.55, 0.35, 0.9)
	_heart_burst.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.04
	draw.height = 0.08
	var draw_mat := _emit_mat(Color(1.0, 0.55, 0.4), 1.5)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.material = draw_mat
	_heart_burst.draw_pass_1 = draw
	add_child(_heart_burst)


func _tint_materials() -> void:
	if _body_mat:
		_body_mat.albedo_color = body_color
		_body_mat.emission = body_color
	if _core_mat:
		_core_mat.albedo_color = core_color
		_core_mat.emission = core_color
	if _aura:
		_aura.light_color = core_color


func _emit_mat(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StylizedMesh.make_material(color, 0.55)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	## Slightly sharper for modern “pixel-inspired” handheld read.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _sphere(radius: float, color: Color, pos: Vector3, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 5
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 1.0)
	mi.position = pos
	_root.add_child(mi)
	return mi


func _box(size: Vector3, color: Color, pos: Vector3, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 1.0)
	mi.position = pos
	return mi


func _capsule(radius: float, height: float, color: Color, pos: Vector3, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(color, 1.0)
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
			_animate_walk(false)
		Anim.RUN:
			_animate_walk(true)
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
		Anim.CURIOUS:
			_animate_curious()
		Anim.DISCOVERY:
			_animate_discovery()
		Anim.STRETCH:
			_animate_stretch()
		Anim.PET:
			_animate_pet()


func _animate_idle() -> void:
	_root.position.y = sin(_time * 2.0) * 0.025
	_root.rotation_degrees = Vector3(0, _look_yaw * 0.4, 0)
	if _body:
		_body.scale = Vector3(1.05, 1.0, 0.95) * (1.0 + sin(_time * 2.2) * 0.03)
	if _head:
		_head.rotation_degrees.y = _look_yaw * 0.5
	if _tail:
		_tail.rotation_degrees.y = sin(_time * 2.6) * 14.0
	if _tail_tip:
		_tail_tip.rotation_degrees.y = sin(_time * 2.6) * 18.0
	if _arm_l:
		_arm_l.rotation_degrees.x = sin(_time * 1.5) * 8.0
		_arm_r.rotation_degrees.x = -sin(_time * 1.5) * 8.0
	_reset_legs(0.12)
	_set_eyes_open(true)
	_orbit_visible(false)


func _animate_walk(running: bool) -> void:
	var speed := 14.0 if running else 9.5
	var amp := 34.0 if running else 24.0
	var swing := sin(_time * speed) * amp * maxf(_walk_amount, 0.35)
	_root.position.y = absf(sin(_time * speed)) * (0.09 if running else 0.05)
	_root.rotation_degrees = Vector3(-6.0 if running else 0.0, 0, 0)
	if _leg_fl:
		_leg_fl.rotation_degrees.x = swing
		_leg_fr.rotation_degrees.x = -swing
	if _arm_l:
		_arm_l.rotation_degrees.x = -swing * 0.6
		_arm_r.rotation_degrees.x = swing * 0.6
	if _tail:
		_tail.rotation_degrees.y = sin(_time * speed) * (28.0 if running else 18.0)
	if _head:
		_head.rotation_degrees.x = -8.0 if running else 0.0
	_set_eyes_open(true)
	_orbit_visible(false)


func _animate_sleep() -> void:
	_root.position.y = lerpf(_root.position.y, -0.04, 0.1)
	_root.rotation_degrees = Vector3(0, 0, lerpf(_root.rotation_degrees.z, 52.0, 0.08))
	if _body:
		_body.scale = Vector3(1.05, 1.0, 0.95) * (1.0 + sin(_time * 1.0) * 0.04)
	_set_eyes_open(false)
	_reset_legs(0.2)
	_orbit_visible(false)


func _animate_eat() -> void:
	_root.position.y = sin(_time * 7.5) * 0.02
	_root.rotation_degrees.x = 14.0 + sin(_time * 7.5) * 5.0
	if _head:
		_head.rotation_degrees.x = 12.0 + sin(_time * 7.5) * 8.0
	_set_eyes_open(true)


func _animate_happy() -> void:
	_root.position.y = absf(sin(_time * 7.0)) * 0.18
	_root.rotation_degrees.y = sin(_time * 5.0) * 18.0
	if _tail:
		_tail.rotation_degrees.y = sin(_time * 14.0) * 42.0
	if _arm_l:
		_arm_l.rotation_degrees.z = 55.0
		_arm_r.rotation_degrees.z = -55.0
	if _cheek_l:
		_cheek_l.scale = Vector3.ONE * (1.0 + sin(_time * 6.0) * 0.2)
		_cheek_r.scale = _cheek_l.scale
	_set_eyes_open(true)


func _animate_sad() -> void:
	_root.position.y = sin(_time * 1.0) * 0.01
	_root.rotation_degrees = Vector3(12.0, 0, 0)
	if _head:
		_head.rotation_degrees.x = 16.0
	if _fin_l:
		_fin_l.rotation_degrees.z = -12.0
		_fin_r.rotation_degrees.z = 12.0
	if _tail:
		_tail.rotation_degrees.x = -18.0
	_set_eyes_open(true)


func _animate_hungry() -> void:
	_root.position.y = sin(_time * 3.0) * 0.02
	_root.rotation_degrees = Vector3(16.0, _look_yaw * 0.7, 0)
	if _snout:
		_snout.scale = Vector3(0.9, 0.7, 1.1) * (1.0 + sin(_time * 5.0) * 0.06)
	_set_eyes_open(true)


func _animate_curious() -> void:
	## Lean in, glance, sniff — investigating the world.
	_root.position.y = sin(_time * 2.4) * 0.02
	_root.rotation_degrees = Vector3(20.0, _look_yaw * 0.9, sin(_time * 1.8) * 4.0)
	if _head:
		_head.rotation_degrees.x = -6.0 + sin(_time * 3.0) * 6.0
	if _tail:
		_tail.rotation_degrees.y = sin(_time * 4.0) * 10.0
	_set_eyes_open(true)


func _animate_discovery() -> void:
	## Spark of joy — hop + tail whip when a secret appears.
	_root.position.y = absf(sin(_time * 9.0)) * 0.16
	_root.rotation_degrees.y = sin(_time * 7.0) * 25.0
	if _tail:
		_tail.rotation_degrees.y = sin(_time * 16.0) * 50.0
	if _arm_l:
		_arm_l.rotation_degrees.z = 48.0
		_arm_r.rotation_degrees.z = -48.0
	_set_eyes_open(true)


func _animate_stretch() -> void:
	_root.position.y = 0.05
	_root.rotation_degrees.x = -18.0 + sin(_time * 2.0) * 4.0
	if _arm_l:
		_arm_l.rotation_degrees.z = 40.0
		_arm_r.rotation_degrees.z = -40.0
	_set_eyes_open(true)


func _animate_pet() -> void:
	_root.position.y = absf(sin(_time * 5.0)) * 0.07
	_root.rotation_degrees.y = sin(_time * 3.0) * 10.0
	if _cheek_l:
		_cheek_l.scale = Vector3.ONE * 1.3
		_cheek_r.scale = Vector3.ONE * 1.3
	if _tail:
		_tail.rotation_degrees.y = sin(_time * 10.0) * 30.0
	_set_eyes_open(true)


func _reset_legs(lerp_w: float) -> void:
	for leg in [_leg_fl, _leg_fr]:
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
