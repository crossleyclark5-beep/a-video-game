class_name BuildingVolume
extends Node3D
## Data + nodes for an enterable building. Works with BuildingInteriorController.
## Keep roof meshes listed for fade; interior can be inlined or a PackedScene.

@export var building_id: StringName = &""
@export var display_name: String = "House"
@export var interior_scene: PackedScene
@export var exterior_zoom: float = 14.5
@export var interior_zoom: float = 11.0
@export var roof_paths: Array[NodePath] = []

var _door: Interactable = null
var _occupied: bool = false


func _ready() -> void:
	if building_id == &"":
		building_id = StringName(name.to_snake_case())
	call_deferred("_bind_door")


func _bind_door() -> void:
	_door = get_node_or_null("DoorInteractable") as Interactable
	if _door:
		_door.prompt_text = "Press E to enter %s" % display_name
		if not _door.interacted.is_connected(_on_door_interacted):
			_door.interacted.connect(_on_door_interacted)


func is_occupied() -> bool:
	return _occupied


func set_occupied(value: bool) -> void:
	_occupied = value
	if _door:
		_door.enabled = not value
		_door.prompt_text = (
			"Press E to exit" if value else "Press E to enter %s" % display_name
		)


func get_roof_meshes() -> Array[MeshInstance3D]:
	var roofs: Array[MeshInstance3D] = []
	for path in roof_paths:
		var node := get_node_or_null(path)
		if node is MeshInstance3D:
			roofs.append(node)
	# Fallback: child named Roof
	var roof := get_node_or_null("Roof")
	if roof is MeshInstance3D and not roofs.has(roof):
		roofs.append(roof)
	return roofs


func get_exterior_exit_position() -> Vector3:
	var marker := get_node_or_null("ExteriorExit") as Marker3D
	if marker:
		return marker.global_position
	return to_global(Vector3(0, 0.15, 5.5))


func get_interior_entry_position() -> Vector3:
	var marker := get_node_or_null("InteriorEntry") as Marker3D
	if marker:
		return marker.global_position
	return to_global(Vector3(0, 0.15, 0.2))


func _on_door_interacted(actor: Node) -> void:
	EventBus.building_enter_requested.emit(building_id)
	# Controller listens and decides enter vs exit based on occupied state.
	var tree := get_tree()
	if tree == null:
		return
	var controllers := tree.get_nodes_in_group(&"building_interior_controller")
	if not controllers.is_empty() and controllers[0].has_method("toggle_building"):
		controllers[0].call("toggle_building", self, actor)
