class_name WorldStreamUnit
extends RefCounted
## One streamable region of the world — geometry stays authored; activation changes.


enum Kind {
	TERRAIN,
	HUB,
	VEGETATION,
	LANDMARK,
	DISCOVERY,
	CORRIDOR,
	OTHER,
}

var id: StringName = &""
var kind: Kind = Kind.OTHER
var root: Node3D = null
var origin: Vector3 = Vector3.ZERO
var radius: float = 80.0
var band: AdventureNodeBudget.Band = AdventureNodeBudget.Band.NEAR
var keep_visible_when_far: bool = false ## Landmarks / hubs stay silhouettes at FAR
var always_near: bool = false ## Occupied hub / forced pin

var _saved_process: int = Node.PROCESS_MODE_INHERIT
var _collision_cache: Array[Dictionary] = [] ## {node, layer}
var _captured: bool = false


func capture_defaults() -> void:
	if root == null or _captured:
		return
	_saved_process = root.process_mode
	_collision_cache.clear()
	_cache_collision(root)
	_captured = true


func _cache_collision(node: Node) -> void:
	if node is CollisionObject3D:
		var co := node as CollisionObject3D
		_collision_cache.append({"node": co, "layer": co.collision_layer, "mask": co.collision_mask})
	for c in node.get_children():
		_cache_collision(c)


func apply_band(new_band: AdventureNodeBudget.Band) -> void:
	if root == null or not is_instance_valid(root):
		return
	capture_defaults()
	band = new_band
	match band:
		AdventureNodeBudget.Band.NEAR:
			_set_active(true, true, true)
		AdventureNodeBudget.Band.MEDIUM:
			_set_active(true, true, true)
			## Medium keeps collision for traversal; process stays on for cheap visuals.
			root.process_mode = Node.PROCESS_MODE_INHERIT
		AdventureNodeBudget.Band.FAR:
			var vis := keep_visible_when_far or kind == Kind.TERRAIN or kind == Kind.HUB
			_set_active(vis, false, false)
		AdventureNodeBudget.Band.VERY_FAR:
			## Terrain stays as a distant silhouette for flight; everything else sleeps.
			if kind == Kind.TERRAIN:
				_set_active(true, false, false)
			else:
				_set_active(false, false, false)


func _set_active(visible: bool, processing: bool, collisions: bool) -> void:
	root.visible = visible
	root.process_mode = _saved_process if processing else Node.PROCESS_MODE_DISABLED
	for entry in _collision_cache:
		var co: CollisionObject3D = entry.get("node")
		if co == null or not is_instance_valid(co):
			continue
		if collisions:
			co.collision_layer = int(entry.get("layer", 1))
			co.collision_mask = int(entry.get("mask", 0))
		else:
			co.collision_layer = 0
			co.collision_mask = 0
