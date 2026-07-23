class_name StylizedMesh
extends RefCounted
## High-resolution modern pixel-art 2.5D mesh helpers.
## Nearest textures, toon diffuse, denser procedural patterns — handheld-friendly.
##
## Why older builds looked too chunky:
##   16×16 patterns + UV scale 2 on BoxMesh faces meant a 110-unit lawn had
##   ~3.4-unit texels. Triplanar world tiling + 64×64 patterns target ~0.1u pixels.

const PATTERN_SIZE := 64

## World units covered by one texture tile (triplanar). Smaller = denser pixels.
const TILE_GRASS := 7.0
const TILE_ASPHALT := 5.5
const TILE_BRICK := 3.8
const TILE_WOOD := 4.5
const TILE_DIRT := 6.0
const TILE_WATER := 4.5
const TILE_LEAF := 2.8
const TILE_ROOF := 3.6
const TILE_PATH := 5.0

static var _mat_cache: Dictionary = {}  ## String -> StandardMaterial3D
static var _tex_cache: Dictionary = {}  ## String -> Texture2D


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
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.shadow_to_opacity = false
	if pattern != &"flat":
		mat.albedo_texture = _pattern_texture(pattern, q)
		_apply_triplanar(mat, _tile_for(pattern))
	if emission_energy > 0.001:
		mat.emission_enabled = true
		mat.emission = q
		mat.emission_energy_multiplier = minf(emission_energy, 0.55)
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
	## Flat window pane — not shiny AAA glass. Tiny emission reads as sky reflection.
	var key := "win_%s" % tint.to_html(true)
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	var q := WorldPalette.quantize(tint)
	mat.albedo_color = q
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.emission_enabled = true
	mat.emission = q.lightened(0.15)
	mat.emission_energy_multiplier = 0.12
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
	var q := WorldPalette.quantize(color)
	var key := "water_anim_%s" % q.to_html(true)
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := make_transparent_material(q)
	mat.albedo_texture = _water_animated_texture(q)
	_apply_triplanar(mat, TILE_WATER)
	mat.emission_enabled = true
	mat.emission = q.lightened(0.2)
	mat.emission_energy_multiplier = 0.08
	_mat_cache[key] = mat
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


## Visual deck at authored Y; collision is a thin flush slab so road↔grass has no lip.
## Prefer this for asphalt / lawn / sidewalks that sit on GrasslandTerrain heightfield.
static func add_walkable_box(
	parent: Node3D,
	size: Vector3,
	color: Color,
	pos: Vector3,
	node_name: String = "Walk",
	rough: float = 1.0,
	pattern: StringName = &"flat",
	walk_y: float = 0.02,
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(pos.x, walk_y, pos.z)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_material(color, rough, 0.0, 0.0, pattern)
	## Keep the painted surface at the designer height while physics sits on the ground plane.
	mi.position = Vector3(0.0, pos.y - walk_y, 0.0)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.04, size.z)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


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
	## Framed pixel window: sill + mullion + glass.
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	parent.add_child(root)
	var frame_c := WorldPalette.WOOD.darkened(0.1)
	var thick := 0.06
	add_box(root, Vector3(size.x + thick * 2.0, size.y + thick * 2.0, size.z * 0.7), frame_c, Vector3(0, 0, -0.02), "Frame", false, 1.0, &"wood")
	add_box(root, Vector3(size.x * 0.06, size.y * 0.92, size.z * 0.5), frame_c.lightened(0.08), Vector3(0, 0, 0.01), "MullionV")
	add_box(root, Vector3(size.x * 0.92, size.y * 0.06, size.z * 0.5), frame_c.lightened(0.08), Vector3(0, 0, 0.01), "MullionH")
	add_box(root, Vector3(size.x + thick * 2.2, thick * 1.4, size.z * 1.2), WorldPalette.SIDEWALK, Vector3(0, -size.y * 0.5 - thick, 0.02), "Sill")
	var mi := MeshInstance3D.new()
	mi.name = "Glass"
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = make_glass_material(WorldPalette.WINDOW)
	mi.position = Vector3(0, 0, 0.04)
	root.add_child(mi)
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


static func _apply_triplanar(mat: StandardMaterial3D, tile_world: float) -> void:
	## World-space tiling keeps pixel size stable on huge ground and tiny props alike.
	mat.uv1_triplanar = true
	mat.uv1_triplanar_sharpness = 4.0
	mat.uv1_scale = Vector3(tile_world, tile_world, tile_world)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST


static func _tile_for(pattern: StringName) -> float:
	match pattern:
		&"grass":
			return TILE_GRASS
		&"asphalt":
			return TILE_ASPHALT
		&"brick":
			return TILE_BRICK
		&"wood":
			return TILE_WOOD
		&"dirt":
			return TILE_DIRT
		&"water":
			return TILE_WATER
		&"leaf":
			return TILE_LEAF
		&"roof":
			return TILE_ROOF
		&"path":
			return TILE_PATH
		_:
			return TILE_GRASS


static func _water_animated_texture(base: Color) -> Texture2D:
	var key := "water_anim_tex_%s" % base.to_html(false)
	if _tex_cache.has(key):
		return _tex_cache[key] as Texture2D
	var anim := AnimatedTexture.new()
	anim.frames = 4
	anim.pause = false
	anim.one_shot = false
	for i in 4:
		anim.set_frame_texture(i, _pattern_texture(&"water", base, i))
		anim.set_frame_duration(i, 0.28)
	_tex_cache[key] = anim
	return anim


static func _pattern_texture(pattern: StringName, base: Color, frame: int = 0) -> ImageTexture:
	var key := "%s_%s_%d" % [String(pattern), base.to_html(false), frame]
	if _tex_cache.has(key):
		return _tex_cache[key] as ImageTexture
	var size := PATTERN_SIZE
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dark := base.darkened(0.16)
	var mid := base.darkened(0.06)
	var light := base.lightened(0.10)
	var bright := base.lightened(0.18)
	for y in size:
		for x in size:
			var c := base
			match pattern:
				&"grass":
					c = _px_grass(x, y, base, dark, mid, light, bright)
				&"asphalt":
					c = _px_asphalt(x, y, base, dark, light)
				&"brick":
					c = _px_brick(x, y, base, dark, mid, light)
				&"wood":
					c = _px_wood(x, y, base, dark, mid, light)
				&"water":
					c = _px_water(x, y, frame, base, dark, light, bright)
				&"dirt":
					c = _px_dirt(x, y, base, dark, mid, light)
				&"leaf":
					c = _px_leaf(x, y, base, dark, mid, light, bright)
				&"roof":
					c = _px_roof(x, y, base, dark, mid, light)
				&"path":
					c = _px_path(x, y, base, dark, mid, light)
				_:
					c = base
			img.set_pixel(x, y, WorldPalette.quantize(c, 6))
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


static func _px_grass(x: int, y: int, base: Color, dark: Color, mid: Color, light: Color, bright: Color) -> Color:
	var n := (x * 13 + y * 7) % 17
	var blade := ((x + y * 2) % 9) == 0 or ((x * 3 + y) % 11) == 2
	var tuft := ((x * 5 + y * 3) % 23) == 0
	var dirt_speck := ((x * 7 + y * 11) % 29) == 4
	if tuft:
		return bright
	if blade:
		return light if n > 8 else mid
	if dirt_speck:
		return dark
	if ((x + y) % 13) == 0:
		return mid
	return base


static func _px_asphalt(x: int, y: int, base: Color, dark: Color, light: Color) -> Color:
	var grit := ((x * 3 + y * 5) % 7) == 0
	var crack := (y % 16 == 7 and (x + y / 2) % 11 < 3) or (x % 20 == 3 and y % 9 < 2)
	if crack:
		return dark.darkened(0.1)
	if grit:
		return light if ((x + y) % 2) == 0 else dark
	if ((x + y * 2) % 15) == 0:
		return dark
	return base


static func _px_brick(x: int, y: int, base: Color, dark: Color, mid: Color, light: Color) -> Color:
	var row_h := 8
	var brick_w := 16
	var row := y / row_h
	var ox := (row % 2) * (brick_w / 2)
	var local_x := (x + ox) % brick_w
	var local_y := y % row_h
	if local_y == 0 or local_x == 0:
		return dark
	## Subtle per-brick tone + mortar speckles.
	var brick_id := (row * 31 + ((x + ox) / brick_w) * 17) % 5
	var tone := base
	if brick_id == 1:
		tone = mid
	elif brick_id == 2:
		tone = light
	elif brick_id == 3:
		tone = base.darkened(0.08)
	if ((x * 3 + y) % 13) == 0:
		tone = tone.darkened(0.05)
	return tone


static func _px_wood(x: int, y: int, base: Color, dark: Color, mid: Color, light: Color) -> Color:
	var plank := x / 10
	var seam := x % 10 == 0
	var grain := ((y + plank * 3) % 8) == 0
	var knot := ((x * 5 + y * 7) % 47) == 0
	if seam:
		return dark
	if knot:
		return dark.darkened(0.12)
	if grain:
		return light if (plank % 2) == 0 else mid
	if ((x + y) % 17) == 0:
		return mid
	return base if (plank % 3) != 0 else base.lightened(0.04)


static func _px_water(x: int, y: int, frame: int, base: Color, dark: Color, light: Color, bright: Color) -> Color:
	var ox := frame * 5
	var oy := frame * 3
	var wave := ((x + ox + (y + oy) * 2) % 10) < 2
	var ripple := ((x * 2 + y + ox) % 14) == 0
	var sparkle := ((x * 3 + y * 5 + frame * 7) % 19) == 0
	if sparkle:
		return bright
	if wave:
		return light
	if ripple:
		return dark
	if ((x + y + frame) % 11) == 0:
		return base.lightened(0.05)
	return base


static func _px_dirt(x: int, y: int, base: Color, dark: Color, mid: Color, light: Color) -> Color:
	var clod := ((x * 3 + y * 2) % 9) == 0
	var pebble := ((x * 7 + y * 5) % 21) == 0
	var crack := (x + y * 2) % 18 == 0
	if pebble:
		return dark.darkened(0.08)
	if clod:
		return mid
	if crack:
		return dark
	if ((x * 2 + y) % 12) == 0:
		return light
	return base


static func _px_leaf(x: int, y: int, base: Color, dark: Color, mid: Color, light: Color, bright: Color) -> Color:
	## Clustered leaf pixels — readable silhouette detail on canopy boxes.
	var cell := ((x / 4) + (y / 4) * 3) % 4
	var edge := (x % 4 == 0) or (y % 4 == 0)
	var vein := ((x + y) % 7) == 0
	if edge and cell == 0:
		return dark
	if vein:
		return mid
	if ((x * 5 + y * 3) % 11) == 0:
		return bright
	if cell == 1:
		return light
	if cell == 2:
		return mid
	return base


static func _px_roof(x: int, y: int, base: Color, dark: Color, mid: Color, light: Color) -> Color:
	## Horizontal shingle rows with slight stagger.
	var row_h := 6
	var shingle_w := 12
	var row := y / row_h
	var ox := (row % 2) * 6
	var lx := (x + ox) % shingle_w
	var ly := y % row_h
	if ly == 0 or lx == 0:
		return dark
	if ly == row_h - 1:
		return mid
	if ((x + y) % 9) == 0:
		return light
	return base if (row % 2) == 0 else base.darkened(0.04)


static func _px_path(x: int, y: int, base: Color, dark: Color, mid: Color, light: Color) -> Color:
	var stone := ((x / 8) + (y / 8) * 5) % 3
	var mortar := (x % 8 == 0) or (y % 8 == 0)
	if mortar:
		return dark
	if stone == 0:
		return light
	if stone == 1:
		return mid
	if ((x * 3 + y) % 10) == 0:
		return dark
	return base
