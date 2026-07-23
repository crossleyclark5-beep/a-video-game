class_name ExternalPropKit
extends RefCounted
## Spawn curated external GLBs through the Asset Standardization Pipeline.


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
	accent: Color = Color.WHITE,
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
	## mesh_yaw aligns Kenney +Z nose with world / vehicle −Z forward when needed.
	root.rotation_degrees.y = yaw_deg + float(def.get("mesh_yaw", 0.0))
	parent.add_child(root)
	var inst := packed.instantiate() as Node3D
	if inst == null:
		root.queue_free()
		return null
	root.add_child(inst)
	## Pipeline: textures kept when present; white → DF palette; toon + nearest.
	var mode: StringName = &"vehicle" if def.get("category", &"") == &"transport" else &"prop"
	var tint: Color = accent
	if tint == Color.WHITE and def.has("tint"):
		tint = def.get("tint", Color.WHITE) as Color
	AssetStandardizer.rematerialize(inst, mode, tint)
	## Prefer measured height fit when catalog declares target_height (world scale bible).
	var target_h := float(def.get("target_height", 0.0))
	if target_h > 0.05:
		AssetStandardizer.fit_to_height(root, target_h, scale_mul)
	else:
		var s := float(def.get("scale", 1.0)) * scale_mul
		root.scale = Vector3(s, s, s)
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
	push_warning("ExternalPropKit: not a PackedScene %s (%s)" % [path, res])
	return null


static func _add_proxy_collision(root: Node3D, prop_id: String) -> void:
	## Tight proxy collision matched to visual footprint — leave walk space in rooms.
	## World-meter sizes, counter-scaled by root.scale so local shape stays correct.
	var body := StaticBody3D.new()
	body.name = "ProxyCollision"
	root.add_child(body)
	var shape := CollisionShape3D.new()
	var sid := String(prop_id)
	var inv := 1.0 / maxf(root.scale.x, 0.01)
	if sid.begins_with("tree_"):
		var cap := CapsuleShape3D.new()
		cap.radius = 0.32 * inv
		cap.height = 3.0 * inv
		shape.shape = cap
		shape.position = Vector3(0, cap.height * 0.5, 0)
	elif sid.begins_with("craft_") or sid in ["park_car", "adventure_suv"]:
		var box_v := BoxShape3D.new()
		box_v.size = Vector3(1.9, 1.15, 3.6) * inv
		shape.shape = box_v
		shape.position = Vector3(0, 0.58 * inv, 0)
	else:
		var dims := _furniture_collision_dims(sid)
		var box := BoxShape3D.new()
		## 10% XZ shrink so players can squeeze past without clipping the mesh badly.
		box.size = Vector3(dims.x * 0.9, dims.y, dims.z * 0.9) * inv
		shape.shape = box
		shape.position = Vector3(0, dims.y * 0.5 * inv, 0)
	body.add_child(shape)


static func _furniture_collision_dims(sid: String) -> Vector3:
	match sid:
		"bench":
			return Vector3(1.15, 0.5, 0.45)
		"sofa":
			return Vector3(1.7, 0.7, 0.7)
		"bed":
			return Vector3(1.8, 0.55, 1.15)
		"desk":
			return Vector3(1.2, 0.75, 0.6)
		"coffee_table":
			return Vector3(0.85, 0.35, 0.5)
		"chair":
			return Vector3(0.42, 0.85, 0.42)
		"bookcase":
			return Vector3(0.9, 1.85, 0.35)
		"fridge":
			return Vector3(0.65, 1.7, 0.6)
		"stove":
			return Vector3(0.65, 0.9, 0.55)
		"sink":
			return Vector3(0.55, 0.85, 0.45)
		"toilet":
			return Vector3(0.4, 0.7, 0.55)
		"market_stall":
			return Vector3(1.8, 2.0, 1.2)
		"cart":
			return Vector3(1.1, 1.1, 1.6)
		"fountain":
			return Vector3(1.15, 1.2, 1.15)
		"tent":
			return Vector3(2.0, 1.4, 2.0)
		"fence", "fence_gate":
			return Vector3(1.6, 1.0, 0.18)
		"treasure_chest", "supply_crate", "supply_crate_item", "barrel":
			return Vector3(0.85, 0.8, 0.85)
		"hangar_small":
			return Vector3(4.5, 2.6, 4.5)
		"log", "rock_large", "rock_tall":
			return Vector3(0.9, 0.7, 0.7)
		_:
			return Vector3(0.5, 0.7, 0.5)


static func _mark_all_meshes_occludable(node: Node) -> void:
	if node is MeshInstance3D:
		OcclusionUtil.mark(node as MeshInstance3D)
	for child in node.get_children():
		_mark_all_meshes_occludable(child)
