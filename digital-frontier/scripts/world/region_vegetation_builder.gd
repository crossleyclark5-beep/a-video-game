class_name RegionVegetationBuilder
extends RefCounted
## Dense handheld-friendly vegetation for travel corridors and hubs.
## MultiMesh grass + structured forest belts (not random scatter).


static func build(root: Node3D) -> void:
	var veg := Node3D.new()
	veg.name = "RegionVegetation"
	root.add_child(veg)
	_build_corridor_forests(veg)
	_build_grass_strips(veg)
	_build_special_clearings(veg)


static func _build_corridor_forests(parent: Node3D) -> void:
	var forests := Node3D.new()
	forests.name = "ForestBelts"
	parent.add_child(forests)
	_forest_along(forests, GrasslandLayout.path_park_to_salty(), 1)
	_forest_along(forests, GrasslandLayout.path_park_to_reels(), 2)
	_forest_along(forests, GrasslandLayout.path_park_to_fields(), 3)
	## Tree line west of Park (natural barrier toward West Ridge).
	_tree_line(forests, Vector3(-180, 0, -120), Vector3(-180, 0, 220), 14, 4)
	## Tree line framing North Pass approach.
	_tree_line(forests, Vector3(760, 0, -700), Vector3(1040, 0, -1100), 12, 5)


static func _forest_along(parent: Node3D, points: Array[Vector3], seed_base: int) -> void:
	for i in range(1, points.size()):
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		var mid := a.lerp(b, 0.5)
		var perp := _perp(a, b)
		## Structured belts — left dense, right lighter with a clearing gap.
		_tree_clump(parent, mid + perp * 22.0, 5 + (i % 3), seed_base * 17 + i)
		_tree_clump(parent, mid - perp * 26.0, 4 + ((i + 1) % 3), seed_base * 31 + i)
		if i % 2 == 0:
			_tree_clump(parent, mid + perp * 38.0, 3, seed_base * 13 + i * 3)
		## Hidden clearing pocket every few segments.
		if i % 3 == 0:
			_clearing(parent, mid + perp * (-42.0), seed_base + i)


static func _tree_line(parent: Node3D, a: Vector3, b: Vector3, count: int, seed_i: int) -> void:
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		var p := a.lerp(b, t)
		var side := _perp(a, b) * (6.0 if i % 2 == 0 else -5.0)
		_pixel_tree(parent, p + side, 0.85 + float((i + seed_i) % 4) * 0.12, i + seed_i)


static func _tree_clump(parent: Node3D, center: Vector3, count: int, seed_i: int) -> void:
	for j in count:
		var ang := float(j) * 2.1 + float(seed_i) * 0.15
		var r := 2.5 + float(j % 3) * 2.2
		var p := center + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		_pixel_tree(parent, p, 0.8 + float((j + seed_i) % 5) * 0.1, seed_i + j)


static func _clearing(parent: Node3D, center: Vector3, seed_i: int) -> void:
	## Open grass ring with a ring of trees — reads as a secret pocket.
	StylizedMesh.add_box(parent, Vector3(14, 0.04, 14), WorldPalette.GRASS_LIGHT, center + Vector3(0, 0.03, 0), "Clearing_%d" % seed_i, false, 1.0, &"grass")
	for j in 6:
		var ang := float(j) * TAU / 6.0
		_pixel_tree(parent, center + Vector3(cos(ang) * 9.0, 0, sin(ang) * 9.0), 0.9, seed_i + j)
	StylizedMesh.add_box(parent, Vector3(0.35, 0.2, 0.3), WorldPalette.ROCK, center + Vector3(1.5, 0.1, -1.0), "ClearRock", false, 1.0, &"dirt")


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


static func _build_grass_strips(parent: Node3D) -> void:
	var grass_root := Node3D.new()
	grass_root.name = "GrassStrips"
	parent.add_child(grass_root)
	## Dense MultiMesh grass near hubs + along roads (LOD: only travel corridors).
	var hubs := [
		GrasslandLayout.PLEASANT_PARK,
		GrasslandLayout.SALTY_SPRINGS,
		GrasslandLayout.RISKY_REELS,
		GrasslandLayout.FATAL_FIELDS,
	]
	for i in hubs.size():
		_grass_patch(grass_root, hubs[i], 28.0, 420, i * 11)
		_grass_patch(grass_root, hubs[i] + Vector3(18, 0, -12), 16.0, 220, i * 19 + 3)
	for path in RegionMapCatalog.road_polylines():
		for i in range(1, path.size()):
			var mid: Vector3 = path[i - 1].lerp(path[i], 0.5)
			var perp := _perp(path[i - 1], path[i])
			_grass_patch(grass_root, mid + perp * 10.0, 12.0, 180, i * 7)
			_grass_patch(grass_root, mid - perp * 10.0, 12.0, 160, i * 9 + 1)
			if i % 2 == 0:
				_flower_scatter(grass_root, mid + perp * 14.0, i)


static func _grass_patch(parent: Node3D, center: Vector3, radius: float, count: int, seed_i: int) -> void:
	## Individual blade-like boxes via MultiMesh — cheap, readable on handheld.
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassMM_%d" % seed_i
	mmi.position = center
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	var blade := BoxMesh.new()
	blade.size = Vector3(0.06, 0.35, 0.04)
	mm.mesh = blade
	var mat := StylizedMesh.make_material(WorldPalette.GRASS_LIGHT if seed_i % 2 == 0 else WorldPalette.LEAF, 1.0, 0.0, 0.0, &"leaf")
	mmi.material_override = mat
	mmi.multimesh = mm
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_i) * 9973 + 17
	for i in count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var x := cos(a) * r
		var z := sin(a) * r
		var h := 0.22 + rng.randf() * 0.45
		var lean := rng.randf_range(-0.25, 0.25)
		var xf := Transform3D.IDENTITY
		xf = xf.scaled(Vector3(1.0, h / 0.35, 1.0))
		xf = xf.rotated(Vector3.UP, a)
		xf = xf.rotated(Vector3.RIGHT, lean)
		xf.origin = Vector3(x, h * 0.5, z)
		mm.set_instance_transform(i, xf)
	parent.add_child(mmi)
	## Dirt / density variation under the patch.
	if seed_i % 3 == 0:
		StylizedMesh.add_box(parent, Vector3(radius * 0.5, 0.03, radius * 0.35), WorldPalette.DIRT.lightened(0.05), center + Vector3(2, 0.02, -1), "DirtVar_%d" % seed_i, false, 1.0, &"dirt")


static func _flower_scatter(parent: Node3D, center: Vector3, seed_i: int) -> void:
	for i in 5:
		var ang := float(i) * 1.4 + float(seed_i)
		var p := center + Vector3(cos(ang) * (1.5 + float(i)), 0.0, sin(ang) * (1.2 + float(i % 3)))
		StylizedMesh.add_box(parent, Vector3(0.08, 0.2, 0.08), WorldPalette.LEAF_DARK, p + Vector3(0, 0.1, 0), "Stem")
		var fc := WorldPalette.FLOWER if i % 2 == 0 else WorldPalette.FLOWER_Y
		StylizedMesh.add_box(parent, Vector3(0.18, 0.18, 0.18), fc, p + Vector3(0, 0.28, 0), "Bloom")


static func _build_special_clearings(parent: Node3D) -> void:
	## Named exploration pockets between POIs.
	var pine := Node3D.new()
	pine.name = "PineHollow"
	pine.position = Vector3(420.0, 0.0, 520.0)
	parent.add_child(pine)
	_clearing(pine, Vector3.ZERO, 101)
	for j in 8:
		_pixel_tree(pine, Vector3(cos(float(j)) * 14.0, 0, sin(float(j)) * 14.0), 1.05, 200 + j)
	RegionPropKit.add_discoverable(pine, &"pine_hollow", "Pine Hollow", Vector3(0, 0.6, 0), 14, "A quiet ring of pines — the road noise fades.")
	result_chest_safe(pine, "PineHollowChest", Vector3(2, 0, -2))

	var meadow := Node3D.new()
	meadow.name = "MeadowClearing"
	meadow.position = Vector3(1780.0, 0.0, -1680.0)
	parent.add_child(meadow)
	StylizedMesh.add_box(meadow, Vector3(22, 0.05, 18), WorldPalette.GRASS_LIGHT, Vector3(0, 0.03, 0), "Meadow", false, 1.0, &"grass")
	_flower_scatter(meadow, Vector3(0, 0, 0), 44)
	_flower_scatter(meadow, Vector3(4, 0, 3), 45)
	_tree_clump(meadow, Vector3(-10, 0, 0), 4, 88)
	_tree_clump(meadow, Vector3(10, 0, -2), 4, 89)
	RegionPropKit.add_discoverable(meadow, &"meadow_clearing", "Meadow Clearing", Vector3(0, 0.6, 0), 12, "Wildflowers lean toward Risky Reels.")


static func result_chest_safe(parent: Node3D, chest_name: String, pos: Vector3) -> void:
	RegionPropKit.build_chest(parent, chest_name, pos, ChestInteractable.Rarity.NORMAL, 24.0, "Search the hollow")


static func _perp(a: Vector3, b: Vector3) -> Vector3:
	var d := (b - a).normalized()
	return Vector3(-d.z, 0.0, d.x)
