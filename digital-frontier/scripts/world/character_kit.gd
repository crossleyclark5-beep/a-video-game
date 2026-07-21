class_name CharacterKit
extends RefCounted
## Load curated character GLBs with DF toon + nearest filtering (textures kept).


static var _scene_cache: Dictionary = {}


static func is_available() -> bool:
	return ResourceLoader.exists(CharacterCatalog.character_path(&"hero_a"))


static func spawn(
	parent: Node3D,
	character_id: StringName,
	pos: Vector3 = Vector3.ZERO,
	yaw_deg: float = 0.0,
	scale_mul: float = 1.0,
	node_name: String = "",
) -> Node3D:
	var def := CharacterCatalog.character_def(character_id)
	if def.is_empty():
		return null
	var path := CharacterCatalog.character_path(character_id)
	var packed := _load_scene(path)
	if packed == null:
		return null
	var root := Node3D.new()
	root.name = node_name if node_name != "" else String(character_id)
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
	_toonify(inst)
	return root


static func attach_under(
	parent: Node3D,
	character_id: StringName,
	scale_mul: float = 1.0,
	node_name: String = "LibraryMesh",
) -> Node3D:
	return spawn(parent, character_id, Vector3.ZERO, 0.0, scale_mul, node_name)


static func _load_scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if _scene_cache.has(path):
		return _scene_cache[path] as PackedScene
	if not ResourceLoader.exists(path):
		push_warning("CharacterKit: missing %s" % path)
		return null
	var res := load(path)
	if res is PackedScene:
		_scene_cache[path] = res
		return res as PackedScene
	push_warning("CharacterKit: not a PackedScene %s" % path)
	return null


static func _toonify(node: Node) -> void:
	## Characters stay higher-detail than the world: keep albedo textures, force toon + nearest.
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var src: Material = null
		if mi.get_surface_override_material_count() > 0:
			src = mi.get_active_material(0)
		if src == null and mi.mesh and mi.mesh.get_surface_count() > 0:
			src = mi.mesh.surface_get_material(0)
		var mat := StandardMaterial3D.new()
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		if src is BaseMaterial3D:
			var b := src as BaseMaterial3D
			mat.albedo_color = b.albedo_color
			if b.albedo_texture:
				mat.albedo_texture = b.albedo_texture
		elif src is StandardMaterial3D:
			var s := src as StandardMaterial3D
			mat.albedo_color = s.albedo_color
			if s.albedo_texture:
				mat.albedo_texture = s.albedo_texture
		mi.material_override = mat
	for child in node.get_children():
		_toonify(child)
