class_name BuildingVolume
extends Node3D
## Enterable building shell. Door toggles interior; roof/shell cut away so the room stays visible.

@export var building_id: StringName = &""
@export var display_name: String = "House"
## Handcrafted interior override. When null, ModularInteriorBuilder uses interior_kind.
@export var interior_scene: PackedScene
@export var interior_kind: StringName = &"house"
@export var interior_personality: int = -1  ## InteriorPersonality.Style or -1 = derive
@export var exterior_zoom: float = 14.5
@export var interior_zoom: float = 9.5
@export var roof_paths: Array[NodePath] = []
## Extra meshes hidden while inside (solid Body, peaks, etc.).
@export var cutaway_paths: Array[NodePath] = []

var _door: Interactable = null
var _occupied: bool = false
var _cutaway_meshes: Array[MeshInstance3D] = []
var _cutaway_bodies: Array[CollisionObject3D] = []


func _ready() -> void:
	if building_id == &"":
		building_id = StringName(name.to_snake_case())
	_cache_cutaway_nodes()
	call_deferred("_bind_door")


func bind_door_now() -> void:
	## Call after runtime set_script + door spawn (builder path).
	_cache_cutaway_nodes()
	_bind_door()


func _bind_door() -> void:
	_door = get_node_or_null("DoorInteractable") as Interactable
	if _door == null:
		return
	_door.once = false
	_door.prompt_verb = "Exit" if _occupied else "Enter %s" % display_name
	if not _door.interacted.is_connected(_on_door_interacted):
		_door.interacted.connect(_on_door_interacted)


func is_occupied() -> bool:
	return _occupied


func set_occupied(value: bool) -> void:
	## Keep the door interactable — Exit must always work on handheld.
	_occupied = value
	if _door:
		_door.enabled = true
		_door.once = false
		_door.prompt_verb = "Exit" if value else "Enter %s" % display_name
	set_cutaway(value)


func set_cutaway(cutaway: bool) -> void:
	_cache_cutaway_nodes()
	for mesh in _cutaway_meshes:
		if is_instance_valid(mesh):
			mesh.visible = not cutaway
	for body in _cutaway_bodies:
		if is_instance_valid(body):
			## Keep doorway free inside; restore exterior collision when outside.
			body.collision_layer = 0 if cutaway else 1


func get_roof_meshes() -> Array[MeshInstance3D]:
	var roofs: Array[MeshInstance3D] = []
	for path in roof_paths:
		_collect_mesh_at(path, roofs)
	for fallback_name in ["Roof", "RoofPeak", "PorchRoof"]:
		var node := get_node_or_null(fallback_name)
		_append_mesh_node(node, roofs)
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


func resolve_interior() -> Node3D:
	## Prefer unique handcrafted scenes; otherwise generate a themed modular room.
	if interior_scene != null:
		return interior_scene.instantiate() as Node3D
	var personality := interior_personality
	if personality < 0:
		personality = InteriorPersonality.from_building_id(building_id, interior_kind)
	return ModularInteriorBuilder.build(interior_kind, building_id, 0, personality)


func _on_door_interacted(actor: Node) -> void:
	EventBus.building_enter_requested.emit(building_id)
	var tree := get_tree()
	if tree == null:
		return
	var controllers := tree.get_nodes_in_group(&"building_interior_controller")
	if not controllers.is_empty() and controllers[0].has_method("toggle_building"):
		controllers[0].call("toggle_building", self, actor)


func _cache_cutaway_nodes() -> void:
	_cutaway_meshes.clear()
	_cutaway_bodies.clear()
	var names := [
		"Body", "RoofPeak", "PorchRoof", "Garage", "Chimney", "ChimneyCap", "Belt",
		"ShellFloor", "Yard",
		## Front wall cutaway so the camera can see into the occupied room.
		"WallF1", "WallF2", "Door", "DoorFrame",
	]
	for n in names:
		var node := get_node_or_null(n)
		_append_cutaway(node)
	for path in cutaway_paths:
		_append_cutaway(get_node_or_null(path))


func _append_cutaway(node: Node) -> void:
	if node == null:
		return
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		if not _cutaway_bodies.has(body):
			_cutaway_bodies.append(body)
	_append_mesh_node(node, _cutaway_meshes)
	for child in node.get_children():
		_append_mesh_node(child, _cutaway_meshes)


func _collect_mesh_at(path: NodePath, into: Array[MeshInstance3D]) -> void:
	_append_mesh_node(get_node_or_null(path), into)


func _append_mesh_node(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if not into.has(mesh):
			into.append(mesh)
	elif node != null:
		for child in node.get_children():
			if child is MeshInstance3D:
				var mesh := child as MeshInstance3D
				if not into.has(mesh):
					into.append(mesh)
