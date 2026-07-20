class_name CharacterVisual
extends Node3D
## Stylized low-poly humanoid with idle / walk / run motion.
## AnimationPlayer-ready hierarchy for future authored clips.

enum AnimState { IDLE, WALK, RUN }

@export var body_color := Color(0.25, 0.55, 0.95)
@export var accent_color := Color(0.95, 0.8, 0.25)
@export var skin_color := Color(0.96, 0.78, 0.62)

var _state: AnimState = AnimState.IDLE
var _bob_time: float = 0.0
var _move_amount: float = 0.0
var _running: bool = false

@onready var _hip: Node3D = $Hip
@onready var _torso: Node3D = $Hip/Torso
@onready var _head: Node3D = $Hip/Torso/Head
@onready var _leg_l: Node3D = $Hip/LegL
@onready var _leg_r: Node3D = $Hip/LegR
@onready var _arm_l: Node3D = $Hip/Torso/ArmL
@onready var _arm_r: Node3D = $Hip/Torso/ArmR


func set_move_amount(amount: float, running: bool = false) -> void:
	_move_amount = clampf(amount, 0.0, 1.0)
	_running = running and _move_amount > 0.15
	if _move_amount <= 0.08:
		_state = AnimState.IDLE
	elif _running:
		_state = AnimState.RUN
	else:
		_state = AnimState.WALK


func get_anim_state() -> AnimState:
	return _state


func _process(delta: float) -> void:
	_bob_time += delta
	match _state:
		AnimState.IDLE:
			_animate_idle()
		AnimState.WALK:
			_animate_locomotion(9.0, 26.0)
		AnimState.RUN:
			_animate_locomotion(14.0, 38.0)


func _animate_idle() -> void:
	if _torso == null:
		return
	_hip.position.y = sin(_bob_time * 2.2) * 0.025
	_torso.rotation_degrees.x = sin(_bob_time * 1.6) * 2.0
	_arm_l.rotation_degrees.x = lerp(_arm_l.rotation_degrees.x, 8.0, 0.12)
	_arm_r.rotation_degrees.x = lerp(_arm_r.rotation_degrees.x, -8.0, 0.12)
	_leg_l.rotation_degrees.x = lerp(_leg_l.rotation_degrees.x, 0.0, 0.15)
	_leg_r.rotation_degrees.x = lerp(_leg_r.rotation_degrees.x, 0.0, 0.15)
	_head.rotation_degrees.y = lerp(_head.rotation_degrees.y, 0.0, 0.1)


func _animate_locomotion(speed: float, swing_deg: float) -> void:
	if _torso == null:
		return
	var swing := sin(_bob_time * speed) * swing_deg * _move_amount
	var bob := absf(sin(_bob_time * speed)) * (0.05 if _state == AnimState.WALK else 0.09) * _move_amount
	_hip.position.y = bob
	_torso.rotation_degrees.x = sin(_bob_time * speed) * (4.0 if _state == AnimState.WALK else 7.0) * _move_amount
	_leg_l.rotation_degrees.x = swing
	_leg_r.rotation_degrees.x = -swing
	_arm_l.rotation_degrees.x = -swing * 0.9
	_arm_r.rotation_degrees.x = swing * 0.9
	_head.rotation_degrees.y = sin(_bob_time * speed * 0.5) * 8.0 * _move_amount
