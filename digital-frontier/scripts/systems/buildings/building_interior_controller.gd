class_name BuildingInteriorController
extends Node
## Enter/exit + multi-floor visibility for any building height.
## Player always sees the floor they occupy; camera rises with the story.

@export var camera_rig_path: NodePath
@export var interior_container_path: NodePath
@export var transition_seconds: float = 0.38

var _camera_rig: Node = null
var _interior_container: Node3D = null
var _active: BuildingVolume = null
var _loaded_interior: Node3D = null
var _current_floor_index: int = 0
var _transitioning: bool = false
var _interior_light: OmniLight3D = null
var _floors: Array[BuildingFloor] = []


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
	_apply_floor_visibility(0)
	_sync_camera_to_floor(0)
	_ensure_interior_light(true)
	EventBus.building_interior_loaded.emit(building.building_id)
	var fname := _floor_label(0)
	EventBus.ui_notification_requested.emit("Inside %s · %s" % [building.display_name, fname], 1.8)
	_transitioning = false


func exit_building(actor: Node) -> void:
	if _active == null or _transitioning:
		return
	_transitioning = true
	var building := _active
	var building_id := building.building_id
	_ensure_interior_light(false)
	_fade_roofs(building, 1.0)
	_unload_interior()
	_set_interior_camera(false, building.exterior_zoom)
	_clear_camera_floor()
	if actor is Node3D:
		await _soft_move_actor(actor as Node3D, building.get_exterior_exit_position())
	building.set_occupied(false)
	_active = null
	_floors.clear()
	_current_floor_index = 0
	InputManager.set_context(InputManager.Context.OVERWORLD)
	_snap_companion_to_player(actor)
	EventBus.building_exited.emit(building_id)
	EventBus.ui_notification_requested.emit("Back outside", 1.2)
	_transitioning = false


func go_to_floor(floor_index: int, actor: Node3D, spawn: Vector3) -> void:
	if _transitioning or _active == null:
		return
	_transitioning = true
	## Reveal destination floor before the move so the player never vanishes.
	_apply_floor_visibility(floor_index)
	_sync_camera_to_floor(floor_index)
	await _soft_move_actor(actor, spawn)
	_current_floor_index = floor_index
	_snap_companion_to_player(actor)
	EventBus.ui_notification_requested.emit(_floor_label(floor_index), 1.4)
	_transitioning = false


func get_active_building() -> BuildingVolume:
	return _active


func get_current_floor_index() -> int:
	return _current_floor_index


func get_floor_count() -> int:
	return _floors.size()


func is_inside() -> bool:
	return _active != null


func _soft_move_actor(actor: Node3D, dest: Vector3) -> void:
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


func _sync_camera_to_floor(floor_index: int) -> void:
	if _camera_rig == null:
		return
	var fl := _find_floor(floor_index)
	var ground := _find_floor(0)
	var relative := 0.0
	if fl and ground:
		relative = fl.get_focus_height() - ground.get_focus_height()
	elif fl:
		relative = fl.global_position.y
	if _camera_rig.has_method("set_floor_focus_height"):
		_camera_rig.call("set_floor_focus_height", relative)
	_place_interior_light(fl)


func _clear_camera_floor() -> void:
	if _camera_rig and _camera_rig.has_method("set_floor_focus_height"):
		_camera_rig.call("set_floor_focus_height", 0.0)


func _load_interior(building: BuildingVolume) -> void:
	_unload_interior()
	if _interior_container == null:
		return
	_loaded_interior = building.resolve_interior()
	if _loaded_interior == null:
		return
	_interior_container.add_child(_loaded_interior)
	if _loaded_interior is Node3D:
		(_loaded_interior as Node3D).global_transform = building.global_transform
	_collect_floors()
	## Default: only ground story until stairs are used.
	_apply_floor_visibility(0)


func _unload_interior() -> void:
	if _loaded_interior and is_instance_valid(_loaded_interior):
		_loaded_interior.queue_free()
	_loaded_interior = null
	_floors.clear()


func _collect_floors() -> void:
	_floors.clear()
	if _loaded_interior == null:
		return
	for child in _loaded_interior.find_children("*", "BuildingFloor", true, false):
		if child is BuildingFloor:
			_floors.append(child as BuildingFloor)
	_floors.sort_custom(func(a: BuildingFloor, b: BuildingFloor) -> bool:
		return a.floor_index < b.floor_index
	)


func _apply_floor_visibility(active_index: int) -> void:
	if _floors.is_empty():
		_collect_floors()
	for fl in _floors:
		if fl.floor_index == active_index:
			fl.set_floor_state(BuildingFloor.FloorState.ACTIVE)
		elif fl.floor_index < active_index:
			fl.set_floor_state(BuildingFloor.FloorState.BELOW)
		else:
			fl.set_floor_state(BuildingFloor.FloorState.ABOVE)


func _find_floor(index: int) -> BuildingFloor:
	for fl in _floors:
		if fl.floor_index == index:
			return fl
	return null


func _floor_label(index: int) -> String:
	var fl := _find_floor(index)
	if fl and not fl.floor_name.is_empty():
		return fl.floor_name
	if index <= 0:
		return "Ground Floor"
	return "Floor %d" % (index + 1)


func _ensure_interior_light(on: bool) -> void:
	if not on:
		if _interior_light and is_instance_valid(_interior_light):
			_interior_light.queue_free()
		_interior_light = null
		return
	if _interior_light and is_instance_valid(_interior_light):
		_place_interior_light(_find_floor(_current_floor_index))
		return
	if _loaded_interior == null:
		return
	_interior_light = OmniLight3D.new()
	_interior_light.name = "InteriorFill"
	_interior_light.light_color = Color(1.0, 0.95, 0.85)
	_interior_light.light_energy = 1.35
	_interior_light.omni_range = 14.0
	_interior_light.shadow_enabled = false
	_loaded_interior.add_child(_interior_light)
	_place_interior_light(_find_floor(_current_floor_index))


func _place_interior_light(fl: BuildingFloor) -> void:
	if _interior_light == null or not is_instance_valid(_interior_light):
		return
	var y := 2.4
	if fl:
		## Local Y above the occupied story so light travels with floor switches.
		y = fl.position.y + 2.4
	_interior_light.position = Vector3(0, y, 0)
