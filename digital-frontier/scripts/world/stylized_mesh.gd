class_name StylizedMesh
extends RefCounted
## Shared helpers for stylized low-poly 2.5D world props.
## Materials are cached by key for handheld performance (fewer unique shaders).

static var _mat_cache: Dictionary = {}  ## String -> StandardMaterial3D


static func make_material(
	color: Color,
	rough: float = 0.78,
	metallic: float = 0.0,
	emission_energy: float = 0.0,
) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f_%.2f" % [color.to_html(false), rough, metallic, emission_energy]
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metallic
	## Soft specular response — less chalky than default flat unshaded look.
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if emission_energy > 0.001:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	_mat_cache[key] = mat
	return mat


static func make_transparent_material(color: Color, rough: float = 0.55) -> StandardMaterial3D:
	## Unique per color (roofs fade via modulate) — do not cache shared instances.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = 0.05
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


static func make_glass_material(tint: Color = Color(0.55, 0.78, 0.95, 0.72)) -> StandardMaterial3D:
	var key := "glass_%s" % tint.to_html(true)
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.12
	mat.metallic = 0.35
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.65, 0.85, 1.0)
	mat.emission_energy_multiplier = 0.15
	_mat_cache[key] = mat
	return mat


static func make_asphalt_material(color: Color = Color(0.28, 0.28, 0.31)) -> StandardMaterial3D:
	return make_material(color, 0.92, 0.0)


static func make_grass_material(color: Color) -> StandardMaterial3D:
	return make_material(color, 0.88, 0.0)


static func make_wood_material(color: Color) -> StandardMaterial3D:
	return make_material(color, 0.72, 0.0)


static func make_metal_material(color: Color) -> StandardMaterial3D:
	return make_material(color, 0.35, 0.65)


static func add_box(
	parent: Node3D,
	size: Vector3,
	color: Color,
	pos: Vector3,
	node_name: String = "Box",
	with_collision: bool = false,
	rough: float = 0.78,
) -> Node3D:
	if with_collision:
		return _static_box(parent, size, color, pos, node_name, rough)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_material(color, rough)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func add_cylinder(
	parent: Node3D,
	radius: float,
	height: float,
	color: Color,
	pos: Vector3,
	node_name: String = "Cyl",
	with_collision: bool = false,
	segments: int = 16,
	rough: float = 0.78,
) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mi.mesh = mesh
	mi.material_override = make_material(color, rough)
	mi.position = pos
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name
		body.collision_layer = 1
		body.position = pos
		mi.position = Vector3.ZERO
		body.add_child(mi)
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		col.shape = shape
		body.add_child(col)
		parent.add_child(body)
		return body
	parent.add_child(mi)
	return mi


static func add_sphere(
	parent: Node3D,
	radius: float,
	color: Color,
	pos: Vector3,
	node_name: String = "Sphere",
	segments: int = 14,
	rings: int = 10,
	rough: float = 0.78,
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	mi.mesh = mesh
	mi.material_override = make_material(color, rough)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func add_window_pane(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	node_name: String = "Window",
	frame_color: Color = Color(0.85, 0.85, 0.82),
) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	parent.add_child(root)
	## Frame
	add_box(root, size + Vector3(0.12, 0.12, 0.02), frame_color, Vector3.ZERO, "Frame", false, 0.65)
	## Glass
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var mesh := BoxMesh.new()
	mesh.size = size
	glass.mesh = mesh
	glass.material_override = make_glass_material()
	glass.position = Vector3(0, 0, 0.02)
	root.add_child(glass)
	## Mullion
	add_box(root, Vector3(0.04, size.y * 0.92, 0.03), frame_color.darkened(0.1), Vector3(0, 0, 0.03), "MullionV", false, 0.6)
	add_box(root, Vector3(size.x * 0.92, 0.04, 0.03), frame_color.darkened(0.1), Vector3(0, 0, 0.03), "MullionH", false, 0.6)
	return root


static func add_prism_roof(
	parent: Node3D,
	width: float,
	depth: float,
	height: float,
	color: Color,
	pos: Vector3,
	node_name: String = "Roof",
	transparent: bool = false,
) -> MeshInstance3D:
	var roof_root := Node3D.new()
	roof_root.name = node_name
	roof_root.position = pos
	parent.add_child(roof_root)
	var base_mi := MeshInstance3D.new()
	base_mi.name = "RoofBase"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(width, height * 0.35, depth)
	base_mi.mesh = base_mesh
	if transparent:
		base_mi.material_override = make_transparent_material(color, 0.62)
	else:
		base_mi.material_override = make_material(color, 0.7)
	roof_root.add_child(base_mi)
	add_box(
		roof_root,
		Vector3(width * 0.55, height * 0.55, depth * 0.55),
		color.darkened(0.08),
		Vector3(0.0, height * 0.35, 0.0),
		"RoofPeak",
		false,
		0.7,
	)
	## Eave overhang lip
	add_box(
		roof_root,
		Vector3(width * 1.05, 0.08, depth * 1.05),
		color.darkened(0.15),
		Vector3(0.0, -height * 0.12, 0.0),
		"Eave",
		false,
		0.75,
	)
	return base_mi


static func clear_material_cache() -> void:
	_mat_cache.clear()


static func _static_box(
	parent: Node3D,
	size: Vector3,
	color: Color,
	pos: Vector3,
	node_name: String,
	rough: float = 0.78,
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_material(color, rough)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body
