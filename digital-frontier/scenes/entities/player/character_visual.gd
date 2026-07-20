class_name CharacterVisual
extends Node3D
## Stylized low-poly humanoid placeholder with code-driven idle/walk motion.
## Structure is AnimationPlayer-ready: swap meshes later without changing the controller.

enum AnimState { IDLE, WALK }

@export var body_color := Color(0.25, 0.55, 0.95)
@export var accent_color := Color(0.95, 0.8, 0.25)
@export var skin_color := Color(0.96, 0.78, 0.62)

var _state: AnimState = AnimState.IDLE
var _bob_time: float = 0.0
var _walk_amount: float = 0.0

@onready var _hip: Node3D = $Hip
@onready var _torso: Node3D = $Hip/Torso
@onready var _head: Node3D = $Hip/Torso/Head
@onready var _leg_l: Node3D = $Hip/LegL
@onready var _leg_r: Node3D = $Hip/LegR
@onready var _arm_l: Node3D = $Hip/Torso/ArmL
@onready var _arm_r: Node3D = $Hip/Torso/ArmR


func _ready() -> void:
	if _hip == null:
		_build_visual()


func _build_visual() -> void:
	## Fallback if scene parts missing — should not run when using player.tscn.
	pass


func set_move_amount(amount: float) -> void:
	_walk_amount = clampf(amount, 0.0, 1.0)
	_state = AnimState.WALK if _walk_amount > 0.08 else AnimState.IDLE


func _process(delta: float) -> void:
	_bob_time += delta
	match _state:
		AnimState.IDLE:
			_animate_idle(delta)
		AnimState.WALK:
			_animate_walk(delta)


func _animate_idle(_delta: float) -> void:
	if _torso == null:
		return
	var bob := sin(_bob_time * 2.2) * 0.025
	_hip.position.y = bob
	_torso.rotation_degrees.x = sin(_bob_time * 1.6) * 2.0
	_arm_l.rotation_degrees.x = lerp(_arm_l.rotation_degrees.x, 8.0, 0.1)
	_arm_r.rotation_degrees.x = lerp(_arm_r.rotation_degrees.x, -8.0, 0.1)
	_leg_l.rotation_degrees.x = lerp(_leg_l.rotation_degrees.x, 0.0, 0.15)
	_leg_r.rotation_degrees.x = lerp(_leg_r.rotation_degrees.x, 0.0, 0.15)


func _animate_walk(_delta: float) -> void:
	if _torso == null:
		return
	var speed := 9.0 + _walk_amount * 4.0
	var swing := sin(_bob_time * speed) * 28.0 * _walk_amount
	var bob := absf(sin(_bob_time * speed)) * 0.06 * _walk_amount
	_hip.position.y = bob
	_torso.rotation_degrees.x = sin(_bob_time * speed) * 4.0 * _walk_amount
	_leg_l.rotation_degrees.x = swing
	_leg_r.rotation_degrees.x = -swing
	_arm_l.rotation_degrees.x = -swing * 0.85
	_arm_r.rotation_degrees.x = swing * 0.85
	_head.rotation_degrees.y = sin(_bob_time * speed * 0.5) * 6.0 * _walk_amount
