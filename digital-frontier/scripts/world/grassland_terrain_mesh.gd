class_name GrasslandTerrainMesh
extends RefCounted
## Builds true 3D heightfield visual + HeightMapShape3D collision for the Grassland.
## Chunked so handheld stays under the adventure node budget while the world remains
## a continuous elevation field for future flight / free camera.


const CELL := 72.0 ## Vertex spacing (meters) — readable hills from ortho + aerial
const CHUNK_CELLS := 48 ## ~3456m per chunk edge


static func build(root: Node3D) -> void:
	var terrain := Node3D.new()
	terrain.name = "GrasslandTerrain"
	root.add_child(terrain)
	var mn := GrasslandLayout.REGION_MIN
	var mx := GrasslandLayout.REGION_MAX
	## Expand slightly so coast edges don't drop into void.
	var min_x := mn.x - 100.0
	var max_x := mx.x + 100.0
	var min_z := mn.z - 100.0
	var max_z := mx.z + 100.0
	var chunk_i := 0
	var x := min_x
	while x < max_x:
		var z := min_z
		while z < max_z:
			var end_x := mini(x + float(CHUNK_CELLS) * CELL, max_x)
			var end_z := mini(z + float(CHUNK_CELLS) * CELL, max_z)
			_build_chunk(terrain, chunk_i, x, z, end_x, end_z)
			chunk_i += 1
			z = end_z
		x = end_x if end_x > x else x + float(CHUNK_CELLS) * CELL
	_build_color_overlays(terrain)
	_build_river_water(terrain)
	_build_scenic_lakes(terrain)


static func _build_chunk(parent: Node3D, idx: int, min_x: float, min_z: float, max_x: float, max_z: float) -> void:
	var nx := maxi(int(ceil((max_x - min_x) / CELL)) + 1, 2)
	var nz := maxi(int(ceil((max_z - min_z) / CELL)) + 1, 2)
	var width_m := float(nx - 1) * CELL
	var depth_m := float(nz - 1) * CELL
	var origin_x := min_x
	var origin_z := min_z
	var center := Vector3(origin_x + width_m * 0.5, 0.0, origin_z + depth_m * 0.5)

	var heights := PackedFloat32Array()
	heights.resize(nx * nz)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := _terrain_material()

	for iz in nz:
		for ix in nx:
			var wx := origin_x + float(ix) * CELL
			var wz := origin_z + float(iz) * CELL
			var h := GrasslandHeightField.height_at(wx, wz)
			heights[iz * nx + ix] = h

	## Build indexed grid with height-tinted vertices.
	for iz in nz - 1:
		for ix in nx - 1:
			var i00 := iz * nx + ix
			var i10 := iz * nx + ix + 1
			var i01 := (iz + 1) * nx + ix
			var i11 := (iz + 1) * nx + ix + 1
			_add_tri(st, origin_x, origin_z, nx, heights, i00, i10, i11)
			_add_tri(st, origin_x, origin_z, nx, heights, i00, i11, i01)

	st.generate_normals()
	var mesh := st.commit()
	var body := StaticBody3D.new()
	body.name = "TerrainChunk_%d" % idx
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	parent.add_child(body)

	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	## Mesh was authored in world XZ with Y=height; shift into chunk-local space.
	mi.position = -center
	mi.material_override = mat
	mi.visibility_range_end = 9000.0
	body.add_child(mi)

	var col := CollisionShape3D.new()
	col.name = "Collision"
	var shape := HeightMapShape3D.new()
	shape.map_width = nx
	shape.map_depth = nz
	shape.map_data = heights
	col.shape = shape
	## HeightMapShape is centered on the CollisionShape3D; map spans map_width-1 / map_depth-1 units
	## in Godot — scale so one map unit = CELL meters.
	col.scale = Vector3(CELL, 1.0, CELL)
	body.add_child(col)


static func _add_tri(
	st: SurfaceTool,
	origin_x: float,
	origin_z: float,
	nx: int,
	heights: PackedFloat32Array,
	ia: int,
	ib: int,
	ic: int,
) -> void:
	_add_vert(st, origin_x, origin_z, nx, heights, ia)
	_add_vert(st, origin_x, origin_z, nx, heights, ib)
	_add_vert(st, origin_x, origin_z, nx, heights, ic)


static func _add_vert(
	st: SurfaceTool,
	origin_x: float,
	origin_z: float,
	nx: int,
	heights: PackedFloat32Array,
	index: int,
) -> void:
	var ix := index % nx
	var iz := int(index / nx)
	var wx := origin_x + float(ix) * CELL
	var wz := origin_z + float(iz) * CELL
	var h: float = heights[index]
	st.set_color(_color_for_height(h))
	st.set_uv(Vector2(wx * 0.02, wz * 0.02))
	st.add_vertex(Vector3(wx, h, wz))


static func _color_for_height(h: float) -> Color:
	if h < -0.6:
		return WorldPalette.DIRT.darkened(0.08)
	if h < 1.5:
		return WorldPalette.GRASS
	if h < 5.0:
		return WorldPalette.GRASS.lerp(WorldPalette.GRASS_DARK, clampf((h - 1.5) / 3.5, 0.0, 1.0))
	if h < 14.0:
		return WorldPalette.GRASS_DARK.lerp(WorldPalette.ROCK, clampf((h - 5.0) / 9.0, 0.0, 1.0))
	if h < 24.0:
		return WorldPalette.ROCK.lerp(WorldPalette.ROCK.lightened(0.12), clampf((h - 14.0) / 10.0, 0.0, 1.0))
	return Color(0.82, 0.84, 0.88) ## High cap / snow hint for aerial silhouette


static func _terrain_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.albedo_color = Color.WHITE
	return mat


static func _build_color_overlays(parent: Node3D) -> void:
	## Cheap scenic tint patches snapped to height — read as meadow / dirt from altitude.
	var patches := [
		[Vector3(600, 0, 800), Vector3(180, 0.06, 140), WorldPalette.GRASS_LIGHT],
		[Vector3(400, 0, 2800), Vector3(200, 0.06, 160), WorldPalette.GRASS_DARK],
		[Vector3(1600, 0, -1400), Vector3(160, 0.06, 180), WorldPalette.LEAF_LIT],
		[Vector3(200, 0, 3600), Vector3(220, 0.06, 150), WorldPalette.SAND.darkened(0.15)],
		[Vector3(900, 0, 1500), Vector3(90, 0.05, 70), WorldPalette.DIRT.lightened(0.05)],
		[Vector3(1400, 0, -800), Vector3(70, 0.05, 90), WorldPalette.PATH],
		[Vector3(-600, 0, 400), Vector3(120, 0.05, 100), WorldPalette.GRASS_DARK],
		[Vector3(2500, 0, 2500), Vector3(150, 0.05, 120), WorldPalette.GRASS_LIGHT],
	]
	for i in patches.size():
		var p: Array = patches[i]
		var pos: Vector3 = GrasslandHeightField.snap_y(p[0], 0.04)
		StylizedMesh.add_box(parent, p[1], p[2], pos, "CountryPatch_%d" % i, false, 1.0, &"grass")


static func _build_river_water(parent: Node3D) -> void:
	## Continuous shallow water ribbon along the Mere corridor (true 3D planes on the dip).
	var river := Node3D.new()
	river.name = "RiverRibbon"
	parent.add_child(river)
	var path: Array[Vector3] = [
		Vector3(200, 0, -80),
		Vector3(280, 0, -180),
		GrasslandLayout.LANDMARK_STREAM_CROSSING,
		GrasslandLayout.LANDMARK_CREEK_BRIDGE,
		Vector3(1100, 0, -1100),
		Vector3(1280, 0, -1280),
	]
	for i in range(1, path.size()):
		## Skip segments that already have authored water set pieces.
		var mid := path[i - 1].lerp(path[i], 0.5)
		if mid.distance_to(GrasslandLayout.LANDMARK_STREAM_CROSSING) < 35.0:
			continue
		if mid.distance_to(GrasslandLayout.LANDMARK_CREEK_BRIDGE) < 35.0:
			continue
		var a := path[i - 1]
		var b := path[i]
		var dir := b - a
		var length := Vector3(dir.x, 0, dir.z).length()
		if length < 8.0:
			continue
		var yaw := atan2(dir.x, dir.z)
		var pos := GrasslandHeightField.snap_y(mid, 0.05)
		var water := MeshInstance3D.new()
		water.name = "RiverSeg_%d" % i
		var wm := BoxMesh.new()
		wm.size = Vector3(14.0, 0.08, length * 0.92)
		water.mesh = wm
		water.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
		water.position = pos
		water.rotation.y = yaw
		river.add_child(water)
		RegionPropKit.attach_living_water(water, Vector3(12.0, 0.06, length * 0.85))
		## Bank rocks — real 3D clutter along the channel.
		var perp := Vector3(-dir.z, 0.0, dir.x).normalized()
		if perp.length_squared() < 0.01:
			perp = Vector3(1, 0, 0)
		for s in [-1.0, 1.0]:
			var rock_p := GrasslandHeightField.snap_y(mid + perp * (8.0 * s), 0.15)
			StylizedMesh.add_box(river, Vector3(0.7, 0.4, 0.55), WorldPalette.ROCK, rock_p, "BankRock_%d_%d" % [i, int(s)], false, 1.0, &"dirt")


static func _build_scenic_lakes(parent: Node3D) -> void:
	## Minor wilderness ponds (off-map discoveries live in RegionDiscoveryBuilder).
	var lakes := [
		{"pos": Vector3(450, 0, 600), "r": 9.0, "name": "Pond_A"},
		{"pos": Vector3(-320, 0, -600), "r": 7.5, "name": "Pond_B"},
		{"pos": Vector3(1500, 0, 400), "r": 8.0, "name": "Pond_C"},
		{"pos": Vector3(800, 0, 2000), "r": 10.0, "name": "Pond_D"},
		{"pos": Vector3(-900, 0, 400), "r": 6.5, "name": "Pond_E"},
	]
	var root := Node3D.new()
	root.name = "ScenicPonds"
	parent.add_child(root)
	for i in lakes.size():
		var spec: Dictionary = lakes[i]
		var c: Vector3 = GrasslandHeightField.snap_y(spec["pos"], 0.02)
		var r: float = float(spec["r"])
		var bed := StylizedMesh.add_box(root, Vector3(r * 2.2, 0.12, r * 1.8), WorldPalette.DIRT.darkened(0.1), c + Vector3(0, -0.08, 0), String(spec["name"]) + "_Bed", false, 1.0, &"dirt")
		var water := MeshInstance3D.new()
		water.name = String(spec["name"]) + "_Water"
		var wm := BoxMesh.new()
		wm.size = Vector3(r * 2.0, 0.07, r * 1.6)
		water.mesh = wm
		water.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
		water.position = c + Vector3(0, 0.04, 0)
		root.add_child(water)
		RegionPropKit.attach_living_water(water, Vector3(r * 1.8, 0.05, r * 1.4))
		## Reed / rock fringe
		for j in 4:
			var ang := float(j) * TAU / 4.0 + float(i)
			var rp := GrasslandHeightField.snap_y(c + Vector3(cos(ang) * r * 1.15, 0, sin(ang) * r * 0.95), 0.2)
			StylizedMesh.add_box(root, Vector3(0.45, 0.35, 0.4), WorldPalette.ROCK, rp, "PondRock_%d_%d" % [i, j], false, 1.0, &"dirt")
		if bed:
			pass
