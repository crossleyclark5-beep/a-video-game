class_name RegionVegetationBuilder
extends RefCounted
## Vegetation with placement rules — no grass on roads, no plants in building pads.


static func build(root: Node3D) -> void:
	var veg := Node3D.new()
	veg.name = "RegionVegetation"
	root.add_child(veg)
	_build_corridor_forests(veg)
	_build_grass_strips(veg)
	_build_special_clearings(veg)
	_build_wilderness_fill(veg)
	_build_pine_ridges(veg)


static func _build_corridor_forests(parent: Node3D) -> void:
	var forests := Node3D.new()
	forests.name = "ForestBelts"
	parent.add_child(forests)
	_forest_along(forests, GrasslandLayout.path_park_to_salty(), 1)
	_forest_along(forests, GrasslandLayout.path_park_to_reels(), 2)
	_forest_along(forests, GrasslandLayout.path_park_to_fields(), 3)
	_tree_line(forests, Vector3(-180, 0, -120), Vector3(-180, 0, 220), 14, 4)
	_tree_line(forests, Vector3(-40, 0, -1100), Vector3(200, 0, -1700), 12, 5)
	_forest_along(forests, GrasslandLayout.path_park_to_mere(), 4)
	_forest_along(forests, GrasslandLayout.path_park_to_mile(), 5)
	_forest_along(forests, GrasslandLayout.path_park_to_grove(), 6)


static func _forest_along(parent: Node3D, points: Array[Vector3], seed_base: int) -> void:
	var clear := GrasslandLayout.road_clearance() + 8.0
	for i in range(1, points.size()):
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		var mid := a.lerp(b, 0.5)
		var perp := _perp(a, b)
		## Belts well outside the road shoulder — denser living forest walls.
		_tree_clump_safe(parent, mid + perp * (clear + 14.0), 7 + (i % 4), seed_base * 17 + i)
		_tree_clump_safe(parent, mid - perp * (clear + 18.0), 6 + ((i + 1) % 4), seed_base * 31 + i)
		_bush_cluster_safe(parent, mid + perp * (clear + 8.0), 4, seed_base * 41 + i)
		_bush_cluster_safe(parent, mid - perp * (clear + 9.0), 3, seed_base * 43 + i)
		if i % 2 == 0:
			_tree_clump_safe(parent, mid + perp * (clear + 30.0), 5, seed_base * 13 + i * 3)
			_rock_scatter_safe(parent, mid - perp * (clear + 22.0), seed_base + i)
		if i % 3 == 0:
			_clearing_safe(parent, mid + perp * (-(clear + 34.0)), seed_base + i)
			_tree_clump_safe(parent, mid - perp * (clear + 42.0), 4, seed_base * 19 + i)


static func _tree_line(parent: Node3D, a: Vector3, b: Vector3, count: int, seed_i: int) -> void:
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		var p := a.lerp(b, t)
		var side := _perp(a, b) * (6.0 if i % 2 == 0 else -5.0)
		_pixel_tree_safe(parent, p + side, 0.85 + float((i + seed_i) % 4) * 0.12, i + seed_i)


static func _tree_clump_safe(parent: Node3D, center: Vector3, count: int, seed_i: int) -> void:
	if not _placement_ok(center, true):
		return
	_tree_clump(parent, center, count, seed_i)


static func _clearing_safe(parent: Node3D, center: Vector3, seed_i: int) -> void:
	if not _placement_ok(center, true):
		return
	_clearing(parent, center, seed_i)


static func _tree_clump(parent: Node3D, center: Vector3, count: int, seed_i: int) -> void:
	for j in count:
		var ang := float(j) * 2.1 + float(seed_i) * 0.15
		var r := 2.5 + float(j % 3) * 2.2
		var p := center + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		_pixel_tree_safe(parent, p, 0.8 + float((j + seed_i) % 5) * 0.1, seed_i + j)


static func _clearing(parent: Node3D, center: Vector3, seed_i: int) -> void:
	StylizedMesh.add_box(parent, Vector3(14, 0.04, 14), WorldPalette.GRASS_LIGHT, center + Vector3(0, 0.03, 0), "Clearing_%d" % seed_i, false, 1.0, &"grass")
	for j in 6:
		var ang := float(j) * TAU / 6.0
		_pixel_tree_safe(parent, center + Vector3(cos(ang) * 9.0, 0, sin(ang) * 9.0), 0.9, seed_i + j)
	StylizedMesh.add_box(parent, Vector3(0.35, 0.2, 0.3), WorldPalette.ROCK, center + Vector3(1.5, 0.1, -1.0), "ClearRock", false, 1.0, &"dirt")


static func _pixel_tree_safe(parent: Node3D, pos: Vector3, scale_v: float, idx: int) -> void:
	if not _placement_ok(pos, true):
		return
	_pixel_tree(parent, pos, scale_v, idx)


static func _pixel_tree(parent: Node3D, pos: Vector3, scale_v: float, idx: int) -> void:
	var tree := Node3D.new()
	tree.name = "VTree_%d" % idx
	tree.position = pos
	tree.rotation_degrees.y = float(idx * 41 % 360)
	parent.add_child(tree)
	var tw := 0.3 * scale_v
	StylizedMesh.add_box(tree, Vector3(tw, 1.6 * scale_v, tw), WorldPalette.TRUNK, Vector3(0, 0.8 * scale_v, 0), "Trunk", false, 1.0, &"wood")
	var leaf := WorldPalette.LEAF if idx % 2 == 0 else WorldPalette.LEAF_DARK
	if idx % 3 == 0:
		leaf = WorldPalette.LEAF_LIT
	StylizedMesh.add_box(tree, Vector3(1.5 * scale_v, 1.1 * scale_v, 1.5 * scale_v), leaf, Vector3(0, 2.0 * scale_v, 0), "C1", false, 1.0, &"leaf")
	StylizedMesh.add_box(tree, Vector3(0.9 * scale_v, 0.75 * scale_v, 0.9 * scale_v), leaf.lightened(0.06), Vector3(0.35 * scale_v, 2.55 * scale_v, 0.15), "C2", false, 1.0, &"leaf")
	OcclusionUtil.mark_named_in(tree, PackedStringArray(["C1", "C2"]))


static func _build_grass_strips(parent: Node3D) -> void:
	var grass_root := Node3D.new()
	grass_root.name = "GrassStrips"
	parent.add_child(grass_root)
	## Meadow rings outside hub pads — never on building footprints.
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		var r: float = float(zone["radius"])
		## Outer meadow band beyond the pad.
		_grass_patch_safe(grass_root, hub + Vector3(r * 0.85, 0, 0), 10.0, 160, int(hub.x) + 11)
		_grass_patch_safe(grass_root, hub + Vector3(-r * 0.7, 0, r * 0.55), 9.0, 140, int(hub.z) + 19)
		_grass_patch_safe(grass_root, hub + Vector3(r * 0.4, 0, -r * 0.75), 8.0, 120, int(hub.x + hub.z) + 3)
	var clear := GrasslandLayout.road_clearance() + 4.0
	for path in RegionMapCatalog.road_polylines():
		for i in range(1, path.size()):
			var mid: Vector3 = path[i - 1].lerp(path[i], 0.5)
			var perp := _perp(path[i - 1], path[i])
			_grass_patch_safe(grass_root, mid + perp * clear, 10.0, 180, i * 7)
			_grass_patch_safe(grass_root, mid - perp * clear, 10.0, 170, i * 9 + 1)
			if i % 2 == 0:
				_flower_scatter_safe(grass_root, mid + perp * (clear + 4.0), i)
				_flower_scatter_safe(grass_root, mid - perp * (clear + 6.0), i + 17)
			if i % 3 == 0:
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
	mmi.position = center
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
		## Cull blades that land on roads / pads.
		if not _placement_ok(world, false):
			continue
		var h := 0.22 + rng.randf() * 0.45
		var lean := rng.randf_range(-0.25, 0.25)
		var xf := Transform3D.IDENTITY
		xf = xf.scaled(Vector3(1.0, h / 0.35, 1.0))
		xf = xf.rotated(Vector3.UP, a)
		xf = xf.rotated(Vector3.RIGHT, lean)
		xf.origin = Vector3(x, h * 0.5, z)
		transforms.append(xf)
	if transforms.is_empty():
		return
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	mmi.multimesh = mm
	parent.add_child(mmi)


static func _flower_scatter(parent: Node3D, center: Vector3, seed_i: int) -> void:
	for i in 5:
		var ang := float(i) * 1.4 + float(seed_i)
		var p := center + Vector3(cos(ang) * (1.5 + float(i)), 0.0, sin(ang) * (1.2 + float(i % 3)))
		if not _placement_ok(p, false):
			continue
		StylizedMesh.add_box(parent, Vector3(0.08, 0.2, 0.08), WorldPalette.LEAF_DARK, p + Vector3(0, 0.1, 0), "Stem")
		var fc := WorldPalette.FLOWER if i % 2 == 0 else WorldPalette.FLOWER_Y
		StylizedMesh.add_box(parent, Vector3(0.18, 0.18, 0.18), fc, p + Vector3(0, 0.28, 0), "Bloom")


static func _build_special_clearings(parent: Node3D) -> void:
	var pine := Node3D.new()
	pine.name = "PineHollow"
	pine.position = GrasslandLayout.LANDMARK_PINE_HOLLOW
	parent.add_child(pine)
	_clearing(pine, Vector3.ZERO, 101)
	for j in 8:
		_pixel_tree(pine, Vector3(cos(float(j)) * 14.0, 0, sin(float(j)) * 14.0), 1.05, 200 + j)
	RegionPropKit.add_discoverable(pine, &"pine_hollow", "Pine Hollow", Vector3(0, 0.6, 0), 14, "A quiet ring of pines — the road noise fades.")
	result_chest_safe(pine, "PineHollowChest", Vector3(2, 0, -2))

	var meadow := Node3D.new()
	meadow.name = "MeadowClearing"
	meadow.position = GrasslandLayout.LANDMARK_MEADOW_CLEARING
	parent.add_child(meadow)
	StylizedMesh.add_box(meadow, Vector3(22, 0.05, 18), WorldPalette.GRASS_LIGHT, Vector3(0, 0.03, 0), "Meadow", false, 1.0, &"grass")
	_flower_scatter(meadow, Vector3(0, 0, 0), 44)
	_flower_scatter(meadow, Vector3(4, 0, 3), 45)
	_tree_clump(meadow, Vector3(-10, 0, 0), 4, 88)
	_tree_clump(meadow, Vector3(10, 0, -2), 4, 89)
	RegionPropKit.add_discoverable(meadow, &"meadow_clearing", "Meadow Clearing", Vector3(0, 0.6, 0), 12, "Wildflowers lean toward Risky Reels.")


static func result_chest_safe(parent: Node3D, chest_name: String, pos: Vector3) -> void:
	RegionPropKit.build_chest(parent, chest_name, pos, ChestInteractable.Rarity.NORMAL, 24.0, "Search the hollow")


static func _build_wilderness_fill(parent: Node3D) -> void:
	## Dense nature between hubs — forests, bushes, flowers, rocks (not empty fields).
	var fill := Node3D.new()
	fill.name = "WildernessFill"
	parent.add_child(fill)
	var anchors: Array[Vector3] = [
		Vector3(120, 0, 180),
		Vector3(-140, 0, 220),
		Vector3(260, 0, -160),
		Vector3(480, 0, 420),
		Vector3(900, 0, -200),
		Vector3(600, 0, 900),
		Vector3(200, 0, 1400),
		Vector3(1100, 0, 600),
		Vector3(40, 0, -900),
		Vector3(-80, 0, 700),
		GrasslandLayout.LANDMARK_CREATURE_DEN + Vector3(30, 0, -20),
		GrasslandLayout.LANDMARK_MEADOW_CLEARING + Vector3(-25, 0, 20),
		GrasslandLayout.LANDMARK_STREAM_CROSSING + Vector3(35, 0, 25),
	]
	for i in anchors.size():
		var c: Vector3 = anchors[i]
		if not _placement_ok(c, true):
			continue
		_tree_clump_safe(fill, c, 6 + (i % 4), 500 + i)
		_tree_clump_safe(fill, c + Vector3(14, 0, -10), 4, 600 + i)
		_bush_cluster_safe(fill, c + Vector3(-8, 0, 8), 5, 700 + i)
		_rock_scatter_safe(fill, c + Vector3(6, 0, 12), 800 + i)
		_grass_patch_safe(fill, c + Vector3(4, 0, 4), 12.0, 160, 900 + i)
		if i % 2 == 0:
			_flower_scatter_safe(fill, c + Vector3(-4, 0, 6), 1000 + i)


static func _build_pine_ridges(parent: Node3D) -> void:
	## Mountain / ridge pines — taller, darker canopy.
	var pine := Node3D.new()
	pine.name = "PineRidges"
	parent.add_child(pine)
	var centers: Array[Vector3] = [
		GrasslandLayout.LANDMARK_WEST_RIDGE,
		GrasslandLayout.LANDMARK_NORTH_PASS,
		GrasslandLayout.LANDMARK_HILLSIDE_CAVE + Vector3(-20, 0, 10),
		GrasslandLayout.LANDMARK_SOUTH_BLUFFS + Vector3(-40, 0, -30),
	]
	for i in centers.size():
		var c: Vector3 = centers[i]
		for j in 10:
			var ang := float(j) * 0.7 + float(i)
			var p := c + Vector3(cos(ang) * (8.0 + float(j % 4) * 3.0), 0, sin(ang) * (8.0 + float(j % 3) * 3.5))
			_pine_tree_safe(pine, p, 1.0 + float((j + i) % 4) * 0.12, 1100 + i * 20 + j)
		_rock_scatter_safe(pine, c + Vector3(5, 0, -4), 1200 + i)


static func _bush_cluster_safe(parent: Node3D, center: Vector3, count: int, seed_i: int) -> void:
	if not _placement_ok(center, false):
		return
	for j in count:
		var ang := float(j) * 1.9 + float(seed_i) * 0.1
		var r := 1.2 + float(j % 3) * 0.9
		var p := center + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		if not _placement_ok(p, false):
			continue
		var s := 0.55 + float((j + seed_i) % 3) * 0.15
		StylizedMesh.add_box(parent, Vector3(s, s * 0.7, s), WorldPalette.BUSH if j % 2 == 0 else WorldPalette.LEAF_DARK, p + Vector3(0, s * 0.35, 0), "Bush_%d_%d" % [seed_i, j], false, 1.0, &"leaf")


static func _rock_scatter_safe(parent: Node3D, center: Vector3, seed_i: int) -> void:
	if not _placement_ok(center, false):
		return
	for j in 4:
		var ang := float(j) * 1.5 + float(seed_i)
		var p := center + Vector3(cos(ang) * (1.0 + float(j)), 0.0, sin(ang) * (0.8 + float(j % 3)))
		if not _placement_ok(p, false):
			continue
		var s := 0.35 + float((j + seed_i) % 3) * 0.2
		StylizedMesh.add_box(parent, Vector3(s, s * 0.55, s * 0.8), WorldPalette.ROCK.darkened(0.04 * float(j)), p + Vector3(0, s * 0.25, 0), "Rock_%d_%d" % [seed_i, j], false, 1.0, &"dirt")


static func _pine_tree_safe(parent: Node3D, pos: Vector3, scale_v: float, idx: int) -> void:
	if not _placement_ok(pos, true):
		return
	var tree := Node3D.new()
	tree.name = "Pine_%d" % idx
	tree.position = pos
	tree.rotation_degrees.y = float(idx * 37 % 360)
	parent.add_child(tree)
	StylizedMesh.add_box(tree, Vector3(0.28 * scale_v, 2.2 * scale_v, 0.28 * scale_v), WorldPalette.TRUNK.darkened(0.1), Vector3(0, 1.1 * scale_v, 0), "Trunk", false, 1.0, &"wood")
	var leaf := WorldPalette.LEAF_DARK
	StylizedMesh.add_box(tree, Vector3(1.4 * scale_v, 1.0 * scale_v, 1.4 * scale_v), leaf, Vector3(0, 2.0 * scale_v, 0), "C1", false, 1.0, &"leaf")
	StylizedMesh.add_box(tree, Vector3(1.0 * scale_v, 0.9 * scale_v, 1.0 * scale_v), leaf.lightened(0.05), Vector3(0, 2.7 * scale_v, 0), "C2", false, 1.0, &"leaf")
	StylizedMesh.add_box(tree, Vector3(0.55 * scale_v, 0.7 * scale_v, 0.55 * scale_v), leaf.lightened(0.1), Vector3(0, 3.3 * scale_v, 0), "C3", false, 1.0, &"leaf")
	OcclusionUtil.mark_named_in(tree, PackedStringArray(["C1", "C2", "C3"]))


static func _placement_ok(world: Vector3, for_tree: bool) -> bool:
	## Stay on-island (trees can sit near coast; grass stays inland a bit).
	if not GrasslandLayout.is_on_island(world, -80.0 if for_tree else -40.0):
		return false
	## Keep clear of building pads / plaza centers.
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		var r: float = float(zone["radius"])
		## Trees need a slightly larger keep-out so trunks don't punch through roofs.
		var keep := r if for_tree else r * 0.72
		if Vector3(world.x, 0, world.z).distance_to(Vector3(hub.x, 0, hub.z)) < keep:
			return false
	## Keep clear of road centerlines.
	var road_r := GrasslandLayout.road_clearance() + (2.0 if for_tree else 0.0)
	for path in RegionMapCatalog.road_polylines():
		for i in range(1, path.size()):
			if _dist_point_to_segment(world, path[i - 1], path[i]) < road_r:
				return false
	return true


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
