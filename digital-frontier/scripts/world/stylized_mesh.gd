class_name StylizedMesh
extends RefCounted
## Pixel-art inspired 2.5D mesh helpers.
## Flat materials, nearest textures, low segment counts — handheld-friendly.

static var _mat_cache: Dictionary = {}  ## String -> StandardMaterial3D
static var _tex_cache: Dictionary = {}  ## String -> ImageTexture


static func make_material(
	color: Color,
	rough: float = 1.0,
	metallic: float = 0.0,
	emission_energy: float = 0.0,
	pattern: StringName = &"flat",
) -> StandardMaterial3D:
	var q := WorldPalette.quantize(color)
	var key := "%s_%s_%.2f_%.2f_%.2f" % [String(pattern), q.to_html(true), rough, metallic, emission_energy]
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = q
	mat.roughness = 1.0  ## No soft plastic specular.
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	## Subtle vertex-ish read without expensive custom shaders.
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.shadow_to_opacity = false
	if pattern != &"flat":
		mat.albedo_texture = _pattern_texture(pattern, q)
		mat.uv1_scale = Vector3(2.0, 2.0, 2.0)
	if emission_energy > 0.001:
		mat.emission_enabled = true
		mat.emission = q
		mat.emission_energy_multiplier = minf(emission_energy, 0.45)
	_mat_cache[key] = mat
	return mat


static func make_transparent_material(color: Color, _rough: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WorldPalette.quantize(color)
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return mat


static func make_glass_material(tint: Color = Color(0.35, 0.55, 0.72, 0.85)) -> StandardMaterial3D:
	## Flat window pane — not shiny AAA glass.
	var key := "win_%s" % tint.to_html(true)
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WorldPalette.quantize(tint)
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	_mat_cache[key] = mat
	return mat


static func make_asphalt_material(color: Color = WorldPalette.ROAD) -> StandardMaterial3D:
	return make_material(color, 1.0, 0.0, 0.0, &"asphalt")


static func make_grass_material(color: Color = WorldPalette.GRASS) -> StandardMaterial3D:
	return make_material(color, 1.0, 0.0, 0.0, &"grass")


static func make_wood_material(color: Color = WorldPalette.WOOD) -> StandardMaterial3D:
	return make_material(color, 1.0, 0.0, 0.0, &"wood")


static func make_metal_material(color: Color = WorldPalette.METAL) -> StandardMaterial3D:
	return make_material(color, 1.0, 0.0, 0.0, &"brick")


static func make_brick_material(color: Color = WorldPalette.BRICK) -> StandardMaterial3D:
	return make_material(color, 1.0, 0.0, 0.0, &"brick")


static func make_water_material(color: Color = WorldPalette.WATER) -> StandardMaterial3D:
	var mat := make_transparent_material(color)
	mat.albedo_texture = _pattern_texture(&"water", WorldPalette.quantize(color))
	mat.uv1_scale = Vector3(3.0, 3.0, 3.0)
	return mat


static func add_box(
	parent: Node3D,
	size: Vector3,
	color: Color,
	pos: Vector3,
	node_name: String = "Box",
	with_collision: bool = false,
	rough: float = 1.0,
	pattern: StringName = &"flat",
) -> Node3D:
	if with_collision:
		return _static_box(parent, size, color, pos, node_name, rough, pattern)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_material(color, rough, 0.0, 0.0, pattern)
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
	segments: int = 8,
	rough: float = 1.0,
) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = mini(segments, 8)
	mi.mesh = mesh
	mi.material_override = make_material(color, rough)
	mi.position = pos
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name
		body.collision_layer = 1
		body.position = pos
		mi.position = Vector3.ZERO
		mi.name = "Mesh"
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
	segments: int = 8,
	rings: int = 5,
	rough: float = 1.0,
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = mini(segments, 8)
	mesh.rings = mini(rings, 5)
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
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_glass_material(WorldPalette.WINDOW)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _static_box(
	parent: Node3D,
	size: Vector3,
	color: Color,
	pos: Vector3,
	node_name: String,
	rough: float = 1.0,
	pattern: StringName = &"flat",
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
	mi.material_override = make_material(color, rough, 0.0, 0.0, pattern)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func _pattern_texture(pattern: StringName, base: Color) -> ImageTexture:
	var key := "%s_%s" % [String(pattern), base.to_html(false)]
	if _tex_cache.has(key):
		return _tex_cache[key] as ImageTexture
	var size := 16
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dark := base.darkened(0.18)
	var light := base.lightened(0.12)
	for y in size:
		for x in size:
			var c := base
			match pattern:
				&"grass":
					if ((x + y * 3) % 5) == 0:
						c = light
					elif ((x * 2 + y) % 7) == 0:
						c = dark
				&"asphalt":
					if ((x + y) % 4) == 0:
						c = dark
					elif (x % 5) == 2:
						c = light
				&"brick":
					var row := y / 4
					var ox := (row % 2) * 4
					if y % 4 == 0 or ((x + ox) % 8) == 0:
						c = dark
					else:
						c = base if ((x + y) % 3) != 0 else light
				&"wood":
					if x % 4 == 0:
						c = dark
					elif (y + x / 2) % 6 == 0:
						c = light
				&"water":
					if ((x + y * 2) % 6) < 2:
						c = light
					elif ((x * 3 + y) % 8) == 0:
						c = dark
				&"dirt":
					if ((x * 3 + y * 2) % 5) == 0:
						c = dark
					elif ((x + y) % 6) == 0:
						c = light
				_:
					c = base
			img.set_pixel(x, y, WorldPalette.quantize(c, 5))
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex
