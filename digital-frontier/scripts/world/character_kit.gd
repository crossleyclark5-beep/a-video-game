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


static func attach_outfit(
	parent: Node3D,
	outfit_id: StringName,
	scale_mul: float = 1.0,
	node_name: String = "LibraryMesh",
) -> Node3D:
	## Prefer high-quality DF retro look-alikes; Kenney tint path is fallback only.
	if CharacterOutfitCatalog.has_outfit(outfit_id):
		var look := CharacterLookalikeKit.build(parent, outfit_id, scale_mul)
		if look:
			look.name = node_name
			return look
	var def := CharacterOutfitCatalog.outfit_def(outfit_id)
	var mesh_id: StringName = def.get("mesh", &"hero_a") as StringName
	var root := attach_under(parent, mesh_id, scale_mul, node_name)
	if root == null:
		return null
	var tint: Color = def.get("tint", Color.WHITE) as Color
	var accent: Color = def.get("accent", tint.lightened(0.2)) as Color
	apply_tint(root, tint)
	_attach_prop(root, def.get("prop", &"none") as StringName, accent)
	return root


static func apply_tint(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := mi.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mi.material_override = mat
		else:
			mat = mat.duplicate() as StandardMaterial3D
			mi.material_override = mat
		## Keep texture identity; multiply tint for outfit palette.
		mat.albedo_color = mat.albedo_color * tint
	for child in node.get_children():
		apply_tint(child, tint)


static func _attach_prop(root: Node3D, prop: StringName, accent: Color) -> void:
	if prop == &"" or prop == &"none" or root == null:
		return
	var mount := Node3D.new()
	mount.name = "OutfitProp"
	mount.position = Vector3(0, 1.55, 0)
	root.add_child(mount)
	match prop:
		&"crown":
			StylizedMesh.add_box(mount, Vector3(0.42, 0.12, 0.42), accent, Vector3(0, 0.08, 0), "Crown")
			StylizedMesh.add_box(mount, Vector3(0.1, 0.18, 0.1), accent.lightened(0.2), Vector3(0, 0.22, 0), "CrownTip")
		&"hat":
			StylizedMesh.add_box(mount, Vector3(0.55, 0.06, 0.55), accent, Vector3(0, 0.02, 0), "Brim")
			StylizedMesh.add_box(mount, Vector3(0.28, 0.18, 0.28), accent.darkened(0.1), Vector3(0, 0.14, 0), "Crown")
		&"cap":
			StylizedMesh.add_box(mount, Vector3(0.34, 0.1, 0.34), accent, Vector3(0, 0.04, 0), "Cap")
			StylizedMesh.add_box(mount, Vector3(0.22, 0.04, 0.28), accent.darkened(0.15), Vector3(0, 0.0, 0.18), "Bill")
		&"orb":
			StylizedMesh.add_box(mount, Vector3(0.22, 0.22, 0.22), accent, Vector3(0.28, -0.55, 0.2), "Orb")
		&"armor":
			StylizedMesh.add_box(mount, Vector3(0.5, 0.35, 0.28), accent, Vector3(0, -0.55, 0.05), "Plate")
		&"peel":
			StylizedMesh.add_box(mount, Vector3(0.18, 0.35, 0.18), accent, Vector3(0, 0.12, 0), "PeelTop")
		&"soft":
			StylizedMesh.add_box(mount, Vector3(0.4, 0.28, 0.4), accent, Vector3(0, 0.05, 0), "Puff")
		&"helm":
			StylizedMesh.add_box(mount, Vector3(0.38, 0.28, 0.42), accent, Vector3(0, 0.05, 0), "Helm")
			StylizedMesh.add_box(mount, Vector3(0.28, 0.08, 0.12), Color(0.1, 0.1, 0.12), Vector3(0, 0.02, 0.18), "Visor")
		&"headset":
			StylizedMesh.add_box(mount, Vector3(0.48, 0.08, 0.08), accent, Vector3(0, 0.0, 0), "Band")
			StylizedMesh.add_box(mount, Vector3(0.1, 0.14, 0.1), accent.lightened(0.15), Vector3(0.22, -0.02, 0), "CupL")
			StylizedMesh.add_box(mount, Vector3(0.1, 0.14, 0.1), accent.lightened(0.15), Vector3(-0.22, -0.02, 0), "CupR")
		&"visor":
			StylizedMesh.add_box(mount, Vector3(0.36, 0.12, 0.2), accent, Vector3(0, 0.0, 0.12), "Visor")
		&"mask":
			StylizedMesh.add_box(mount, Vector3(0.32, 0.16, 0.22), accent, Vector3(0, -0.02, 0.12), "Mask")
		_:
			pass


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
