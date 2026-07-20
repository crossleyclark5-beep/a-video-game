class_name CameraOcclusionFader
extends Node
## Soft-fades occludable meshes that sit between the camera and the player.
## Keeps the character readable without hard-hiding world props.

const _OcclusionUtil = preload("res://scripts/systems/camera/occlusion_util.gd")

@export var fade_alpha: float = 0.32
@export var fade_speed: float = 7.0
@export var restore_speed: float = 5.0
@export var max_check_distance: float = 48.0
@export var player_aim_height: float = 1.05
@export var max_fading: int = 24

var _camera: Camera3D = null
var _target: Node3D = null
var _interior_mode: bool = false
var _states: Dictionary = {} ## instance_id -> { mesh, mat, target_a, current_a, base_a }
var _frame: int = 0


func setup(camera: Camera3D, target: Node3D = null) -> void:
	_camera = camera
	_target = target


func set_target(target: Node3D) -> void:
	_target = target


func set_interior_mode(inside: bool) -> void:
	_interior_mode = inside
	if inside:
		## Restore everything — building cutaway owns indoor visibility.
		for id in _states.keys():
			var st: Dictionary = _states[id]
			st["target_a"] = float(st.get("base_a", 1.0))


func _process(delta: float) -> void:
	if _camera == null or _target == null or not is_instance_valid(_target):
		return
	_frame += 1
	## Alternate frames for handheld cost — still feels continuous.
	if _frame % 2 == 1:
		_update_targets()
	_apply_fades(delta)


func _update_targets() -> void:
	var from := _camera.global_position
	var to := _target.global_position + Vector3(0.0, player_aim_height, 0.0)
	var blocking := {}
	if not _interior_mode:
		var tree := get_tree()
		if tree == null:
			return
		var nodes := tree.get_nodes_in_group(_OcclusionUtil.GROUP)
		var checked := 0
		for node in nodes:
			if checked >= max_fading * 3:
				break
			if not (node is MeshInstance3D):
				continue
			var mi := node as MeshInstance3D
			if not is_instance_valid(mi) or not mi.is_visible_in_tree():
				continue
			## Skip player / companion meshes if somehow tagged.
			if mi.is_in_group(GameConstants.GROUP_PLAYER):
				continue
			var origin := mi.global_position
			if origin.distance_to(to) > max_check_distance:
				continue
			checked += 1
			if _segment_hits_mesh(from, to, mi):
				blocking[mi.get_instance_id()] = mi
				if blocking.size() >= max_fading:
					break
	## Update state map.
	for id in blocking.keys():
		var mi: MeshInstance3D = blocking[id]
		_ensure_state(mi)
		_states[id]["target_a"] = fade_alpha
	for id in _states.keys():
		if not blocking.has(id):
			var st: Dictionary = _states[id]
			st["target_a"] = float(st.get("base_a", 1.0))


func _ensure_state(mi: MeshInstance3D) -> void:
	var id := mi.get_instance_id()
	if _states.has(id):
		return
	var mat: StandardMaterial3D
	if mi.material_override is StandardMaterial3D:
		mat = (mi.material_override as StandardMaterial3D).duplicate()
	else:
		mat = StylizedMesh.make_transparent_material(Color(0.55, 0.55, 0.55, 1.0))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	## Keep depth feel — do not write fully invisible pixels.
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	mi.material_override = mat
	var base_a := mat.albedo_color.a
	_states[id] = {
		"mesh": mi,
		"mat": mat,
		"base_a": base_a,
		"current_a": base_a,
		"target_a": base_a,
	}


func _apply_fades(delta: float) -> void:
	var dead: Array = []
	for id in _states.keys():
		var st: Dictionary = _states[id]
		var mi: MeshInstance3D = st["mesh"]
		if not is_instance_valid(mi):
			dead.append(id)
			continue
		var cur: float = float(st["current_a"])
		var tgt: float = float(st["target_a"])
		var spd := fade_speed if tgt < cur else restore_speed
		cur = move_toward(cur, tgt, spd * delta)
		st["current_a"] = cur
		var mat: StandardMaterial3D = st["mat"]
		if mat:
			var c := mat.albedo_color
			c.a = cur
			mat.albedo_color = c
		## Prune fully restored idle states to free dictionary.
		if absf(cur - float(st["base_a"])) < 0.01 and absf(tgt - float(st["base_a"])) < 0.01:
			dead.append(id)
	for id in dead:
		_states.erase(id)


func _segment_hits_mesh(from: Vector3, to: Vector3, mi: MeshInstance3D) -> bool:
	var aabb := mi.get_aabb()
	## Inflate slightly so thin roofs still catch the LOS segment.
	aabb = aabb.grow(0.35)
	var gt := mi.global_transform
	## Transform segment into mesh local space for AABB test.
	var inv := gt.affine_inverse()
	var local_from := inv * from
	var local_to := inv * to
	## Godot 4 AABB.intersects_segment returns the hit point (Variant) or null.
	return aabb.intersects_segment(local_from, local_to) != null
