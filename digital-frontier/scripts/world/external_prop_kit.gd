class_name ExternalPropKit
extends RefCounted
## Spawn curated external GLBs with DF toon rematerialization + simple collision.


static var _scene_cache: Dictionary = {}  ## path -> PackedScene
static var _available: bool = true


static func is_available() -> bool:
	## True if at least one curated GLB exists on disk.
	return ResourceLoader.exists(ExternalPropCatalog.prop_path(&"tree_pine"))


static func spawn(
	parent: Node3D,
	prop_id: StringName,
	pos: Vector3,
	yaw_deg: float = 0.0,
	scale_mul: float = 1.0,
	node_name: String = "",
) -> Node3D:
	var def := ExternalPropCatalog.prop_def(prop_id)
	if def.is_empty():
		return null
	var path := ExternalPropCatalog.prop_path(prop_id)
	var packed := _load_scene(path)
	if packed == null:
		return null
	var root := Node3D.new()
	root.name = node_name if node_name != "" else String(prop_id)
	root.position = pos + Vector3(0, float(def.get("y", 0.0)), 0)
	root.rotation_degrees.y = yaw_deg
	var s := float(def.get("scale", 1.0)) * scale_mul
	root.scale = Vector3(s, s, s)
	parent.add_child(root)
	var inst := packed.instantiate() as Node3D
	if inst == null:
		root.queue_free()
		return null
	root.add_child(inst)
	_rematerialize(inst)
	if bool(def.get("collision", false)):
		_add_proxy_collision(root, prop_id)
	## Tree canopies participate in occlusion fade.
	if String(prop_id).begins_with("tree_"):
		_mark_all_meshes_occludable(root)
	return root


static func _load_scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if _scene_cache.has(path):
		return _scene_cache[path] as PackedScene
	if not ResourceLoader.exists(path):
		push_warning("ExternalPropKit: missing %s" % path)
		return null
	var res := load(path)
	if res is PackedScene:
		_scene_cache[path] = res
		return res as PackedScene
	## Some imports return GLTF state differently — try instantiate via packed wrapper.
	push_warning("ExternalPropKit: not a PackedScene %s (%s)" % [path, res])
	return null


static func _rematerialize(node: Node) -> void:
	## Force shared toon/nearest materials so Kenney/Sketchfab meshes match DF.
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var base := Color(0.55, 0.55, 0.55)
		if mi.mesh and mi.mesh.get_surface_count() > 0:
			var active := mi.get_active_material(0)
			if active is BaseMaterial3D:
				base = (active as BaseMaterial3D).albedo_color
			elif mi.mesh.surface_get_material(0) is BaseMaterial3D:
				base = (mi.mesh.surface_get_material(0) as BaseMaterial3D).albedo_color
		var pattern := _guess_pattern(String(mi.name), base)
		mi.material_override = StylizedMesh.make_material(base, 1.0, 0.0, 0.0, pattern)
	for child in node.get_children():
		_rematerialize(child)


static func _guess_pattern(mesh_name: String, color: Color) -> StringName:
	var n := mesh_name.to_lower()
	if "leaf" in n or "foliage" in n or "canopy" in n or color.g > color.r + 0.08 and color.g > 0.35:
		return &"leaf"
	if "wood" in n or "trunk" in n or "log" in n or "plank" in n:
		return &"wood"
	if "rock" in n or "stone" in n or "cliff" in n:
		return &"dirt"
	if "grass" in n:
		return &"grass"
	return &"flat"


static func _add_proxy_collision(root: Node3D, prop_id: String) -> void:
	## Cheap capsule/box collision — avoids per-triangle trimesh cost on handheld.
	var body := StaticBody3D.new()
	body.name = "ProxyCollision"
	root.add_child(body)
	var shape := CollisionShape3D.new()
	var sid := String(prop_id)
	if sid.begins_with("tree_"):
		var cap := CapsuleShape3D.new()
		cap.radius = 0.28
		cap.height = 2.2
		shape.shape = cap
		shape.position = Vector3(0, 1.1, 0)
	elif sid in ["bench", "sofa", "bed", "desk", "coffee_table", "market_stall", "cart"]:
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 0.7, 0.7)
		shape.shape = box
		shape.position = Vector3(0, 0.35, 0)
	elif sid.begins_with("craft_") or sid in ["park_car", "adventure_suv"]:
		var box_v := BoxShape3D.new()
		box_v.size = Vector3(2.4, 1.0, 3.4)
		shape.shape = box_v
		shape.position = Vector3(0, 0.55, 0)
	elif sid == "hangar_small":
		var box_h := BoxShape3D.new()
		box_h.size = Vector3(4.5, 2.4, 4.5)
		shape.shape = box_h
		shape.position = Vector3(0, 1.2, 0)
	elif sid in ["treasure_chest", "supply_crate", "supply_crate_item", "barrel"]:
		var box_c := BoxShape3D.new()
		box_c.size = Vector3(1.1, 0.9, 1.1)
		shape.shape = box_c
		shape.position = Vector3(0, 0.45, 0)
	elif sid in ["fence", "fence_gate"]:
		var box2 := BoxShape3D.new()
		box2.size = Vector3(1.6, 1.0, 0.2)
		shape.shape = box2
		shape.position = Vector3(0, 0.5, 0)
	elif sid == "tent":
		var box3 := BoxShape3D.new()
		box3.size = Vector3(2.2, 1.4, 2.2)
		shape.shape = box3
		shape.position = Vector3(0, 0.7, 0)
	else:
		var sphere := SphereShape3D.new()
		sphere.radius = 0.55
		shape.shape = sphere
		shape.position = Vector3(0, 0.4, 0)
	body.add_child(shape)


static func _mark_all_meshes_occludable(node: Node) -> void:
	if node is MeshInstance3D:
		OcclusionUtil.mark(node as MeshInstance3D)
	for child in node.get_children():
		_mark_all_meshes_occludable(child)
