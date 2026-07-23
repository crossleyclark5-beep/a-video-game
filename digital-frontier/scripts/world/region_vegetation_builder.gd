class_name RegionVegetationBuilder
extends RefCounted
## Vegetation with placement rules — no grass on roads, no plants in building pads.
## Trees / bushes / rocks / mushrooms use MultiMesh for density without exploding the node budget.
## All wilderness props snap to GrasslandHeightField (true 3D ground).


static var _tree_mesh_cache: ArrayMesh
static var _pine_mesh_cache: ArrayMesh
static var _bush_mesh_cache: ArrayMesh
static var _rock_mesh_cache: ArrayMesh
static var _mushroom_mesh_cache: ArrayMesh


static func build(root: Node3D) -> void:
	var veg := Node3D.new()
	veg.name = "RegionVegetation"
	root.add_child(veg)
	_build_corridor_forests(veg)
	_build_dense_wilderness_forests(veg)
	_build_grass_strips(veg)
	_build_special_clearings(veg)
	_build_wilderness_fill(veg)
	_build_pine_ridges(veg)
	_build_biome_clutter(veg)


static func _build_corridor_forests(parent: Node3D) -> void:
	var forests := Node3D.new()
	forests.name = "ForestBelts"
	parent.add_child(forests)
	_forest_along(forests, GrasslandLayout.path_park_to_salty(), 1)
	_forest_along(forests, GrasslandLayout.path_park_to_reels(), 2)
	_forest_along(forests, GrasslandLayout.path_park_to_fields(), 3)
	_tree_line(forests, Vector3(-180, 0, -120), Vector3(-180, 0, 220), 22, 4)
	_tree_line(forests, Vector3(-40, 0, -1100), Vector3(200, 0, -1700), 18, 5)
	_forest_along(forests, GrasslandLayout.path_park_to_mere(), 4)
	_forest_along(forests, GrasslandLayout.path_park_to_mile(), 5)
	_forest_along(forests, GrasslandLayout.path_park_to_grove(), 6)


static func _forest_along(parent: Node3D, points: Array[Vector3], seed_base: int) -> void:
	var clear := GrasslandLayout.road_clearance() + 8.0
	var tree_xfs: Array[Transform3D] = []
	var bush_xfs: Array[Transform3D] = []
	var rock_xfs: Array[Transform3D] = []
	for i in range(1, points.size()):
		## Dense belts — MultiMesh absorbs instance cost.
		if i % 2 == 0 and seed_base % 2 == 0:
			pass ## still place, just vary pattern below
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		var mid := a.lerp(b, 0.5)
		var perp := _perp(a, b)
		_collect_tree_clump(tree_xfs, mid + perp * (clear + 14.0), 8 + (i % 4), seed_base * 17 + i)
		_collect_tree_clump(tree_xfs, mid - perp * (clear + 18.0), 7 + ((i + 1) % 4), seed_base * 31 + i)
		_collect_bush_cluster(bush_xfs, mid + perp * (clear + 8.0), 6, seed_base * 41 + i)
		_collect_bush_cluster(bush_xfs, mid - perp * (clear + 9.0), 5, seed_base * 43 + i)
		_collect_tree_clump(tree_xfs, mid + perp * (clear + 32.0), 6, seed_base * 13 + i * 3)
		_collect_tree_clump(tree_xfs, mid - perp * (clear + 36.0), 5, seed_base * 19 + i * 2)
		_collect_rocks(rock_xfs, mid - perp * (clear + 22.0), seed_base + i)
		if i % 2 == 1:
			_flower_scatter_safe(parent, mid + perp * (clear + 11.0), seed_base + i * 5)
		if i % 3 == 0:
			_clearing_safe(parent, mid + perp * (-(clear + 34.0)), seed_base + i)
			_fallen_log(parent, mid - perp * (clear + 16.0), seed_base + i * 7)
	_emit_tree_multimesh(parent, "CorridorTrees_%d" % seed_base, tree_xfs, false)
	_emit_bush_multimesh(parent, "CorridorBush_%d" % seed_base, bush_xfs)
	_emit_rock_multimesh(parent, "CorridorRock_%d" % seed_base, rock_xfs)


static func _build_dense_wilderness_forests(parent: Node3D) -> void:
	## Large MultiMesh forest patches — the density that makes wilderness feel alive.
	var forests := Node3D.new()
	forests.name = "DenseForests"
	parent.add_child(forests)
	var patches: Array[Dictionary] = [
		{"pos": Vector3(200, 0, 350), "r": 62.0, "n": 130, "pine": false},
		{"pos": Vector3(-250, 0, 280), "r": 55.0, "n": 115, "pine": false},
		{"pos": Vector3(450, 0, -250), "r": 68.0, "n": 140, "pine": false},
		{"pos": Vector3(900, 0, 200), "r": 78.0, "n": 155, "pine": false},
		{"pos": Vector3(300, 0, 1200), "r": 72.0, "n": 135, "pine": false},
		{"pos": Vector3(-100, 0, -900), "r": 65.0, "n": 125, "pine": true},
		{"pos": Vector3(1400, 0, -600), "r": 70.0, "n": 130, "pine": false},
		{"pos": Vector3(2000, 0, 800), "r": 62.0, "n": 115, "pine": false},
		{"pos": Vector3(-800, 0, 600), "r": 75.0, "n": 145, "pine": false},
		{"pos": Vector3(600, 0, -1600), "r": 80.0, "n": 150, "pine": true},
		{"pos": Vector3(2400, 0, 2400), "r": 58.0, "n": 100, "pine": false},
		{"pos": Vector3(-1500, 0, 1200), "r": 62.0, "n": 110, "pine": false},
		{"pos": Vector3(100, 0, -2800), "r": 55.0, "n": 95, "pine": true},
		{"pos": Vector3(1100, 0, 1600), "r": 65.0, "n": 120, "pine": false},
		{"pos": Vector3(-400, 0, -400), "r": 52.0, "n": 100, "pine": false},
		{"pos": Vector3(2800, 0, 1200), "r": 58.0, "n": 100, "pine": false},
		## Extra near-hub belts so leaving town never feels empty.
		{"pos": Vector3(80, 0, 160), "r": 38.0, "n": 70, "pine": false},
		{"pos": Vector3(-90, 0, 140), "r": 36.0, "n": 65, "pine": false},
		{"pos": Vector3(140, 0, -120), "r": 40.0, "n": 75, "pine": false},
		{"pos": Vector3(-130, 0, -100), "r": 38.0, "n": 70, "pine": true},
		{"pos": Vector3(320, 0, 520), "r": 48.0, "n": 90, "pine": false},
		{"pos": Vector3(-320, 0, -520), "r": 48.0, "n": 90, "pine": true},
		{"pos": Vector3(1600, 0, 1600), "r": 55.0, "n": 95, "pine": false},
		{"pos": Vector3(-900, 0, 1400), "r": 50.0, "n": 85, "pine": false},
	]
	for i in patches.size():
		var spec: Dictionary = patches[i]
		var center: Vector3 = spec["pos"]
		if not _placement_ok(center, true):
			continue
		var tree_xfs: Array[Transform3D] = []
		var bush_xfs: Array[Transform3D] = []
		var rock_xfs: Array[Transform3D] = []
		var mush_xfs: Array[Transform3D] = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(i) * 9181 + 17
		var n: int = int(spec["n"])
		var radius: float = float(spec["r"])
		var use_pine: bool = bool(spec["pine"])
		for j in n:
			var ang := rng.randf() * TAU
			var r := sqrt(rng.randf()) * radius
			## Soft density falloff toward edge; denser core reads as forest.
			if rng.randf() > 0.55 and r > radius * 0.55:
				continue
			var p := center + Vector3(cos(ang) * r, 0, sin(ang) * r)
			if not _placement_ok(p, true):
				continue
			var scale_v := 0.7 + rng.randf() * 0.55
			tree_xfs.append(_tree_xf(p, scale_v, rng.randf() * TAU))
		## Undergrowth ring — denser bushes / rocks / mushrooms for living forests.
		for j in int(n * 0.7):
			var ang := rng.randf() * TAU
			var r := sqrt(rng.randf()) * radius * 0.9
			var p := center + Vector3(cos(ang) * r, 0, sin(ang) * r)
			if not _placement_ok(p, false):
				continue
			bush_xfs.append(_bush_xf(p, 0.5 + rng.randf() * 0.4, rng.randf() * TAU))
		for j in 22:
			var ang := rng.randf() * TAU
			var p := center + Vector3(cos(ang) * rng.randf() * radius * 0.8, 0, sin(ang) * rng.randf() * radius * 0.8)
			if _placement_ok(p, false):
				rock_xfs.append(_rock_xf(p, 0.3 + rng.randf() * 0.35, rng.randf() * TAU))
		for j in 16:
			var ang := rng.randf() * TAU
			var p := center + Vector3(cos(ang) * rng.randf() * radius * 0.5, 0, sin(ang) * rng.randf() * radius * 0.5)
			if _placement_ok(p, false):
				mush_xfs.append(_mushroom_xf(p, 0.8 + rng.randf() * 0.5, rng.randf() * TAU))
		_grass_patch_safe(forests, center, radius * 0.75, 200, 2000 + i)
		_emit_tree_multimesh(forests, "Forest_%d" % i, tree_xfs, use_pine)
		_emit_bush_multimesh(forests, "ForestBush_%d" % i, bush_xfs)
		_emit_rock_multimesh(forests, "ForestRock_%d" % i, rock_xfs)
		_emit_mushroom_multimesh(forests, "ForestMush_%d" % i, mush_xfs)
		if i % 3 == 0:
			_fallen_log(forests, GrasslandHeightField.snap(center + Vector3(8, 0, -6)), 3000 + i)
			_leaf_litter(forests, center, 3100 + i)


static func _tree_line(parent: Node3D, a: Vector3, b: Vector3, count: int, seed_i: int) -> void:
	var xfs: Array[Transform3D] = []
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		var p := a.lerp(b, t)
		var side := _perp(a, b) * (6.0 if i % 2 == 0 else -5.0)
		var world := p + side
		if not _placement_ok(world, true):
			continue
		xfs.append(_tree_xf(world, 0.85 + float((i + seed_i) % 4) * 0.12, float(i + seed_i)))
	_emit_tree_multimesh(parent, "TreeLine_%d" % seed_i, xfs, false)


static func _tree_clump_safe(parent: Node3D, center: Vector3, count: int, seed_i: int) -> void:
	if not _placement_ok(center, true):
		return
	var xfs: Array[Transform3D] = []
	_collect_tree_clump(xfs, center, count, seed_i)
	_emit_tree_multimesh(parent, "Clump_%d" % seed_i, xfs, false)
	if seed_i % 4 == 0:
		_fallen_log(parent, center + Vector3(2.0, 0, -1.5), seed_i)
	if seed_i % 3 == 0:
		_leaf_litter(parent, center, seed_i)


static func _collect_tree_clump(out_xfs: Array[Transform3D], center: Vector3, count: int, seed_i: int) -> void:
	_collect_tree_clump_local(out_xfs, center, count, seed_i, Vector3.ZERO)


static func _collect_tree_clump_local(out_xfs: Array[Transform3D], center: Vector3, count: int, seed_i: int, parent_origin: Vector3) -> void:
	if not _placement_ok(parent_origin + center, true):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_i) * 7919 + 41
	var n := mini(count, 10)
	for j in n:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(0.8, 2.2 + float(j % 4) * 1.9)
		if j < n / 2:
			r *= 0.72
		var p := center + Vector3(cos(ang) * r + rng.randf_range(-0.6, 0.6), 0.0, sin(ang) * r + rng.randf_range(-0.6, 0.6))
		if not _placement_ok(parent_origin + p, true):
			continue
		out_xfs.append(_tree_xf(p, 0.72 + rng.randf() * 0.48, rng.randf() * TAU, parent_origin))
	if n >= 4:
		var sat := center + Vector3(rng.randf_range(6.0, 11.0) * (1.0 if seed_i % 2 == 0 else -1.0), 0, rng.randf_range(-4.0, 4.0))
		if _placement_ok(parent_origin + sat, true):
			out_xfs.append(_tree_xf(sat, 0.65 + rng.randf() * 0.2, rng.randf() * TAU, parent_origin))


static func _collect_bush_cluster(out_xfs: Array[Transform3D], center: Vector3, count: int, seed_i: int) -> void:
	_collect_bush_cluster_local(out_xfs, center, count, seed_i, Vector3.ZERO)


static func _collect_bush_cluster_local(out_xfs: Array[Transform3D], center: Vector3, count: int, seed_i: int, parent_origin: Vector3) -> void:
	if not _placement_ok(parent_origin + center, false):
		return
	for j in count:
		var ang := float(j) * 1.9 + float(seed_i) * 0.1
		var r := 1.2 + float(j % 3) * 0.9
		var p := center + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		if not _placement_ok(parent_origin + p, false):
			continue
		out_xfs.append(_bush_xf(p, 0.55 + float((j + seed_i) % 3) * 0.15, ang, parent_origin))


static func _collect_rocks(out_xfs: Array[Transform3D], center: Vector3, seed_i: int) -> void:
	_collect_rocks_local(out_xfs, center, seed_i, Vector3.ZERO)


static func _collect_rocks_local(out_xfs: Array[Transform3D], center: Vector3, seed_i: int, parent_origin: Vector3) -> void:
	if not _placement_ok(parent_origin + center, false):
		return
	for j in 5:
		var ang := float(j) * 1.5 + float(seed_i)
		var p := center + Vector3(cos(ang) * (1.0 + float(j)), 0.0, sin(ang) * (0.8 + float(j % 3)))
		if not _placement_ok(parent_origin + p, false):
			continue
		out_xfs.append(_rock_xf(p, 0.35 + float((j + seed_i) % 3) * 0.2, ang, parent_origin))


static func _clearing_safe(parent: Node3D, center: Vector3, seed_i: int) -> void:
	if not _placement_ok(center, true):
		return
	_clearing(parent, center, seed_i)


static func _clearing(parent: Node3D, center: Vector3, seed_i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_i) * 4523 + 7
	var parent_origin := parent.position
	var world_center := parent_origin + center
	var local_y := GrasslandHeightField.height_at_v(world_center) - parent_origin.y
	StylizedMesh.add_box(parent, Vector3(14, 0.04, 12), WorldPalette.GRASS_LIGHT, center + Vector3(0, local_y + 0.03, 0), "Clearing_%d" % seed_i, false, 1.0, &"grass")
	var xfs: Array[Transform3D] = []
	for j in 7:
		if j == (seed_i % 7):
			continue
		var ang := float(j) * TAU / 7.0 + rng.randf_range(-0.22, 0.22)
		var r := 8.2 + rng.randf_range(-1.2, 1.8)
		var local := center + Vector3(cos(ang) * r, 0, sin(ang) * r)
		if _placement_ok(parent_origin + local, true):
			xfs.append(_tree_xf(local, 0.82 + rng.randf() * 0.25, ang, parent_origin))
	_emit_tree_multimesh(parent, "ClearRing_%d" % seed_i, xfs, false)
	var rock_local := center + Vector3(1.5, 0, -1.0)
	var rock_y := GrasslandHeightField.height_at_v(parent_origin + rock_local) - parent_origin.y
	StylizedMesh.add_box(parent, Vector3(0.4, 0.22, 0.35), WorldPalette.ROCK, rock_local + Vector3(0, rock_y + 0.12, 0), "ClearRock", false, 1.0, &"dirt")
	_flower_scatter_local(parent, center + Vector3(-2.0, 0, 1.5), seed_i + 3)
	if seed_i % 2 == 0:
		_fallen_log_local(parent, center + Vector3(-3.5, 0, 2.0), seed_i + 11)


static func _fallen_log(parent: Node3D, pos: Vector3, seed_i: int) -> void:
	## `pos` is world XZ when parent sits at the region origin.
	if not _placement_ok(pos, false):
		return
	var log := Node3D.new()
	log.name = "FallenLog_%d" % seed_i
	log.position = GrasslandHeightField.snap(pos)
	log.rotation_degrees.y = float(seed_i * 37 % 360)
	parent.add_child(log)
	StylizedMesh.add_box(log, Vector3(2.2, 0.28, 0.32), WorldPalette.TRUNK.darkened(0.08), Vector3(0, 0.16, 0), "Log", false, 1.0, &"wood")
	StylizedMesh.add_box(log, Vector3(0.35, 0.12, 0.35), WorldPalette.LEAF_DARK, Vector3(0.6, 0.28, 0.05), "Moss", false, 1.0, &"leaf")


static func _fallen_log_local(parent: Node3D, local: Vector3, seed_i: int) -> void:
	var world := parent.position + local
	if not _placement_ok(world, false):
		return
	var log := Node3D.new()
	log.name = "FallenLog_%d" % seed_i
	var y := GrasslandHeightField.height_at_v(world) - parent.position.y
	log.position = Vector3(local.x, y, local.z)
	log.rotation_degrees.y = float(seed_i * 37 % 360)
	parent.add_child(log)
	StylizedMesh.add_box(log, Vector3(2.2, 0.28, 0.32), WorldPalette.TRUNK.darkened(0.08), Vector3(0, 0.16, 0), "Log", false, 1.0, &"wood")
	StylizedMesh.add_box(log, Vector3(0.35, 0.12, 0.35), WorldPalette.LEAF_DARK, Vector3(0.6, 0.28, 0.05), "Moss", false, 1.0, &"leaf")


static func _leaf_litter(parent: Node3D, center: Vector3, seed_i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_i) * 1301 + 3
	for i in 3:
		var p := center + Vector3(rng.randf_range(-3.5, 3.5), 0, rng.randf_range(-3.5, 3.5))
		if not _placement_ok(p, false):
			continue
		StylizedMesh.add_box(parent, Vector3(0.45 + rng.randf() * 0.3, 0.03, 0.35 + rng.randf() * 0.25), WorldPalette.LEAF_DARK.darkened(0.1), GrasslandHeightField.snap_y(p, 0.04), "Leaves_%d_%d" % [seed_i, i], false, 1.0, &"leaf")


static func _leaf_litter_local(parent: Node3D, center: Vector3, seed_i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_i) * 1301 + 3
	for i in 3:
		var local := center + Vector3(rng.randf_range(-3.5, 3.5), 0, rng.randf_range(-3.5, 3.5))
		var world := parent.position + local
		if not _placement_ok(world, false):
			continue
		var y := GrasslandHeightField.height_at_v(world) - parent.position.y
		StylizedMesh.add_box(parent, Vector3(0.45 + rng.randf() * 0.3, 0.03, 0.35 + rng.randf() * 0.25), WorldPalette.LEAF_DARK.darkened(0.1), local + Vector3(0, y + 0.04, 0), "Leaves_%d_%d" % [seed_i, i], false, 1.0, &"leaf")


static func _build_grass_strips(parent: Node3D) -> void:
	var grass_root := Node3D.new()
	grass_root.name = "GrassStrips"
	parent.add_child(grass_root)
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		var r: float = float(zone["radius"])
		_grass_patch_safe(grass_root, hub + Vector3(r * 0.85, 0, 0), 12.0, 120, int(hub.x) + 11)
		_grass_patch_safe(grass_root, hub + Vector3(-r * 0.7, 0, r * 0.55), 11.0, 110, int(hub.z) + 19)
		_grass_patch_safe(grass_root, hub + Vector3(r * 0.4, 0, -r * 0.75), 10.0, 100, int(hub.x + hub.z) + 3)
		_grass_patch_safe(grass_root, hub + Vector3(-r * 0.5, 0, -r * 0.5), 9.0, 90, int(hub.x) + 77)
	var clear := GrasslandLayout.road_clearance() + 4.0
	for path in RegionMapCatalog.road_polylines():
		for i in range(1, path.size()):
			var mid: Vector3 = path[i - 1].lerp(path[i], 0.5)
			var perp := _perp(path[i - 1], path[i])
			_grass_patch_safe(grass_root, mid + perp * clear, 12.0, 120, i * 7)
			_grass_patch_safe(grass_root, mid - perp * clear, 12.0, 110, i * 9 + 1)
			if i % 2 == 1:
				_flower_scatter_safe(grass_root, mid + perp * (clear + 4.0), i)
			if i % 3 == 1:
				_bush_cluster_safe(grass_root, mid + perp * (clear + 12.0), 3, i * 11)


static func _grass_patch_safe(parent: Node3D, center: Vector3, radius: float, count: int, seed_i: int) -> void:
	if not _placement_ok(center, false):
		return
	_grass_patch(parent, center, radius, count, seed_i)


static func _flower_scatter_safe(parent: Node3D, center: Vector3, seed_i: int) -> void:
	if not _placement_ok(center, false):
		return
	_flower_scatter(parent, center, seed_i)


static func _grass_patch(parent: Node3D, center: Vector3, radius: float, count: int, seed_i: int) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassMM_%d" % seed_i
	var ground_y := GrasslandHeightField.height_at_v(center)
	mmi.position = Vector3(center.x, ground_y, center.z)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var blade := BoxMesh.new()
	blade.size = Vector3(0.06, 0.35, 0.04)
	mm.mesh = blade
	var mat := StylizedMesh.make_material(WorldPalette.GRASS_LIGHT if seed_i % 2 == 0 else WorldPalette.LEAF, 1.0, 0.0, 0.0, &"leaf")
	mmi.material_override = mat
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_i) * 9973 + 17
	var transforms: Array[Transform3D] = []
	for i in count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var x := cos(a) * r
		var z := sin(a) * r
		var world := center + Vector3(x, 0.0, z)
		if not _placement_ok(world, false):
			continue
		var local_y := GrasslandHeightField.height_at(world.x, world.z) - ground_y
		var h := 0.22 + rng.randf() * 0.45
		var lean := rng.randf_range(-0.25, 0.25)
		var xf := Transform3D.IDENTITY
		xf = xf.scaled(Vector3(1.0, h / 0.35, 1.0))
		xf = xf.rotated(Vector3.UP, a)
		xf = xf.rotated(Vector3.RIGHT, lean)
		xf.origin = Vector3(x, local_y + h * 0.5, z)
		transforms.append(xf)
	if transforms.is_empty():
		return
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	mmi.multimesh = mm
	mmi.visibility_range_end = AdventureNodeBudget.LOD_GRASS_END
	mmi.visibility_range_end_margin = 40.0
	parent.add_child(mmi)


static func _flower_scatter(parent: Node3D, center: Vector3, seed_i: int) -> void:
	## World-space centers (parent near region origin).
	for i in 7:
		var ang := float(i) * 1.4 + float(seed_i)
		var p := center + Vector3(cos(ang) * (1.5 + float(i)), 0.0, sin(ang) * (1.2 + float(i % 3)))
		if not _placement_ok(p, false):
			continue
		var base := GrasslandHeightField.snap(p)
		StylizedMesh.add_box(parent, Vector3(0.08, 0.2, 0.08), WorldPalette.LEAF_DARK, base + Vector3(0, 0.1, 0), "Stem")
		var fc := WorldPalette.FLOWER if i % 2 == 0 else WorldPalette.FLOWER_Y
		StylizedMesh.add_box(parent, Vector3(0.18, 0.18, 0.18), fc, base + Vector3(0, 0.28, 0), "Bloom")


static func _flower_scatter_local(parent: Node3D, center: Vector3, seed_i: int) -> void:
	for i in 7:
		var ang := float(i) * 1.4 + float(seed_i)
		var local := center + Vector3(cos(ang) * (1.5 + float(i)), 0.0, sin(ang) * (1.2 + float(i % 3)))
		var world := parent.position + local
		if not _placement_ok(world, false):
			continue
		var y := GrasslandHeightField.height_at_v(world) - parent.position.y
		StylizedMesh.add_box(parent, Vector3(0.08, 0.2, 0.08), WorldPalette.LEAF_DARK, local + Vector3(0, y + 0.1, 0), "Stem")
		var fc := WorldPalette.FLOWER if i % 2 == 0 else WorldPalette.FLOWER_Y
		StylizedMesh.add_box(parent, Vector3(0.18, 0.18, 0.18), fc, local + Vector3(0, y + 0.28, 0), "Bloom")


static func _build_special_clearings(parent: Node3D) -> void:
	var pine := Node3D.new()
	pine.name = "PineHollow"
	pine.position = GrasslandLayout.LANDMARK_PINE_HOLLOW
	parent.add_child(pine)
	_clearing(pine, Vector3.ZERO, 101)
	var hollow_xfs: Array[Transform3D] = []
	for j in 14:
		hollow_xfs.append(_tree_xf(Vector3(cos(float(j)) * 14.0, 0, sin(float(j)) * 14.0), 1.05, float(j), pine.position))
	_emit_tree_multimesh(pine, "HollowPines", hollow_xfs, true)
	RegionPropKit.add_discoverable(pine, &"pine_hollow", "Pine Hollow", Vector3(0, 0.6, 0), 14, "A quiet ring of pines — the road noise fades.")
	result_chest_safe(pine, "PineHollowChest", Vector3(2, 0, -2))

	var meadow := Node3D.new()
	meadow.name = "MeadowClearing"
	meadow.position = GrasslandLayout.LANDMARK_MEADOW_CLEARING
	parent.add_child(meadow)
	var meadow_y := GrasslandHeightField.height_at_v(meadow.position) - meadow.position.y
	StylizedMesh.add_box(meadow, Vector3(22, 0.05, 18), WorldPalette.GRASS_LIGHT, Vector3(0, meadow_y + 0.03, 0), "Meadow", false, 1.0, &"grass")
	_flower_scatter_local(meadow, Vector3(0, 0, 0), 44)
	_flower_scatter_local(meadow, Vector3(4, 0, 3), 45)
	var meadow_trees: Array[Transform3D] = []
	_collect_tree_clump_local(meadow_trees, Vector3(-10, 0, 0), 6, 88, meadow.position)
	_collect_tree_clump_local(meadow_trees, Vector3(10, 0, -2), 6, 89, meadow.position)
	_emit_tree_multimesh(meadow, "MeadowTrees", meadow_trees, false)
	RegionPropKit.add_discoverable(meadow, &"meadow_clearing", "Meadow Clearing", Vector3(0, 0.6, 0), 12, "Wildflowers lean toward Risky Reels.")

	var wet := Node3D.new()
	wet.name = "StreamWetland"
	wet.position = GrasslandLayout.LANDMARK_STREAM_CROSSING
	parent.add_child(wet)
	var wet_bush: Array[Transform3D] = []
	var wet_rock: Array[Transform3D] = []
	_collect_bush_cluster_local(wet_bush, Vector3(-10, 0, 6), 8, 301, wet.position)
	_collect_bush_cluster_local(wet_bush, Vector3(12, 0, -5), 7, 302, wet.position)
	_collect_rocks_local(wet_rock, Vector3(8, 0, 7), 304, wet.position)
	_emit_bush_multimesh(wet, "WetBush", wet_bush)
	_emit_rock_multimesh(wet, "WetRock", wet_rock)
	_flower_scatter_local(wet, Vector3(-6, 0, -8), 303)
	_leaf_litter_local(wet, Vector3(0, 0, 9), 305)


static func result_chest_safe(parent: Node3D, chest_name: String, pos: Vector3) -> void:
	RegionPropKit.build_chest(parent, chest_name, pos, ChestInteractable.Rarity.NORMAL, 24.0, "Search the hollow")


static func _build_wilderness_fill(parent: Node3D) -> void:
	var fill := Node3D.new()
	fill.name = "WildernessFill"
	parent.add_child(fill)
	var anchors: Array[Vector3] = [
		Vector3(120, 0, 180), Vector3(-140, 0, 220), Vector3(260, 0, -160),
		Vector3(480, 0, 420), Vector3(900, 0, -200), Vector3(600, 0, 900),
		Vector3(200, 0, 1400), Vector3(1100, 0, 600), Vector3(40, 0, -900),
		Vector3(-80, 0, 700), Vector3(1500, 0, 300), Vector3(-600, 0, -300),
		Vector3(2200, 0, 1400), Vector3(700, 0, -2200), Vector3(-1200, 0, 900),
		GrasslandLayout.LANDMARK_CREATURE_DEN + Vector3(30, 0, -20),
		GrasslandLayout.LANDMARK_MEADOW_CLEARING + Vector3(-25, 0, 20),
		GrasslandLayout.LANDMARK_STREAM_CROSSING + Vector3(35, 0, 25),
		Vector3(1800, 0, 2600), Vector3(300, 0, -3200),
		Vector3(60, 0, 95), Vector3(-70, 0, 90), Vector3(95, 0, -70),
		Vector3(-85, 0, -75), Vector3(180, 0, 60), Vector3(-160, 0, 50),
		Vector3(400, 0, -400), Vector3(-450, 0, 350), Vector3(800, 0, 1100),
		Vector3(1200, 0, -1400), Vector3(-200, 0, 1600), Vector3(2500, 0, 500),
	]
	for i in anchors.size():
		var c: Vector3 = anchors[i]
		if not _placement_ok(c, true):
			continue
		_tree_clump_safe(fill, c, 12 + (i % 5), 500 + i)
		_tree_clump_safe(fill, c + Vector3(14, 0, -10), 9, 600 + i)
		_tree_clump_safe(fill, c + Vector3(-12, 0, 14), 7, 650 + i)
		_bush_cluster_safe(fill, c + Vector3(-8, 0, 8), 10, 700 + i)
		_rock_scatter_safe(fill, c + Vector3(6, 0, 12), 800 + i)
		_grass_patch_safe(fill, c + Vector3(4, 0, 4), 18.0, 180, 900 + i)
		_flower_scatter_safe(fill, c + Vector3(-4, 0, 6), 1000 + i)
		if i % 2 == 0:
			_fallen_log(fill, c + Vector3(9, 0, -6), 1050 + i)
		if i % 3 == 0:
			_trail_marker(fill, c + Vector3(-12, 0, 6), 1100 + i)
		if i % 4 == 0:
			_camp_nook(fill, c + Vector3(8, 0, -14), 1200 + i)
		if ExternalPropKit.is_available() and i % 4 == 0:
			var kind: StringName = &"tree_pine" if i % 2 == 0 else &"tree_oak"
			var tp := GrasslandHeightField.snap(c + Vector3(-6, 0, 10))
			ExternalPropKit.spawn(fill, kind, tp, float(i * 40), 1.0 + float(i % 3) * 0.08, "LandmarkTree_%d" % i)
			ExternalPropKit.spawn(fill, &"rock_tall", GrasslandHeightField.snap(c + Vector3(10, 0, 4)), float(i * 17), 1.0, "LandmarkRock_%d" % i)


static func _trail_marker(parent: Node3D, pos: Vector3, seed_i: int) -> void:
	if not _placement_ok(pos, false):
		return
	var m := Node3D.new()
	m.name = "TrailMarker_%d" % seed_i
	m.position = GrasslandHeightField.snap(pos)
	parent.add_child(m)
	StylizedMesh.add_box(m, Vector3(0.12, 1.1, 0.12), WorldPalette.WOOD.darkened(0.15), Vector3(0, 0.55, 0), "Post", false, 1.0, &"wood")
	StylizedMesh.add_box(m, Vector3(0.55, 0.28, 0.08), Color(0.75, 0.55, 0.3), Vector3(0.2, 0.95, 0), "Sign", false, 1.0, &"wood")


static func _camp_nook(parent: Node3D, pos: Vector3, seed_i: int) -> void:
	if not _placement_ok(pos, false):
		return
	var camp := Node3D.new()
	camp.name = "CampNook_%d" % seed_i
	camp.position = GrasslandHeightField.snap(pos)
	parent.add_child(camp)
	StylizedMesh.add_box(camp, Vector3(2.4, 0.04, 2.4), WorldPalette.DIRT.lightened(0.05), Vector3(0, 0.03, 0), "ClearDirt", false, 1.0, &"dirt")
	if ExternalPropKit.is_available():
		ExternalPropKit.spawn(camp, &"campfire", Vector3(0, 0, 0), float(seed_i % 360), 1.0, "Campfire")
		ExternalPropKit.spawn(camp, &"tent", Vector3(2.2, 0, -1.2), 35.0, 0.95, "Tent")
		ExternalPropKit.spawn(camp, &"log", Vector3(-1.4, 0, 0.8), -20.0, 1.0, "SeatLog")
		ExternalPropKit.spawn(camp, &"mushroom", Vector3(-2.0, 0, -1.5), 0.0, 1.2, "Shrooms")
	else:
		StylizedMesh.add_box(camp, Vector3(0.7, 0.2, 0.7), WorldPalette.ROCK, Vector3(0, 0.12, 0), "FireRing", false, 1.0, &"dirt")
		StylizedMesh.add_box(camp, Vector3(1.2, 0.25, 0.35), WorldPalette.WOOD, Vector3(0.9, 0.2, 0.6), "LogSeat", false, 1.0, &"wood")
		StylizedMesh.add_box(camp, Vector3(0.35, 0.45, 0.35), Color(0.45, 0.35, 0.25), Vector3(-0.8, 0.3, -0.5), "Pack", false, 1.0, &"wood")


static func _build_pine_ridges(parent: Node3D) -> void:
	var pine := Node3D.new()
	pine.name = "PineRidges"
	parent.add_child(pine)
	var centers: Array[Vector3] = [
		GrasslandLayout.LANDMARK_WEST_RIDGE,
		GrasslandLayout.LANDMARK_NORTH_PASS,
		GrasslandLayout.LANDMARK_HILLSIDE_CAVE + Vector3(-20, 0, 10),
		GrasslandLayout.LANDMARK_SOUTH_BLUFFS + Vector3(-40, 0, -30),
		Vector3(-900, 0, -800),
		Vector3(2400, 0, -900),
	]
	for i in centers.size():
		var c: Vector3 = centers[i]
		var xfs: Array[Transform3D] = []
		var rock_xfs: Array[Transform3D] = []
		for j in 14:
			var ang := float(j) * 0.55 + float(i)
			var p := c + Vector3(cos(ang) * (8.0 + float(j % 5) * 4.0), 0, sin(ang) * (8.0 + float(j % 4) * 4.0))
			if _placement_ok(p, true):
				xfs.append(_tree_xf(p, 1.0 + float((j + i) % 4) * 0.12, ang))
		_collect_rocks(rock_xfs, c + Vector3(5, 0, -4), 1200 + i)
		_emit_tree_multimesh(pine, "RidgePine_%d" % i, xfs, true)
		_emit_rock_multimesh(pine, "RidgeRock_%d" % i, rock_xfs)


static func _build_biome_clutter(parent: Node3D) -> void:
	## Open-field scatter — not empty meadows between forests.
	var clutter := Node3D.new()
	clutter.name = "FieldClutter"
	parent.add_child(clutter)
	var field_centers: Array[Vector3] = [
		Vector3(350, 0, 50), Vector3(700, 0, -700), Vector3(1300, 0, 900),
		Vector3(-300, 0, 1100), Vector3(500, 0, 1800), Vector3(1900, 0, 400),
		Vector3(100, 0, -1500), Vector3(-700, 0, 200), Vector3(2500, 0, 1800),
		Vector3(900, 0, 2800), Vector3(-200, 0, -2500), Vector3(1600, 0, -200),
		Vector3(55, 0, 70), Vector3(-55, 0, 75), Vector3(220, 0, -40),
		Vector3(-210, 0, -50), Vector3(450, 0, 250), Vector3(-480, 0, -180),
		Vector3(1000, 0, 500), Vector3(1500, 0, -900), Vector3(-1000, 0, 800),
	]
	for i in field_centers.size():
		var c: Vector3 = field_centers[i]
		if not _placement_ok(c, false):
			continue
		var tree_xfs: Array[Transform3D] = []
		var bush_xfs: Array[Transform3D] = []
		var rock_xfs: Array[Transform3D] = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(i) * 4243 + 9
		for j in 20:
			var ang := rng.randf() * TAU
			var r := rng.randf_range(4.0, 32.0)
			var p := c + Vector3(cos(ang) * r, 0, sin(ang) * r)
			if _placement_ok(p, true) and rng.randf() < 0.65:
				tree_xfs.append(_tree_xf(p, 0.75 + rng.randf() * 0.35, ang))
		for j in 28:
			var ang := rng.randf() * TAU
			var p := c + Vector3(cos(ang) * rng.randf() * 28.0, 0, sin(ang) * rng.randf() * 28.0)
			if _placement_ok(p, false):
				bush_xfs.append(_bush_xf(p, 0.45 + rng.randf() * 0.35, ang))
		for j in 16:
			var ang := rng.randf() * TAU
			var p := c + Vector3(cos(ang) * rng.randf() * 22.0, 0, sin(ang) * rng.randf() * 22.0)
			if _placement_ok(p, false):
				rock_xfs.append(_rock_xf(p, 0.28 + rng.randf() * 0.3, ang))
		_grass_patch_safe(clutter, c, 22.0, 220, 4000 + i)
		_flower_scatter_safe(clutter, c + Vector3(3, 0, -2), 4100 + i)
		_flower_scatter_safe(clutter, c + Vector3(-5, 0, 4), 4200 + i)
		_emit_tree_multimesh(clutter, "FieldTree_%d" % i, tree_xfs, false)
		_emit_bush_multimesh(clutter, "FieldBush_%d" % i, bush_xfs)
		_emit_rock_multimesh(clutter, "FieldRock_%d" % i, rock_xfs)


static func _bush_cluster_safe(parent: Node3D, center: Vector3, count: int, seed_i: int) -> void:
	var xfs: Array[Transform3D] = []
	_collect_bush_cluster(xfs, center, count, seed_i)
	_emit_bush_multimesh(parent, "BushCl_%d" % seed_i, xfs)


static func _rock_scatter_safe(parent: Node3D, center: Vector3, seed_i: int) -> void:
	var xfs: Array[Transform3D] = []
	_collect_rocks(xfs, center, seed_i)
	_emit_rock_multimesh(parent, "RockCl_%d" % seed_i, xfs)


## --- MultiMesh helpers ------------------------------------------------------------

static func _tree_xf(local: Vector3, scale_v: float, yaw: float, parent_origin: Vector3 = Vector3.ZERO) -> Transform3D:
	var world := parent_origin + local
	var y := GrasslandHeightField.height_at(world.x, world.z) - parent_origin.y
	var xf := Transform3D.IDENTITY.scaled(Vector3(scale_v, scale_v, scale_v))
	xf = xf.rotated(Vector3.UP, yaw)
	xf.origin = Vector3(local.x, y, local.z)
	return xf


static func _bush_xf(local: Vector3, scale_v: float, yaw: float, parent_origin: Vector3 = Vector3.ZERO) -> Transform3D:
	var world := parent_origin + local
	var y := GrasslandHeightField.height_at(world.x, world.z) - parent_origin.y
	var xf := Transform3D.IDENTITY.scaled(Vector3(scale_v, scale_v * 0.85, scale_v))
	xf = xf.rotated(Vector3.UP, yaw)
	xf.origin = Vector3(local.x, y, local.z)
	return xf


static func _rock_xf(local: Vector3, scale_v: float, yaw: float, parent_origin: Vector3 = Vector3.ZERO) -> Transform3D:
	var world := parent_origin + local
	var y := GrasslandHeightField.height_at(world.x, world.z) - parent_origin.y
	var xf := Transform3D.IDENTITY.scaled(Vector3(scale_v, scale_v * 0.6, scale_v * 0.85))
	xf = xf.rotated(Vector3.UP, yaw)
	xf.origin = Vector3(local.x, y, local.z)
	return xf


static func _mushroom_xf(local: Vector3, scale_v: float, yaw: float, parent_origin: Vector3 = Vector3.ZERO) -> Transform3D:
	var world := parent_origin + local
	var y := GrasslandHeightField.height_at(world.x, world.z) - parent_origin.y
	var xf := Transform3D.IDENTITY.scaled(Vector3(scale_v, scale_v, scale_v))
	xf = xf.rotated(Vector3.UP, yaw)
	xf.origin = Vector3(local.x, y, local.z)
	return xf


static func _emit_tree_multimesh(parent: Node3D, node_name: String, xfs: Array[Transform3D], pine: bool) -> void:
	if xfs.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _pine_proxy_mesh() if pine else _tree_proxy_mesh()
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mmi.multimesh = mm
	mmi.material_override = StylizedMesh.make_material(WorldPalette.LEAF_DARK if pine else WorldPalette.LEAF, 1.0, 0.0, 0.0, &"leaf")
	mmi.visibility_range_end = AdventureNodeBudget.LOD_TREE_END
	mmi.visibility_range_end_margin = 60.0
	parent.add_child(mmi)


static func _emit_bush_multimesh(parent: Node3D, node_name: String, xfs: Array[Transform3D]) -> void:
	if xfs.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _bush_proxy_mesh()
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mmi.multimesh = mm
	mmi.material_override = StylizedMesh.make_material(WorldPalette.BUSH, 1.0, 0.0, 0.0, &"leaf")
	mmi.visibility_range_end = AdventureNodeBudget.LOD_BUSH_END
	parent.add_child(mmi)


static func _emit_rock_multimesh(parent: Node3D, node_name: String, xfs: Array[Transform3D]) -> void:
	if xfs.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _rock_proxy_mesh()
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mmi.multimesh = mm
	mmi.material_override = StylizedMesh.make_material(WorldPalette.ROCK, 1.0, 0.0, 0.0, &"dirt")
	mmi.visibility_range_end = AdventureNodeBudget.LOD_ROCK_END
	parent.add_child(mmi)


static func _emit_mushroom_multimesh(parent: Node3D, node_name: String, xfs: Array[Transform3D]) -> void:
	if xfs.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _mushroom_proxy_mesh()
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mmi.multimesh = mm
	mmi.material_override = StylizedMesh.make_material(Color(0.75, 0.35, 0.35), 1.0, 0.0, 0.0, &"flat")
	mmi.visibility_range_end = AdventureNodeBudget.LOD_MUSHROOM_END
	parent.add_child(mmi)


static func _tree_proxy_mesh() -> ArrayMesh:
	if _tree_mesh_cache != null:
		return _tree_mesh_cache
	_tree_mesh_cache = _build_box_cluster([
		[Vector3(0.3, 1.7, 0.3), Vector3(0, 0.85, 0)],
		[Vector3(1.55, 1.2, 1.55), Vector3(0, 2.15, 0)],
		[Vector3(0.95, 0.85, 0.95), Vector3(0.2, 2.85, 0.1)],
	])
	return _tree_mesh_cache


static func _pine_proxy_mesh() -> ArrayMesh:
	if _pine_mesh_cache != null:
		return _pine_mesh_cache
	_pine_mesh_cache = _build_box_cluster([
		[Vector3(0.28, 2.2, 0.28), Vector3(0, 1.1, 0)],
		[Vector3(1.4, 1.0, 1.4), Vector3(0, 2.0, 0)],
		[Vector3(1.0, 0.9, 1.0), Vector3(0, 2.7, 0)],
		[Vector3(0.55, 0.7, 0.55), Vector3(0, 3.3, 0)],
	])
	return _pine_mesh_cache


static func _bush_proxy_mesh() -> ArrayMesh:
	if _bush_mesh_cache != null:
		return _bush_mesh_cache
	_bush_mesh_cache = _build_box_cluster([[Vector3(1.0, 0.7, 1.0), Vector3(0, 0.35, 0)]])
	return _bush_mesh_cache


static func _rock_proxy_mesh() -> ArrayMesh:
	if _rock_mesh_cache != null:
		return _rock_mesh_cache
	_rock_mesh_cache = _build_box_cluster([[Vector3(1.0, 0.55, 0.85), Vector3(0, 0.28, 0)]])
	return _rock_mesh_cache


static func _mushroom_proxy_mesh() -> ArrayMesh:
	if _mushroom_mesh_cache != null:
		return _mushroom_mesh_cache
	_mushroom_mesh_cache = _build_box_cluster([
		[Vector3(0.12, 0.28, 0.12), Vector3(0, 0.14, 0)],
		[Vector3(0.35, 0.12, 0.35), Vector3(0, 0.32, 0)],
	])
	return _mushroom_mesh_cache


static func _build_box_cluster(parts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		var size: Vector3 = part[0]
		var pos: Vector3 = part[1]
		_append_box(st, size, pos)
	st.generate_normals()
	return st.commit()


static func _append_box(st: SurfaceTool, size: Vector3, pos: Vector3) -> void:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var verts: Array[Vector3] = [
		pos + Vector3(-hx, -hy, -hz), pos + Vector3(hx, -hy, -hz), pos + Vector3(hx, hy, -hz), pos + Vector3(-hx, hy, -hz),
		pos + Vector3(-hx, -hy, hz), pos + Vector3(hx, -hy, hz), pos + Vector3(hx, hy, hz), pos + Vector3(-hx, hy, hz),
	]
	var faces := [
		[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0],
	]
	for f in faces:
		st.add_vertex(verts[f[0]])
		st.add_vertex(verts[f[1]])
		st.add_vertex(verts[f[2]])
		st.add_vertex(verts[f[0]])
		st.add_vertex(verts[f[2]])
		st.add_vertex(verts[f[3]])


static func _placement_ok(world: Vector3, for_tree: bool) -> bool:
	if not GrasslandLayout.is_on_island(world, -80.0 if for_tree else -40.0):
		return false
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		var r: float = float(zone["radius"])
		var keep := r if for_tree else r * 0.72
		if Vector3(world.x, 0, world.z).distance_to(Vector3(hub.x, 0, hub.z)) < keep:
			return false
	var road_r := GrasslandLayout.road_clearance() + (2.0 if for_tree else 0.0)
	for path in RegionMapCatalog.road_polylines():
		for i in range(1, path.size()):
			if _dist_point_to_segment(world, path[i - 1], path[i]) < road_r:
				return false
	return true


static func placement_allowed(world: Vector3, for_tree: bool = true) -> bool:
	return _placement_ok(world, for_tree)


static func _dist_point_to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ab_len2 := ab.length_squared()
	if ab_len2 < 0.0001:
		return ap.length()
	var t := clampf(ap.dot(ab) / ab_len2, 0.0, 1.0)
	var closest := Vector2(a.x, a.z) + ab * t
	return Vector2(p.x, p.z).distance_to(closest)


static func _perp(a: Vector3, b: Vector3) -> Vector3:
	var d := (b - a).normalized()
	return Vector3(-d.z, 0.0, d.x)
