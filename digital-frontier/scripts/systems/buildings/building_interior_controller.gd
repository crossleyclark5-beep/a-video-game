class_name BuildingInteriorController
extends Node
## Enter/exit: soft move, roof fade, shell cutaway, camera tighten, interior load.
## Player stays in the same adventure scene — never kicked to Home.

@export var camera_rig_path: NodePath
@export var interior_container_path: NodePath
@export var transition_seconds: float = 0.38

var _camera_rig: Node = null
var _interior_container: Node3D = null
var _active: BuildingVolume = null
var _loaded_interior: Node3D = null
var _current_floor_index: int = 0
var _transitioning: bool = false


func _ready() -> void:
	add_to_group(&"building_interior_controller")
	if camera_rig_path:
		_camera_rig = get_node_or_null(camera_rig_path)
	if interior_container_path:
		_interior_container = get_node_or_null(interior_container_path) as Node3D


func setup(camera_rig: Node, interior_container: Node3D) -> void:
	_camera_rig = camera_rig
	_interior_container = interior_container


func toggle_building(building: BuildingVolume, actor: Node) -> void:
	if _transitioning:
		return
	if building.is_occupied():
		exit_building(actor)
	else:
		enter_building(building, actor)


func enter_building(building: BuildingVolume, actor: Node) -> void:
	if _active != null or _transitioning:
		return
	_transitioning = true
	_active = building
	building.set_occupied(true)
	InputManager.set_context(InputManager.Context.BUILDING_INTERIOR)
	_fade_roofs(building, 0.0)
	_load_interior(building)
	_set_interior_camera(true, building.interior_zoom)
	if actor is Node3D:
		await _soft_move_actor(actor as Node3D, building.get_interior_entry_position())
	_snap_companion_to_player(actor)
	_current_floor_index = 0
	EventBus.building_interior_loaded.emit(building.building_id)
	EventBus.ui_notification_requested.emit("Inside %s" % building.display_name, 1.6)
	_transitioning = false


func exit_building(actor: Node) -> void:
	if _active == null or _transitioning:
		return
	_transitioning = true
	var building := _active
	var building_id := building.building_id
	_fade_roofs(building, 1.0)
	_unload_interior()
	_set_interior_camera(false, building.exterior_zoom)
	if actor is Node3D:
		await _soft_move_actor(actor as Node3D, building.get_exterior_exit_position())
	building.set_occupied(false)
	_active = null
	InputManager.set_context(InputManager.Context.OVERWORLD)
	_snap_companion_to_player(actor)
	EventBus.building_exited.emit(building_id)
	EventBus.ui_notification_requested.emit("Back outside", 1.2)
	_transitioning = false


func go_to_floor(floor_index: int, actor: Node3D, spawn: Vector3) -> void:
	_current_floor_index = floor_index
	await _soft_move_actor(actor, spawn)
	EventBus.ui_notification_requested.emit("Floor: %d" % floor_index, 1.2)


func get_active_building() -> BuildingVolume:
	return _active


func get_current_floor_index() -> int:
	return _current_floor_index


func is_inside() -> bool:
	return _active != null


func _soft_move_actor(actor: Node3D, dest: Vector3) -> void:
	## Short ease — feels like stepping through the door, not a scene cut.
	if actor == null or not is_instance_valid(actor):
		return
	if actor.global_position.distance_to(dest) < 0.2:
		actor.global_position = dest
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(actor, "global_position", dest, transition_seconds)
	await tween.finished
	if actor is CharacterBody3D:
		(actor as CharacterBody3D).velocity = Vector3.ZERO


func _snap_companion_to_player(actor: Node) -> void:
	if actor == null or not (actor is Node3D):
		return
	var player := actor as Node3D
	var companions := get_tree().get_nodes_in_group(&"adventure_companion")
	for node in companions:
		if node.has_method("warp_near_player"):
			node.call("warp_near_player", player)
		elif node is Node3D:
			(node as Node3D).global_position = player.global_position + Vector3(-1.1, 0.05, 0.8)


func _fade_roofs(building: BuildingVolume, target_alpha: float) -> void:
	for roof in building.get_roof_meshes():
		_fade_roof_mesh(roof, target_alpha)


func _fade_roof_mesh(roof: MeshInstance3D, target_alpha: float) -> void:
	if roof == null:
		return
	var mat: StandardMaterial3D
	if roof.material_override is StandardMaterial3D:
		mat = (roof.material_override as StandardMaterial3D).duplicate()
	else:
		mat = StylizedMesh.make_transparent_material(Color(0.4, 0.3, 0.25, 1.0))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof.material_override = mat
	var from_a := mat.albedo_color.a
	var tween := create_tween()
	tween.tween_method(_apply_roof_alpha.bind(roof), from_a, target_alpha, transition_seconds)


func _apply_roof_alpha(alpha: float, roof: MeshInstance3D) -> void:
	if not is_instance_valid(roof):
		return
	if roof.material_override is StandardMaterial3D:
		var m := roof.material_override as StandardMaterial3D
		var c := m.albedo_color
		c.a = alpha
		m.albedo_color = c
	roof.visible = alpha > 0.02


func _set_interior_camera(inside: bool, zoom: float) -> void:
	if _camera_rig == null:
		return
	if _camera_rig.has_method("set_interior_mode"):
		_camera_rig.call("set_interior_mode", inside)
	if _camera_rig.has_method("set_zoom_size"):
		_camera_rig.call("set_zoom_size", zoom)


func _load_interior(building: BuildingVolume) -> void:
	_unload_interior()
	if building.interior_scene == null or _interior_container == null:
		return
	_loaded_interior = building.interior_scene.instantiate()
	_interior_container.add_child(_loaded_interior)
	if _loaded_interior is Node3D:
		## Match house rotation + position so rooms line up with the door.
		(_loaded_interior as Node3D).global_transform = building.global_transform


func _unload_interior() -> void:
	if _loaded_interior and is_instance_valid(_loaded_interior):
		_loaded_interior.queue_free()
	_loaded_interior = null
