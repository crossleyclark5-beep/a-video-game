class_name CharacterVisual
extends Node3D
## Stylized Field Unit adventurer — pixel-toon materials + locomotion / interact.
## Hierarchy stays AnimationPlayer-ready; meshes upgraded to WorldPalette language.

enum AnimState { IDLE, WALK, RUN, INTERACT }

@export var body_color := Color(0.25, 0.55, 0.95)
@export var accent_color := Color(0.95, 0.8, 0.25)
@export var skin_color := Color(0.96, 0.78, 0.62)
@export var pants_color := Color(0.2, 0.28, 0.45)
@export var use_character_library: bool = true
@export var library_character_id: StringName = &"hero_a"

var _state: AnimState = AnimState.IDLE
var _bob_time: float = 0.0
var _move_amount: float = 0.0
var _running: bool = false
var _interact_t: float = 0.0
var _detailed: bool = false
var _library_mode: bool = false
var _library_visual: CharacterLibraryVisual = null

var _hip: Node3D
var _torso: Node3D
var _head: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D


func _ready() -> void:
	_hip = get_node_or_null("Hip") as Node3D
	_torso = get_node_or_null("Hip/Torso") as Node3D
	_head = get_node_or_null("Hip/Torso/Head") as Node3D
	_leg_l = get_node_or_null("Hip/LegL") as Node3D
	_leg_r = get_node_or_null("Hip/LegR") as Node3D
	_arm_l = get_node_or_null("Hip/Torso/ArmL") as Node3D
	_arm_r = get_node_or_null("Hip/Torso/ArmR") as Node3D
	if use_character_library and CharacterKit.is_available():
		_enable_library_mode()
	else:
		_apply_stylized_pass()


func _enable_library_mode() -> void:
	## Higher-detail adventurer mesh; keep hip root for future AnimationPlayer binding.
	_library_mode = true
	if _hip:
		_hip.visible = false
	if _library_visual == null:
		_library_visual = CharacterLibraryVisual.new()
		_library_visual.name = "LibraryVisual"
		add_child(_library_visual)
	## Prefer equipped Item Shop outfit when roster is live.
	if CharacterOutfitCatalog.has_outfit(CharacterRosterManager.get_equipped()):
		_library_visual.build_outfit(CharacterRosterManager.get_equipped(), 1.0)
		return
	var opts := CharacterCatalog.player_options()
	var pick := library_character_id
	if pick == &"" or not CharacterCatalog.has_character(pick):
		pick = opts[0] if not opts.is_empty() else &"hero_a"
	_library_visual.build(pick, 1.0)


func set_library_character(character_id: StringName) -> void:
	library_character_id = character_id
	if _library_visual:
		_library_visual.build(character_id, 1.0)
	elif use_character_library and CharacterKit.is_available():
		_enable_library_mode()


func apply_character_outfit(outfit_id: StringName) -> void:
	## Item Shop roster look — mesh + tint + prop from CharacterOutfitCatalog.
	if not CharacterOutfitCatalog.has_outfit(outfit_id):
		set_library_character(library_character_id)
		return
	library_character_id = CharacterOutfitCatalog.mesh_for(outfit_id)
	if use_character_library and CharacterKit.is_available():
		if _library_visual == null:
			_enable_library_mode()
		if _library_visual:
			_library_visual.build_outfit(outfit_id, 1.0)
		return
	## Procedural fallback — retint body colors from outfit palette.
	var def := CharacterOutfitCatalog.outfit_def(outfit_id)
	body_color = def.get("tint", body_color) as Color
	accent_color = def.get("accent", accent_color) as Color
	_apply_stylized_pass()


func set_move_amount(amount: float, running: bool = false) -> void:
	if _library_mode and _library_visual:
		_library_visual.set_move_amount(amount, running)
		return
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
	## Reach / inspect — used when opening doors, chests, talk.
	if _library_mode and _library_visual:
		_library_visual.play_interact()
		EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)
		return
	_state = AnimState.INTERACT
	_interact_t = 0.42
	EventBus.sfx_play_requested.emit(&"ui_blip", Vector3.ZERO)


func get_anim_state() -> AnimState:
	if _library_mode and _library_visual:
		return _library_visual.get_anim_state() as AnimState
	return _state


func _process(delta: float) -> void:
	if _library_mode:
		return
	_bob_time += delta
	if _interact_t > 0.0:
		_interact_t -= delta
		_animate_interact()
		if _interact_t <= 0.0:
			_state = AnimState.IDLE if _move_amount <= 0.08 else (AnimState.RUN if _running else AnimState.WALK)
		return
	match _state:
		AnimState.IDLE:
			_animate_idle()
		AnimState.WALK:
			_animate_locomotion(9.0, 26.0)
		AnimState.RUN:
			_animate_locomotion(14.0, 38.0)
		_:
			_animate_idle()


func _apply_stylized_pass() -> void:
	## Retint existing meshes into quantized toon materials + add silhouette details.
	_override_named("TorsoMesh", body_color)
	_override_named("HeadMesh", skin_color)
	_override_named("Hair", accent_color)
	_override_named("ArmLMesh", skin_color)
	_override_named("ArmRMesh", skin_color)
	_override_named("LegLMesh", pants_color)
	_override_named("LegRMesh", pants_color)
	if _detailed or _head == null:
		return
	_detailed = true
	## Face + gear — readable on handheld without extra draw-heavy meshes.
	StylizedCreatureKit.eye_pair(_head, Vector3(0, 0.0, 0.18), 0.08, 0.04)
	StylizedMesh.add_box(_torso, Vector3(0.32, 0.08, 0.32), accent_color, Vector3(0, 0.42, 0.02), "Collar")
	StylizedMesh.add_box(_torso, Vector3(0.3, 0.24, 0.14), body_color.darkened(0.18), Vector3(0, 0.15, -0.2), "Backpack")
	StylizedMesh.add_box(_leg_l, Vector3(0.14, 0.08, 0.2), Color(0.18, 0.18, 0.2), Vector3(0, -0.42, 0.05), "ShoeL")
	StylizedMesh.add_box(_leg_r, Vector3(0.14, 0.08, 0.2), Color(0.18, 0.18, 0.2), Vector3(0, -0.42, 0.05), "ShoeR")
	StylizedMesh.add_box(_arm_l, Vector3(0.1, 0.08, 0.1), skin_color.darkened(0.05), Vector3(0, -0.32, 0), "HandL")
	StylizedMesh.add_box(_arm_r, Vector3(0.1, 0.08, 0.1), skin_color.darkened(0.05), Vector3(0, -0.32, 0), "HandR")


func _override_named(mesh_name: String, color: Color) -> void:
	var mi := find_child(mesh_name, true, false) as MeshInstance3D
	if mi:
		StylizedCreatureKit.apply_toon_override(mi, color)


func _animate_idle() -> void:
	if _torso == null:
		return
	_hip.position.y = sin(_bob_time * 2.2) * 0.025
	_torso.rotation_degrees.x = sin(_bob_time * 1.6) * 2.0
	_arm_l.rotation_degrees.x = lerpf(_arm_l.rotation_degrees.x, 8.0, 0.12)
	_arm_r.rotation_degrees.x = lerpf(_arm_r.rotation_degrees.x, -8.0, 0.12)
	_leg_l.rotation_degrees.x = lerpf(_leg_l.rotation_degrees.x, 0.0, 0.15)
	_leg_r.rotation_degrees.x = lerpf(_leg_r.rotation_degrees.x, 0.0, 0.15)
	_head.rotation_degrees.y = lerpf(_head.rotation_degrees.y, 0.0, 0.1)


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


func _animate_interact() -> void:
	if _arm_r == null:
		return
	var t := 1.0 - (_interact_t / 0.42)
	_arm_r.rotation_degrees.x = -75.0 * sin(t * PI)
	_arm_l.rotation_degrees.x = lerpf(_arm_l.rotation_degrees.x, 12.0, 0.2)
	_torso.rotation_degrees.x = lerpf(_torso.rotation_degrees.x, 10.0, 0.2)
	_head.rotation_degrees.x = lerpf(_head.rotation_degrees.x, 8.0, 0.15)
