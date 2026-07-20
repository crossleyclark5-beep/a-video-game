class_name CompanionVisual
extends Node3D
## Procedural companion mesh + mood-driven animation states.
## Ready to swap for authored models / skins later (keep same anim API).

enum Anim {
	IDLE,
	WALK,
	SLEEP,
	EAT,
	HAPPY,
	SAD,
	STRETCH,
}

@export var body_color := Color(0.45, 0.82, 0.85)
@export var belly_color := Color(0.85, 0.95, 0.92)
@export var accent_color := Color(0.95, 0.55, 0.45)

var _anim: Anim = Anim.IDLE
var _time: float = 0.0
var _walk_amount: float = 0.0
var _blink_timer: float = 2.5

var _root: Node3D
var _body: MeshInstance3D
var _belly: MeshInstance3D
var _ear_l: MeshInstance3D
var _ear_r: MeshInstance3D
var _eye_l: MeshInstance3D
var _eye_r: MeshInstance3D
var _tail: MeshInstance3D
var _leg_fl: MeshInstance3D
var _leg_fr: MeshInstance3D
var _leg_bl: MeshInstance3D
var _leg_br: MeshInstance3D
var _aura: OmniLight3D
var _body_mat: StandardMaterial3D


func _ready() -> void:
	_build()


func set_anim(anim: Anim) -> void:
	_anim = anim


func get_anim() -> Anim:
	return _anim


func set_walk_amount(amount: float) -> void:
	_walk_amount = clampf(amount, 0.0, 1.0)
	if _walk_amount > 0.12 and _anim != Anim.SLEEP and _anim != Anim.EAT and _anim != Anim.STRETCH:
		_anim = Anim.WALK
	elif _anim == Anim.WALK and _walk_amount <= 0.08:
		_anim = Anim.IDLE


func set_mood_tint(color: Color) -> void:
	if _body_mat == null:
		return
	_body_mat.albedo_color = body_color.lerp(color, 0.35)
	_body_mat.emission = color
	_body_mat.emission_energy_multiplier = 0.35
	if _aura:
		_aura.light_color = color


func _process(delta: float) -> void:
	_time += delta
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_do_blink()
		_blink_timer = randf_range(2.0, 4.5)
	_animate(delta)


func _build() -> void:
	_root = Node3D.new()
	_root.name = "Root"
	add_child(_root)

	_body_mat = StylizedMesh.make_material(body_color, 0.55)
	_body_mat.emission_enabled = true
	_body_mat.emission = body_color
	_body_mat.emission_energy_multiplier = 0.3

	_body = _sphere(0.38, body_color, Vector3(0, 0.42, 0), "Body")
	_body.material_override = _body_mat
	_belly = _sphere(0.22, belly_color, Vector3(0, 0.32, 0.22), "Belly")
	_ear_l = _sphere(0.12, accent_color, Vector3(-0.22, 0.72, 0.0), "EarL")
	_ear_r = _sphere(0.12, accent_color, Vector3(0.22, 0.72, 0.0), "EarR")
	_eye_l = _sphere(0.055, Color(0.08, 0.1, 0.14), Vector3(-0.12, 0.5, 0.3), "EyeL")
	_eye_r = _sphere(0.055, Color(0.08, 0.1, 0.14), Vector3(0.12, 0.5, 0.3), "EyeR")
	## Eye highlights
	_sphere(0.02, Color(1, 1, 1), Vector3(-0.1, 0.52, 0.34), "HiliteL")
	_sphere(0.02, Color(1, 1, 1), Vector3(0.14, 0.52, 0.34), "HiliteR")
	_tail = _sphere(0.1, accent_color, Vector3(0, 0.35, -0.38), "Tail")

	_leg_fl = _capsule(0.06, 0.18, body_color.darkened(0.1), Vector3(-0.14, 0.1, 0.14), "LegFL")
	_leg_fr = _capsule(0.06, 0.18, body_color.darkened(0.1), Vector3(0.14, 0.1, 0.14), "LegFR")
	_leg_bl = _capsule(0.06, 0.18, body_color.darkened(0.1), Vector3(-0.14, 0.1, -0.14), "LegBL")
	_leg_br = _capsule(0.06, 0.18, body_color.darkened(0.1), Vector3(0.14, 0.1, -0.14), "LegBR")

	_aura = OmniLight3D.new()
	_aura.name = "CompanionAura"
	_aura.position = Vector3(0, 0.5, 0)
	_aura.light_color = body_color
	_aura.light_energy = 0.55
	_aura.omni_range = 2.2
	_aura.shadow_enabled = false
	add_child(_aura)


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
	tween.tween_property(_eye_l, "scale:y", 0.15, 0.06)
	tween.parallel().tween_property(_eye_r, "scale:y", 0.15, 0.06)
	tween.tween_property(_eye_l, "scale:y", 1.0, 0.08)
	tween.parallel().tween_property(_eye_r, "scale:y", 1.0, 0.08)


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
		Anim.STRETCH:
			_animate_stretch()


func _animate_idle() -> void:
	_root.position.y = sin(_time * 2.0) * 0.025
	_root.rotation_degrees.y = lerp(_root.rotation_degrees.y, 0.0, 0.08)
	_body.scale = Vector3.ONE * (1.0 + sin(_time * 2.2) * 0.03)
	_ear_l.rotation_degrees.z = sin(_time * 1.5) * 8.0
	_ear_r.rotation_degrees.z = -sin(_time * 1.5) * 8.0
	_tail.rotation_degrees.y = sin(_time * 3.0) * 18.0
	_reset_legs(0.12)
	_set_eyes_open(true)
	_aura.light_energy = 0.5 + sin(_time * 1.8) * 0.08


func _animate_walk() -> void:
	var speed := 10.0
	var swing := sin(_time * speed) * 28.0 * _walk_amount
	_root.position.y = absf(sin(_time * speed)) * 0.05 * _walk_amount
	_leg_fl.rotation_degrees.x = swing
	_leg_br.rotation_degrees.x = swing
	_leg_fr.rotation_degrees.x = -swing
	_leg_bl.rotation_degrees.x = -swing
	_tail.rotation_degrees.y = sin(_time * speed) * 25.0
	_body.scale = Vector3.ONE
	_set_eyes_open(true)
	_aura.light_energy = 0.6


func _animate_sleep() -> void:
	_root.position.y = lerp(_root.position.y, -0.08, 0.1)
	_root.rotation_degrees.z = lerp(_root.rotation_degrees.z, 55.0, 0.08)
	_body.scale = Vector3.ONE * (1.0 + sin(_time * 1.2) * 0.04)
	_set_eyes_open(false)
	_reset_legs(0.2)
	_aura.light_energy = 0.25 + sin(_time * 1.2) * 0.05


func _animate_eat() -> void:
	_root.position.y = sin(_time * 8.0) * 0.02
	_root.rotation_degrees.x = 18.0 + sin(_time * 8.0) * 6.0
	_body.scale = Vector3(1.0, 1.0 + sin(_time * 8.0) * 0.05, 1.0)
	_set_eyes_open(true)
	_aura.light_energy = 0.7


func _animate_happy() -> void:
	_root.position.y = absf(sin(_time * 7.0)) * 0.18
	_root.rotation_degrees.y = sin(_time * 5.0) * 20.0
	_ear_l.rotation_degrees.z = 25.0
	_ear_r.rotation_degrees.z = -25.0
	_tail.rotation_degrees.y = sin(_time * 12.0) * 40.0
	_set_eyes_open(true)
	_aura.light_energy = 0.9 + sin(_time * 6.0) * 0.15


func _animate_sad() -> void:
	_root.position.y = sin(_time * 1.2) * 0.01
	_root.rotation_degrees.x = 12.0
	_ear_l.rotation_degrees.z = -20.0
	_ear_r.rotation_degrees.z = 20.0
	_body.scale = Vector3(1.05, 0.92, 1.05)
	_set_eyes_open(true)
	_aura.light_energy = 0.3


func _animate_stretch() -> void:
	_root.position.y = 0.05
	_root.rotation_degrees.x = -18.0 + sin(_time * 2.0) * 4.0
	_body.scale = Vector3(1.1, 0.9, 1.15)
	_ear_l.rotation_degrees.z = 15.0
	_ear_r.rotation_degrees.z = -15.0
	_set_eyes_open(true)
	_aura.light_energy = 0.65


func _reset_legs(lerp_w: float) -> void:
	for leg in [_leg_fl, _leg_fr, _leg_bl, _leg_br]:
		if leg:
			leg.rotation_degrees.x = lerp(leg.rotation_degrees.x, 0.0, lerp_w)


func _set_eyes_open(open: bool) -> void:
	if _eye_l == null:
		return
	var sy := 1.0 if open else 0.12
	_eye_l.scale.y = lerp(_eye_l.scale.y, sy, 0.2)
	_eye_r.scale.y = lerp(_eye_r.scale.y, sy, 0.2)
