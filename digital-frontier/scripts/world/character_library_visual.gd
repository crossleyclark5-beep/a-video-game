class_name CharacterLibraryVisual
extends Node3D
## Drop-in humanoid visual using CharacterKit GLBs + procedural locomotion bob.
## Same public API as HumanoidVisual / CharacterVisual for NPC and player prototypes.


enum AnimState { IDLE, WALK, RUN, INTERACT }

var character_id: StringName = &"hero_a"
var outfit_id: StringName = &""
var _state: AnimState = AnimState.IDLE
var _bob_time: float = 0.0
var _move_amount: float = 0.0
var _running: bool = false
var _interact_t: float = 0.0
var _mesh_root: Node3D = null
var _hip_base_y: float = 0.0


func build(p_character_id: StringName, scale_mul: float = 1.0) -> void:
	character_id = p_character_id
	outfit_id = &""
	for c in get_children():
		c.queue_free()
	_mesh_root = CharacterKit.attach_under(self, character_id, scale_mul, "LibraryMesh")
	_cache_hip_base()
	if _mesh_root == null:
		## Fallback so callers never get an empty visual.
		_mesh_root = Node3D.new()
		_mesh_root.name = "FallbackRoot"
		add_child(_mesh_root)
		StylizedMesh.add_box(_mesh_root, Vector3(0.4, 1.0, 0.3), Color(0.4, 0.55, 0.85), Vector3(0, 0.7, 0), "Fallback")


func build_outfit(p_outfit_id: StringName, scale_mul: float = 1.0) -> void:
	outfit_id = p_outfit_id
	character_id = CharacterOutfitCatalog.mesh_for(p_outfit_id)
	for c in get_children():
		c.queue_free()
	_mesh_root = CharacterKit.attach_outfit(self, p_outfit_id, scale_mul, "LibraryMesh")
	_cache_hip_base()
	if _mesh_root == null:
		build(character_id, scale_mul)


func _cache_hip_base() -> void:
	_hip_base_y = 0.0
	if _mesh_root == null:
		return
	var hip := _mesh_root.get_node_or_null("Hip") as Node3D
	if hip:
		_hip_base_y = hip.position.y


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
	_interact_t = 0.42


func get_anim_state() -> AnimState:
	return _state


## Enhance CharacterLibraryVisual bob to prefer Hip child when present (lookalikes).
func _process(delta: float) -> void:
	_bob_time += delta
	if _mesh_root == null:
		return
	var bob_target: Node3D = _mesh_root.get_node_or_null("Hip") as Node3D
	if bob_target == null:
		bob_target = _mesh_root
	var base_y := _hip_base_y if bob_target != _mesh_root else 0.0
	if _interact_t > 0.0:
		_interact_t -= delta
		var t := 1.0 - clampf(_interact_t / 0.42, 0.0, 1.0)
		bob_target.rotation_degrees.x = sin(t * PI) * -12.0
		bob_target.position.y = base_y + sin(t * PI) * 0.06
		if _interact_t <= 0.0:
			_state = AnimState.IDLE if _move_amount <= 0.08 else (AnimState.RUN if _running else AnimState.WALK)
			bob_target.rotation_degrees.x = 0.0
			bob_target.position.y = base_y
		return
	match _state:
		AnimState.IDLE:
			bob_target.position.y = base_y + sin(_bob_time * 2.2) * 0.025
			bob_target.rotation_degrees.z = sin(_bob_time * 1.4) * 1.8
		AnimState.WALK:
			bob_target.position.y = base_y + absf(sin(_bob_time * 9.0)) * 0.055
			bob_target.rotation_degrees.z = sin(_bob_time * 9.0) * 4.5
		AnimState.RUN:
			bob_target.position.y = base_y + absf(sin(_bob_time * 14.0)) * 0.09
			bob_target.rotation_degrees.z = sin(_bob_time * 14.0) * 7.5
		_:
			bob_target.position.y = base_y
			bob_target.rotation_degrees.z = 0.0
