class_name HumanoidVisual
extends Node3D
## Shared Field Unit humanoid — player-aligned proportions + locomotion bob.
## Used by world NPCs; keeps role color / hat personality without unique GLTFs.


enum AnimState { IDLE, WALK, RUN, INTERACT }

var body_color: Color = Color(0.35, 0.55, 0.85)
var accent_color: Color = Color(0.95, 0.75, 0.3)
var skin_color: Color = Color(0.96, 0.78, 0.62)
var pants_color: Color = Color(0.22, 0.28, 0.4)
var hair_color: Color = Color(0.35, 0.22, 0.15)
var role_hat: int = 0  ## 0 cap, 1 beanie, 2 none, 3 explorer

var _state: AnimState = AnimState.IDLE
var _bob_time: float = 0.0
var _move_amount: float = 0.0
var _running: bool = false
var _interact_t: float = 0.0

var _hip: Node3D
var _torso: Node3D
var _head: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D


func build(p_body: Color, p_accent: Color, hat_style: int = 0, p_hair: Color = Color(-1, -1, -1)) -> void:
	body_color = WorldPalette.quantize(p_body)
	accent_color = WorldPalette.quantize(p_accent)
	role_hat = hat_style
	if p_hair.r >= 0.0:
		hair_color = WorldPalette.quantize(p_hair)
	for c in get_children():
		c.queue_free()
	_build_rig()


func set_move_amount(amount: float, running: bool = false) -> void:
	if _interact_t > 0.0:
		return
	_move_amount = clampf(amount, 0.0, 1.0)
	_running = running and _move_amount > 0.15
	if _move_amount <= 0.08:
		_state = AnimState.IDLE
	elif _running:
		_state = AnimState.RUN
	else:
		_state = AnimState.WALK


func play_interact() -> void:
	_state = AnimState.INTERACT
	_interact_t = 0.45


func get_anim_state() -> AnimState:
	return _state


func _process(delta: float) -> void:
	_bob_time += delta
	if _interact_t > 0.0:
		_interact_t -= delta
		_animate_interact()
		if _interact_t <= 0.0:
			_state = AnimState.IDLE
		return
	match _state:
		AnimState.IDLE:
			_animate_idle()
		AnimState.WALK:
			_animate_locomotion(9.0, 28.0)
		AnimState.RUN:
			_animate_locomotion(14.0, 40.0)
		_:
			_animate_idle()


func _build_rig() -> void:
	_hip = Node3D.new()
	_hip.name = "Hip"
	_hip.position = Vector3(0, 0.55, 0)
	add_child(_hip)

	_torso = Node3D.new()
	_torso.name = "Torso"
	_hip.add_child(_torso)
	StylizedMesh.add_box(_torso, Vector3(0.42, 0.48, 0.28), body_color, Vector3(0, 0.18, 0), "TorsoMesh")
	## Collar / accent stripe
	StylizedMesh.add_box(_torso, Vector3(0.44, 0.06, 0.3), accent_color, Vector3(0, 0.4, 0), "Collar")
	## Pack / badge
	StylizedMesh.add_box(_torso, Vector3(0.28, 0.22, 0.12), body_color.darkened(0.15), Vector3(0, 0.2, -0.18), "Pack")

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0, 0.52, 0)
	_torso.add_child(_head)
	StylizedMesh.add_sphere(_head, 0.2, skin_color, Vector3.ZERO, "HeadMesh")
	StylizedMesh.add_sphere(_head, 0.18, hair_color, Vector3(0, 0.1, -0.02), "Hair")
	StylizedCreatureKit.eye_pair(_head, Vector3(0, 0.02, 0.16), 0.07, 0.035, Color(0.15, 0.18, 0.22))
	match role_hat:
		1:
			StylizedMesh.add_sphere(_head, 0.2, accent_color, Vector3(0, 0.14, 0), "Beanie")
		2:
			pass
		3:
			StylizedMesh.add_box(_head, Vector3(0.38, 0.08, 0.38), accent_color.darkened(0.1), Vector3(0, 0.18, 0.02), "ExplorerHat")
			StylizedMesh.add_box(_head, Vector3(0.42, 0.04, 0.18), accent_color, Vector3(0, 0.14, 0.16), "Brim")
		_:
			StylizedMesh.add_box(_head, Vector3(0.36, 0.08, 0.36), accent_color.darkened(0.2), Vector3(0, 0.16, 0), "Cap")
			StylizedMesh.add_box(_head, Vector3(0.18, 0.04, 0.14), accent_color, Vector3(0, 0.12, 0.18), "Bill")

	_arm_l = _limb(_torso, "ArmL", Vector3(-0.28, 0.28, 0), skin_color, true)
	_arm_r = _limb(_torso, "ArmR", Vector3(0.28, 0.28, 0), skin_color, true)
	_leg_l = _limb(_hip, "LegL", Vector3(-0.12, -0.08, 0), pants_color, false)
	_leg_r = _limb(_hip, "LegR", Vector3(0.12, -0.08, 0), pants_color, false)
	## Shoes
	StylizedMesh.add_box(_leg_l, Vector3(0.12, 0.08, 0.18), Color(0.2, 0.2, 0.22), Vector3(0, -0.42, 0.04), "ShoeL")
	StylizedMesh.add_box(_leg_r, Vector3(0.12, 0.08, 0.18), Color(0.2, 0.2, 0.22), Vector3(0, -0.42, 0.04), "ShoeR")


func _limb(parent: Node3D, lname: String, pos: Vector3, color: Color, is_arm: bool) -> Node3D:
	var n := Node3D.new()
	n.name = lname
	n.position = pos
	parent.add_child(n)
	var h := 0.38 if is_arm else 0.44
	StylizedMesh.add_box(n, Vector3(0.1, h, 0.1), color, Vector3(0, -h * 0.35, 0), lname + "Mesh")
	return n


func _animate_idle() -> void:
	if _hip == null:
		return
	_hip.position.y = 0.55 + sin(_bob_time * 2.2) * 0.02
	_torso.rotation_degrees.x = sin(_bob_time * 1.6) * 2.0
	_arm_l.rotation_degrees.x = lerpf(_arm_l.rotation_degrees.x, 6.0, 0.12)
	_arm_r.rotation_degrees.x = lerpf(_arm_r.rotation_degrees.x, -6.0, 0.12)
	_leg_l.rotation_degrees.x = lerpf(_leg_l.rotation_degrees.x, 0.0, 0.15)
	_leg_r.rotation_degrees.x = lerpf(_leg_r.rotation_degrees.x, 0.0, 0.15)
	_head.rotation_degrees.y = lerpf(_head.rotation_degrees.y, 0.0, 0.1)


func _animate_locomotion(speed: float, swing_deg: float) -> void:
	if _hip == null:
		return
	var swing := sin(_bob_time * speed) * swing_deg * _move_amount
	var bob := absf(sin(_bob_time * speed)) * (0.045 if _state == AnimState.WALK else 0.085) * _move_amount
	_hip.position.y = 0.55 + bob
	_torso.rotation_degrees.x = sin(_bob_time * speed) * (5.0 if _state == AnimState.WALK else 8.0) * _move_amount
	_leg_l.rotation_degrees.x = swing
	_leg_r.rotation_degrees.x = -swing
	_arm_l.rotation_degrees.x = -swing * 0.95
	_arm_r.rotation_degrees.x = swing * 0.95
	_head.rotation_degrees.y = sin(_bob_time * speed * 0.5) * 10.0 * _move_amount


func _animate_interact() -> void:
	if _arm_r == null:
		return
	var t := 1.0 - (_interact_t / 0.45)
	_arm_r.rotation_degrees.x = lerpf(0.0, -70.0, sin(t * PI))
	_arm_l.rotation_degrees.x = lerpf(_arm_l.rotation_degrees.x, 10.0, 0.2)
	_torso.rotation_degrees.x = lerpf(_torso.rotation_degrees.x, 8.0, 0.2)
