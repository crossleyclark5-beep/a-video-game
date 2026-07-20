class_name StylizedMesh
extends RefCounted
## Shared helpers for stylized low-poly 2.5D world props.
## Keeps materials consistent and handheld-friendly (simple lit colors, no heavy shaders).

static func make_material(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = 0.0
	return mat


static func make_transparent_material(color: Color) -> StandardMaterial3D:
	var mat := make_material(color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


static func add_box(parent: Node3D, size: Vector3, color: Color, pos: Vector3, node_name: String = "Box", with_collision: bool = false) -> Node3D:
	if with_collision:
		return _static_box(parent, size, color, pos, node_name)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func add_cylinder(parent: Node3D, radius: float, height: float, color: Color, pos: Vector3, node_name: String = "Cyl", with_collision: bool = false) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mi.mesh = mesh
	mi.material_override = make_material(color)
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


static func add_sphere(parent: Node3D, radius: float, color: Color, pos: Vector3, node_name: String = "Sphere") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	mi.mesh = mesh
	mi.material_override = make_material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func add_prism_roof(parent: Node3D, width: float, depth: float, height: float, color: Color, pos: Vector3, node_name: String = "Roof") -> MeshInstance3D:
	## Approximate pitched roof with a flattened box + peak slab for readable 2.5D silhouette.
	var roof_root := Node3D.new()
	roof_root.name = node_name
	roof_root.position = pos
	parent.add_child(roof_root)
	var base := add_box(roof_root, Vector3(width, height * 0.35, depth), color, Vector3(0.0, 0.0, 0.0), "RoofBase") as MeshInstance3D
	add_box(roof_root, Vector3(width * 0.55, height * 0.55, depth * 0.55), color.darkened(0.08), Vector3(0.0, height * 0.35, 0.0), "RoofPeak")
	return base


static func _static_box(parent: Node3D, size: Vector3, color: Color, pos: Vector3, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_material(color)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body
