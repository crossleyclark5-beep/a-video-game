class_name RegionCorridorBuilder
extends RefCounted
## Sparse travel corridors between Grassland POIs — journey content, not dense towns.


static func build_all(root: Node3D, result: Dictionary) -> void:
	var corridors := Node3D.new()
	corridors.name = "Corridors"
	root.add_child(corridors)
	_build_path(corridors, result, "ToSaltySprings", GrasslandLayout.path_park_to_salty(), WorldPalette.PATH, true)
	_build_path(corridors, result, "ToRiskyReels", GrasslandLayout.path_park_to_reels(), WorldPalette.ROAD, false)
	_build_path(corridors, result, "ToFatalFields", GrasslandLayout.path_park_to_fields(), WorldPalette.DIRT, true)
	_add_journey_landmarks(corridors, result)


static func _build_path(
	parent: Node3D,
	result: Dictionary,
	path_name: String,
	points: Array[Vector3],
	surface: Color,
	dirt_style: bool,
) -> void:
	var path_root := Node3D.new()
	path_root.name = path_name
	parent.add_child(path_root)
	var pattern: StringName = &"dirt" if dirt_style else &"asphalt"
	if dirt_style and path_name.begins_with("ToSalty"):
		pattern = &"path"
	for i in range(1, points.size()):
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		_road_segment(path_root, a, b, surface, pattern, i)
		## Occasional tree clumps + meadow patches along the shoulder.
		if i % 2 == 0:
			_shoulder_forest(path_root, a, b, i)
		if i % 3 == 0:
			_meadow_patch(path_root, a.lerp(b, 0.5) + _perp(a, b) * 18.0, i)
	## Midpoint secret every major road.
	var mid_idx := points.size() / 2
	var mid: Vector3 = points[mid_idx]
	var chest := RegionPropKit.build_chest(
		path_root,
		"%s_WaysideChest" % path_name,
		mid + _perp(points[maxi(mid_idx - 1, 0)], mid) * 12.0,
		ChestInteractable.Rarity.NORMAL if dirt_style else ChestInteractable.Rarity.RARE,
		24.0,
		"Search the wayside",
	)
	result[&"chests"].append(chest)


static func _road_segment(parent: Node3D, a: Vector3, b: Vector3, color: Color, pattern: StringName, idx: int) -> void:
	var mid := a.lerp(b, 0.5)
	var length := a.distance_to(b)
	var dir := (b - a).normalized()
	var yaw := atan2(dir.x, dir.z)
	var ground := StylizedMesh.add_box(
		parent,
		Vector3(22.0, 0.08, length + 2.0),
		WorldPalette.GRASS.darkened(0.05),
		mid + Vector3(0, -0.02, 0),
		"Strip_%d" % idx,
		false,
		1.0,
		&"grass",
	)
	ground.rotation.y = yaw
	var road := StylizedMesh.add_box(
		parent,
		Vector3(5.5 if pattern == &"asphalt" else 4.2, 0.06, length + 0.5),
		color,
		mid + Vector3(0, 0.04, 0),
		"Road_%d" % idx,
		true,
		1.0,
		pattern,
	)
	road.rotation.y = yaw
	if pattern == &"asphalt" and length > 40.0:
		var dash := StylizedMesh.add_box(
			parent,
			Vector3(0.18, 0.02, maxf(length * 0.55, 8.0)),
			WorldPalette.ROAD_LINE,
			mid + Vector3(0, 0.08, 0),
			"Dash_%d" % idx,
		)
		dash.rotation.y = yaw


static func _shoulder_forest(parent: Node3D, a: Vector3, b: Vector3, seed_i: int) -> void:
	var mid := a.lerp(b, 0.45)
	var side := _perp(a, b) * (14.0 + float(seed_i % 5) * 3.0)
	var base := mid + side * (1.0 if seed_i % 2 == 0 else -1.0)
	for j in 3:
		var p := base + Vector3(float(j) * 3.5 - 3.5, 0, float((j + seed_i) % 3) * 2.0)
		StylizedMesh.add_box(parent, Vector3(0.32, 1.65, 0.32), WorldPalette.TRUNK, p + Vector3(0, 0.82, 0), "Trunk", false, 1.0, &"wood")
		var leaf_c := WorldPalette.LEAF if j % 2 == 0 else WorldPalette.LEAF_DARK
		StylizedMesh.add_box(parent, Vector3(1.5, 1.15, 1.5), leaf_c, p + Vector3(0, 2.05, 0), "Canopy", false, 1.0, &"leaf")
		StylizedMesh.add_box(parent, Vector3(0.85, 0.7, 0.85), leaf_c.lightened(0.08), p + Vector3(0.35, 2.55, 0.15), "Canopy2", false, 1.0, &"leaf")
		if j == 1:
			StylizedMesh.add_box(parent, Vector3(0.35, 0.2, 0.3), WorldPalette.ROCK, p + Vector3(1.2, 0.12, 0.4), "Rock", false, 1.0, &"dirt")
			StylizedMesh.add_box(parent, Vector3(0.12, 0.28, 0.12), WorldPalette.LEAF_DARK, p + Vector3(-1.0, 0.14, 0.6), "Plant")


static func _meadow_patch(parent: Node3D, pos: Vector3, idx: int) -> void:
	StylizedMesh.add_box(parent, Vector3(16, 0.04, 10), WorldPalette.GRASS_LIGHT, pos + Vector3(0, 0.02, 0), "Meadow_%d" % idx, false, 1.0, &"grass")
	StylizedMesh.add_box(parent, Vector3(5, 0.03, 3.5), WorldPalette.DIRT.lightened(0.05), pos + Vector3(2, 0.03, -1), "Dirt_%d" % idx, false, 1.0, &"dirt")
	for i in 6:
		StylizedMesh.add_box(
			parent,
			Vector3(0.22, 0.22, 0.22),
			WorldPalette.FLOWER if i % 2 == 0 else WorldPalette.FLOWER_Y,
			pos + Vector3(-5 + float(i) * 1.8, 0.22, float(i % 2) * 1.4 - 0.5),
			"Bloom",
		)
		StylizedMesh.add_box(
			parent,
			Vector3(0.1, 0.2, 0.1),
			WorldPalette.LEAF_DARK,
			pos + Vector3(-4.5 + float(i) * 1.8, 0.12, float(i % 2) * 1.4),
			"Stem",
		)


static func _add_journey_landmarks(parent: Node3D, result: Dictionary) -> void:
	## Creek bridge on the NE Reels road.
	var bridge_pos := Vector3(1280.0, 0.0, -1200.0)
	var bridge := Node3D.new()
	bridge.name = "CreekBridge"
	bridge.position = bridge_pos
	parent.add_child(bridge)
	StylizedMesh.add_box(bridge, Vector3(18, 0.2, 8), WorldPalette.WATER, Vector3(0, -0.15, 0), "Creek", false, 1.0, &"dirt")
	var water := MeshInstance3D.new()
	water.name = "Water"
	var wm := BoxMesh.new()
	wm.size = Vector3(16, 0.08, 6.5)
	water.mesh = wm
	water.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
	water.position = Vector3(0, 0.02, 0)
	bridge.add_child(water)
	StylizedMesh.add_box(bridge, Vector3(8, 0.25, 10), WorldPalette.WOOD, Vector3(0, 0.2, 0), "Deck", true, 1.0, &"wood")
	StylizedMesh.add_box(bridge, Vector3(8, 0.7, 0.15), WorldPalette.WOOD.darkened(0.1), Vector3(0, 0.55, 4.8), "RailA", false, 1.0, &"wood")
	StylizedMesh.add_box(bridge, Vector3(8, 0.7, 0.15), WorldPalette.WOOD.darkened(0.1), Vector3(0, 0.55, -4.8), "RailB", false, 1.0, &"wood")
	RegionPropKit.add_discoverable(bridge, &"creek_bridge", "Creek Bridge", Vector3(0, 0.6, 0), 14, "Water whispers under the planks — a favorite shortcut for locals.")

	## Hidden hillside cave on the road down to Salty Springs.
	var cave := Node3D.new()
	cave.name = "HillsideCave"
	cave.position = Vector3(650.0, 0.0, 820.0) + Vector3(18, 0, -16)
	parent.add_child(cave)
	StylizedMesh.add_box(cave, Vector3(8, 4, 6), WorldPalette.ROCK, Vector3(0, 1.5, 0), "Hill", true)
	StylizedMesh.add_box(cave, Vector3(2.4, 2.2, 2.0), Color(0.08, 0.08, 0.1), Vector3(0, 1.0, 2.2), "Mouth")
	RegionPropKit.add_discoverable(cave, &"hillside_cave", "Hillside Cave", Vector3(0, 0.8, 3.0), 18, "Cool air and echo — something digital nests deeper in.")
	result[&"chests"].append(
		RegionPropKit.build_chest(cave, "CaveChest", Vector3(0, 0, 0.5), ChestInteractable.Rarity.RARE, 0.0, "Search the cave")
	)

	## Scenic overlook on the south road toward Fatal Fields.
	var view := Node3D.new()
	view.name = "PrairieOverlook"
	view.position = Vector3(680.0, 0.0, 3100.0) + Vector3(25, 0, 0)
	parent.add_child(view)
	StylizedMesh.add_box(view, Vector3(10, 1.2, 6), WorldPalette.ROCK, Vector3(0, 0.4, 0), "Bluff", true)
	StylizedMesh.add_box(view, Vector3(3.5, 0.15, 1.2), WorldPalette.WOOD, Vector3(0, 1.15, 1.5), "Bench", false, 1.0, &"wood")
	RegionPropKit.add_discoverable(view, &"prairie_overlook", "Prairie Overlook", Vector3(0, 1.0, 0), 16, "Fatal Fields stretch south — corn and red barns under a wide sky.")

	## Abandoned billboard before Risky Reels (NE approach).
	var bill := Node3D.new()
	bill.name = "MovieBillboard"
	bill.position = Vector3(2280.0, 0.0, -2200.0)
	parent.add_child(bill)
	StylizedMesh.add_box(bill, Vector3(0.3, 5.5, 0.3), WorldPalette.METAL, Vector3(0, 2.7, 0), "Pole", true)
	StylizedMesh.add_box(bill, Vector3(6.5, 3.2, 0.2), WorldPalette.UI_INK, Vector3(0, 4.5, 0), "Board")
	StylizedMesh.add_box(bill, Vector3(5.8, 2.4, 0.08), WorldPalette.UI_ACCENT, Vector3(0, 4.5, 0.12), "Poster")
	var label := Label3D.new()
	label.text = "NOW SHOWING"
	label.font_size = 72
	label.position = Vector3(0, 4.5, 0.2)
	label.modulate = WorldPalette.UI_PAPER
	bill.add_child(label)
	RegionPropKit.add_discoverable(bill, &"movie_billboard", "Faded Billboard", Vector3(0, 1.0, 1.0), 12, "Tonight's feature never ended — the reels still wait.")

	## Secret path shack south of Park (short side trail).
	var shack := Node3D.new()
	shack.name = "SecretShack"
	shack.position = Vector3(-90.0, 0.0, 220.0)
	parent.add_child(shack)
	StylizedMesh.add_box(shack, Vector3(3.2, 2.4, 3.0), WorldPalette.WOOD, Vector3(0, 1.2, 0), "Shack", true, 1.0, &"wood")
	StylizedMesh.add_box(shack, Vector3(3.6, 0.25, 3.4), WorldPalette.ROOF_RED, Vector3(0, 2.5, 0), "Roof", false, 1.0, &"wood")
	RegionPropKit.add_discoverable(shack, &"secret_shack", "Hidden Shack", Vector3(0, 0.6, 2.0), 20, "Off the map. On purpose.")
	result[&"chests"].append(
		RegionPropKit.build_chest(shack, "ShackChest", Vector3(1.2, 0, -0.5), ChestInteractable.Rarity.LEGENDARY, 0.0, "Pry open the crate")
	)


static func _perp(a: Vector3, b: Vector3) -> Vector3:
	var d := (b - a).normalized()
	return Vector3(-d.z, 0.0, d.x)
