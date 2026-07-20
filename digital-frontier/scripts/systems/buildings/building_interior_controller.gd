class_name BuildingInteriorController
extends Node
## Owns enter/exit transitions: roof fade, camera zoom, interior visibility, player warp.
## Add to GameWorld and group "building_interior_controller".

@export var camera_rig_path: NodePath
@export var interior_container_path: NodePath

var _camera_rig: Node = null
var _interior_container: Node3D = null
var _active: BuildingVolume = null
var _loaded_interior: Node3D = null
var _current_floor_index: int = 0


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
	if building.is_occupied():
		exit_building(actor)
	else:
		enter_building(building, actor)


func enter_building(building: BuildingVolume, actor: Node) -> void:
	if _active != null:
		return
	_active = building
	building.set_occupied(true)
	InputManager.set_context(InputManager.Context.BUILDING_INTERIOR)
	_fade_roofs(building, 0.0)
	_load_interior(building)
	if actor is Node3D:
		(actor as Node3D).global_position = building.get_interior_entry_position()
	_set_zoom(building.interior_zoom)
	_current_floor_index = 0
	EventBus.building_interior_loaded.emit(building.building_id)


func exit_building(actor: Node) -> void:
	if _active == null:
		return
	var building := _active
	_fade_roofs(building, 1.0)
	_unload_interior()
	if actor is Node3D:
		(actor as Node3D).global_position = building.get_exterior_exit_position()
	_set_zoom(building.exterior_zoom)
	building.set_occupied(false)
	_active = null
	InputManager.set_context(InputManager.Context.OVERWORLD)


func go_to_floor(floor_index: int, actor: Node3D, spawn: Vector3) -> void:
	_current_floor_index = floor_index
	actor.global_position = spawn
	EventBus.ui_notification_requested.emit("Floor: %d" % floor_index, 1.2)


func get_active_building() -> BuildingVolume:
	return _active


func get_current_floor_index() -> int:
	return _current_floor_index


func _fade_roofs(building: BuildingVolume, target_alpha: float) -> void:
	for roof in building.get_roof_meshes():
		if roof.material_override == null:
			roof.material_override = StylizedMesh.make_transparent_material(Color.WHITE)
		elif roof.material_override is StandardMaterial3D:
			var mat := roof.material_override as StandardMaterial3D
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var tween := create_tween()
		tween.tween_property(roof, "modulate:a", target_alpha, 0.4)


func _set_zoom(size: float) -> void:
	if _camera_rig and _camera_rig.has_method("set_zoom_size"):
		_camera_rig.call("set_zoom_size", size)


func _load_interior(building: BuildingVolume) -> void:
	_unload_interior()
	if building.interior_scene == null or _interior_container == null:
		return
	_loaded_interior = building.interior_scene.instantiate()
	_interior_container.add_child(_loaded_interior)
	# Align interior to building world position
	if _loaded_interior is Node3D:
		(_loaded_interior as Node3D).global_position = building.global_position


func _unload_interior() -> void:
	if _loaded_interior and is_instance_valid(_loaded_interior):
		_loaded_interior.queue_free()
	_loaded_interior = null
