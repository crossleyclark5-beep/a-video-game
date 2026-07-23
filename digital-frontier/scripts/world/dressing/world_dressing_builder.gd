class_name WorldDressingBuilder
extends RefCounted
## Environmental storytelling & world dressing — rule-based, biome-aware, off-map discovery.
## Volume stays MultiMesh; meaning stays sparse Node3D vignettes.


static func build(root: Node3D, result: Dictionary) -> void:
	var dress := Node3D.new()
	dress.name = "WorldDressing"
	root.add_child(dress)
	var rules := BiomeDressingRules.grassland()
	_build_meadow_dressing(dress, rules)
	_build_forest_understory(dress, rules)
	_build_animal_trails(dress, rules)
	_build_micro_stories(dress, result, rules)
	_build_natural_landmarks(dress, result)
	_build_viewpoints(dress, result, rules)
	_build_path_guidance(dress, rules)
	print("WORLD_DRESSING_BUILT stories=%d landmarks=%d" % [
		MicroStoryCatalog.grassland_stories().size(),
		MicroStoryCatalog.grassland_landmarks().size(),
	])


## --- Meadows / fields ----------------------------------------------------------------

static func _build_meadow_dressing(parent: Node3D, rules: Dictionary) -> void:
	var meadow := Node3D.new()
	meadow.name = "MeadowDressing"
	parent.add_child(meadow)
	var cfg: Dictionary = rules.get(&"meadow", {})
	var centers: Array[Vector3] = [
		Vector3(300, 0, 80), Vector3(700, 0, -500), Vector3(1200, 0, 500),
		Vector3(-280, 0, 900), Vector3(500, 0, 1700), Vector3(1800, 0, 300),
		Vector3(100, 0, -1400), Vector3(-700, 0, 300), Vector3(2400, 0, 1600),
		Vector3(900, 0, 2600), Vector3(-200, 0, -2200), Vector3(1600, 0, -100),
		Vector3(400, 0, 1100), Vector3(-900, 0, 1100), Vector3(2000, 0, 2400),
		Vector3(60, 0, -600), Vector3(1400, 0, 1400), Vector3(-400, 0, -100),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xDBE55
	var flower_xfs: Array[Transform3D] = []
	var bush_xfs: Array[Transform3D] = []
	var rock_xfs: Array[Transform3D] = []
	var tree_xfs: Array[Transform3D] = []
	for i in centers.size():
		var c: Vector3 = centers[i]
		if not RegionVegetationBuilder.placement_allowed(c, false):
			continue
		## Tall grass patch (MultiMesh)
		_grass_patch(meadow, c, 14.0 + rng.randf() * 6.0, 110 + rng.randi() % 40, 5000 + i)
		## Dirt patch — believable bare ground
		if rng.randf() < float(cfg.get(&"dirt_patch_chance", 0.35)):
			var dirt_p := GrasslandHeightField.snap_y(c + Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-4, 4)), 0.03)
			StylizedMesh.add_box(meadow, Vector3(3.5 + rng.randf() * 2.0, 0.04, 2.8 + rng.randf()), WorldPalette.DIRT.lightened(0.05), dirt_p, "Dirt_%d" % i, false, 1.0, &"dirt")
		## Collect instances for batched MultiMesh
		for j in 8:
			var ang := rng.randf() * TAU
			var r := rng.randf() * 16.0
			var p := c + Vector3(cos(ang) * r, 0, sin(ang) * r)
			if RegionVegetationBuilder.placement_allowed(p, false):
				flower_xfs.append(_xf(p, 0.7 + rng.randf() * 0.5, ang))
		if rng.randf() < float(cfg.get(&"bush_chance", 0.5)):
			for j in 4:
				var ang := rng.randf() * TAU
				var p := c + Vector3(cos(ang) * rng.randf_range(3, 12), 0, sin(ang) * rng.randf_range(3, 12))
				if RegionVegetationBuilder.placement_allowed(p, false):
					bush_xfs.append(_xf(p, 0.5 + rng.randf() * 0.4, ang))
		if rng.randf() < float(cfg.get(&"rock_cluster_chance", 0.4)):
			for j in 3:
				var ang := rng.randf() * TAU
				var p := c + Vector3(cos(ang) * rng.randf_range(2, 10), 0, sin(ang) * rng.randf_range(2, 10))
				if RegionVegetationBuilder.placement_allowed(p, false):
					rock_xfs.append(_xf(p, 0.35 + rng.randf() * 0.35, ang))
		if rng.randf() < float(cfg.get(&"lone_tree_chance", 0.55)):
			var tp := c + Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10))
			if RegionVegetationBuilder.placement_allowed(tp, true):
				tree_xfs.append(_xf(tp, 0.85 + rng.randf() * 0.4, rng.randf() * TAU))
	_emit_mm(meadow, "MeadowFlowers", flower_xfs, _flower_mesh(), WorldPalette.FLOWER)
	_emit_mm(meadow, "MeadowBush", bush_xfs, _bush_mesh(), WorldPalette.BUSH)
	_emit_mm(meadow, "MeadowRock", rock_xfs, _rock_mesh(), WorldPalette.ROCK)
	_emit_mm(meadow, "MeadowLoneTrees", tree_xfs, _tree_mesh(), WorldPalette.LEAF)


## --- Forest understory (clustering rules on top of DenseForests) ----------------------

static func _build_forest_understory(parent: Node3D, rules: Dictionary) -> void:
	var forest := Node3D.new()
	forest.name = "ForestUnderstory"
	parent.add_child(forest)
	var cfg: Dictionary = rules.get(&"forest", {})
	var anchors: Array[Vector3] = [
		Vector3(200, 0, 350), Vector3(-250, 0, 280), Vector3(450, 0, -250),
		Vector3(900, 0, 200), Vector3(300, 0, 1200), Vector3(-100, 0, -900),
		Vector3(1400, 0, -600), Vector3(-800, 0, 600), Vector3(600, 0, -1600),
		Vector3(1100, 0, 1600), Vector3(-400, 0, -400), Vector3(2800, 0, 1200),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xF0BE57
	var mush_xfs: Array[Transform3D] = []
	var moss_xfs: Array[Transform3D] = []
	for i in anchors.size():
		var c: Vector3 = anchors[i]
		if not RegionVegetationBuilder.placement_allowed(c, true):
			continue
		## Intentional clearing oval
		if rng.randf() < float(cfg.get(&"clearing_chance", 0.22)):
			var clear_p := GrasslandHeightField.snap_y(c, 0.03)
			StylizedMesh.add_box(forest, Vector3(10, 0.04, 8), WorldPalette.GRASS_LIGHT, clear_p, "Clearing_%d" % i, false, 1.0, &"grass")
		if rng.randf() < float(cfg.get(&"fallen_log_chance", 0.35)):
			_fallen_log(forest, c + Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3)), 6000 + i)
		for j in 6:
			var ang := rng.randf() * TAU
			var p := c + Vector3(cos(ang) * rng.randf() * 12.0, 0, sin(ang) * rng.randf() * 12.0)
			if RegionVegetationBuilder.placement_allowed(p, false):
				if rng.randf() < float(cfg.get(&"mushroom_chance", 0.4)):
					mush_xfs.append(_xf(p, 0.8 + rng.randf() * 0.5, ang))
				if rng.randf() < float(cfg.get(&"moss_rock_chance", 0.5)):
					moss_xfs.append(_xf(p + Vector3(1.2, 0, -0.8), 0.4 + rng.randf() * 0.3, ang + 0.4))
		## Soft animal trail dirt strip leaving the clump
		if rng.randf() < float(cfg.get(&"trail_chance", 0.3)):
			_dirt_trail_segment(forest, c, c + Vector3(rng.randf_range(8, 16) * (1 if i % 2 == 0 else -1), 0, rng.randf_range(-6, 6)), 6100 + i)
	_emit_mm(forest, "ForestMushrooms", mush_xfs, _mushroom_mesh(), Color(0.75, 0.35, 0.35))
	_emit_mm(forest, "ForestMossRocks", moss_xfs, _rock_mesh(), WorldPalette.ROCK.darkened(0.08))


## --- Animal trails / path guidance ---------------------------------------------------

static func _build_animal_trails(parent: Node3D, _rules: Dictionary) -> void:
	var trails := Node3D.new()
	trails.name = "AnimalTrails"
	parent.add_child(trails)
	var paths: Array = [
		[Vector3(40, 0, 80), Vector3(160, 0, 300), Vector3(220, 0, 520)],
		[Vector3(-40, 0, -60), Vector3(-120, 0, -280), Vector3(-80, 0, -520)],
		[Vector3(400, 0, 200), Vector3(700, 0, 400), Vector3(1000, 0, 500)],
		[Vector3(200, 0, 900), Vector3(280, 0, 1100), Vector3(300, 0, 1400)],
		[Vector3(900, 0, -200), Vector3(1100, 0, -400), Vector3(1300, 0, -700)],
	]
	for i in paths.size():
		var pts: Array = paths[i]
		for j in range(1, pts.size()):
			_dirt_trail_segment(trails, pts[j - 1], pts[j], 7000 + i * 10 + j)


static func _build_path_guidance(parent: Node3D, rules: Dictionary) -> void:
	## Sparse posts / cairns along road shoulders — invite curiosity off-road.
	var guide := Node3D.new()
	guide.name = "PathGuidance"
	parent.add_child(guide)
	var spacing := float(rules.get(&"trail_marker_spacing_m", 220.0))
	var idx := 0
	for path in RegionMapCatalog.road_polylines():
		var traveled := 0.0
		for i in range(1, path.size()):
			var a: Vector3 = path[i - 1]
			var b: Vector3 = path[i]
			var seg := Vector3(a.x, 0, a.z).distance_to(Vector3(b.x, 0, b.z))
			traveled += seg
			if traveled < spacing:
				continue
			traveled = 0.0
			var mid := a.lerp(b, 0.5)
			var perp := Vector3(-(b.z - a.z), 0, b.x - a.x).normalized()
			var side := mid + perp * (GrasslandLayout.road_clearance() + 6.0) * (1.0 if idx % 2 == 0 else -1.0)
			if not RegionVegetationBuilder.placement_allowed(side, false):
				continue
			_trail_cairn(guide, side, 8000 + idx)
			idx += 1


## --- Micro-stories -------------------------------------------------------------------

static func _build_micro_stories(parent: Node3D, result: Dictionary, rules: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "MicroStories"
	parent.add_child(root)
	var cap: int = int(rules.get(&"micro_story_cap", 28))
	var stories := MicroStoryCatalog.grassland_stories()
	var n := mini(stories.size(), cap)
	for i in n:
		var s: Dictionary = stories[i]
		var pos: Vector3 = s["pos"]
		if not RegionVegetationBuilder.placement_allowed(pos, false) and StringName(s.get("kind", &"")) != &"waterfall":
			## Waterfalls / caves may sit near rock — soft allow if on island.
			if not GrasslandLayout.is_on_island(pos, -60.0):
				continue
		var node := Node3D.new()
		node.name = String(s["id"]).capitalize().replace(" ", "")
		node.position = GrasslandHeightField.snap(pos)
		root.add_child(node)
		WorldDressKit.dress(node, StringName(s.get("kind", &"camp")), i)
		RegionPropKit.add_discoverable(
			node,
			s["id"],
			String(s["name"]),
			Vector3(0, 0.55, 0),
			int(s.get("bits", 8)),
			String(s.get("msg", "")),
		)
		_apply_reward(node, result, StringName(s.get("reward", &"none")), i)


static func _build_natural_landmarks(parent: Node3D, result: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "NaturalLandmarks"
	parent.add_child(root)
	for i in MicroStoryCatalog.grassland_landmarks().size():
		var lm: Dictionary = MicroStoryCatalog.grassland_landmarks()[i]
		var pos: Vector3 = lm["pos"]
		if not GrasslandLayout.is_on_island(pos, -70.0):
			continue
		var node := Node3D.new()
		node.name = String(lm["id"]).capitalize().replace(" ", "")
		node.position = GrasslandHeightField.snap(pos)
		root.add_child(node)
		WorldDressKit.dress(node, StringName(lm.get("kind", &"stones")), 100 + i)
		RegionPropKit.add_discoverable(
			node,
			lm["id"],
			String(lm["name"]),
			Vector3(0, 0.55, 0),
			8,
			"A quiet landmark — no map pin, just the place itself.",
		)
		if i % 3 == 0:
			result[&"chests"].append(
				RegionPropKit.build_chest(node, "LandmarkChest_%d" % i, Vector3(1.2, 0, -1.0), ChestInteractable.Rarity.NORMAL, 60.0, "Search the landmark")
			)


static func _build_viewpoints(parent: Node3D, result: Dictionary, rules: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "ScenicViewpoints"
	parent.add_child(root)
	var cap: int = int(rules.get(&"viewpoint_cap", 10))
	var views := MicroStoryCatalog.grassland_viewpoints()
	for i in mini(views.size(), cap):
		var v: Dictionary = views[i]
		var node := Node3D.new()
		node.name = String(v["id"]).capitalize().replace(" ", "")
		node.position = GrasslandHeightField.snap(v["pos"])
		root.add_child(node)
		WorldDressKit.dress(node, &"viewpoint", 200 + i)
		RegionPropKit.add_discoverable(node, v["id"], String(v["name"]), Vector3(0, 0.55, 0), 6, String(v["msg"]))
		## Viewpoints rarely need loot — one rare cache.
		if i == 2:
			result[&"chests"].append(
				RegionPropKit.build_chest(node, "ViewpointCache", Vector3(-1.0, 0, 0.8), ChestInteractable.Rarity.RARE, 0.0, "Claim the overlook cache")
			)


static func _apply_reward(node: Node3D, result: Dictionary, reward: StringName, seed_i: int) -> void:
	match reward:
		&"chest_normal":
			result[&"chests"].append(
				RegionPropKit.build_chest(node, "StoryChest_%d" % seed_i, Vector3(1.4, 0, -0.8), ChestInteractable.Rarity.NORMAL, 48.0, "Search the story")
			)
		&"chest_rare":
			result[&"chests"].append(
				RegionPropKit.build_chest(node, "StoryRare_%d" % seed_i, Vector3(1.2, 0, -1.0), ChestInteractable.Rarity.RARE, 0.0, "Open the rare cache")
			)
		&"material", &"lore", &"bits":
			## Discoverable bits already grant; add a small supply stash as tangible find.
			RegionPropKit.add_supply_stash(node, Vector3(-1.3, 0, 0.9), float(seed_i * 17 % 360), "StoryStash_%d" % seed_i)
		_:
			pass


## --- Helpers -------------------------------------------------------------------------

static func _grass_patch(parent: Node3D, center: Vector3, radius: float, count: int, seed_i: int) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "DressGrass_%d" % seed_i
	var ground_y := GrasslandHeightField.height_at_v(center)
	mmi.position = Vector3(center.x, ground_y, center.z)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var blade := BoxMesh.new()
	blade.size = Vector3(0.07, 0.42, 0.05)
	mm.mesh = blade
	mmi.material_override = StylizedMesh.make_material(WorldPalette.GRASS_LIGHT if seed_i % 2 == 0 else WorldPalette.LEAF, 1.0, 0.0, 0.0, &"leaf")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_i) * 9133 + 5
	var xfs: Array[Transform3D] = []
	for i in count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var x := cos(a) * r
		var z := sin(a) * r
		var world := center + Vector3(x, 0, z)
		if not RegionVegetationBuilder.placement_allowed(world, false):
			continue
		var local_y := GrasslandHeightField.height_at(world.x, world.z) - ground_y
		var h := 0.28 + rng.randf() * 0.55
		var xf := Transform3D.IDENTITY.scaled(Vector3(1.0, h / 0.42, 1.0))
		xf = xf.rotated(Vector3.UP, a)
		xf.origin = Vector3(x, local_y + h * 0.5, z)
		xfs.append(xf)
	if xfs.is_empty():
		return
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mmi.multimesh = mm
	mmi.visibility_range_end = AdventureNodeBudget.LOD_GRASS_END
	parent.add_child(mmi)


static func _dirt_trail_segment(parent: Node3D, a: Vector3, b: Vector3, seed_i: int) -> void:
	if not GrasslandLayout.is_on_island(a, -40.0) or not GrasslandLayout.is_on_island(b, -40.0):
		return
	var mid := a.lerp(b, 0.5)
	for zone in GrasslandLayout.hub_exclusion_zones():
		var hub: Vector3 = zone["pos"]
		if Vector3(mid.x, 0, mid.z).distance_to(Vector3(hub.x, 0, hub.z)) < float(zone["radius"]) * 0.85:
			return
	var dir := b - a
	var length := Vector3(dir.x, 0, dir.z).length()
	if length < 4.0:
		return
	var yaw := atan2(dir.x, dir.z)
	var holder := Node3D.new()
	holder.name = "Trail_%d" % seed_i
	holder.position = GrasslandHeightField.snap_y(mid, 0.025)
	holder.rotation.y = yaw
	parent.add_child(holder)
	StylizedMesh.add_box(holder, Vector3(1.1, 0.03, length * 0.9), WorldPalette.DIRT.darkened(0.02), Vector3.ZERO, "Dirt", false, 1.0, &"dirt")


static func _fallen_log(parent: Node3D, pos: Vector3, seed_i: int) -> void:
	if not RegionVegetationBuilder.placement_allowed(pos, false):
		return
	var log := Node3D.new()
	log.name = "DressLog_%d" % seed_i
	log.position = GrasslandHeightField.snap(pos)
	log.rotation_degrees.y = float(seed_i * 29 % 360)
	parent.add_child(log)
	StylizedMesh.add_box(log, Vector3(2.6, 0.32, 0.38), WorldPalette.TRUNK.darkened(0.1), Vector3(0, 0.16, 0), "Log", false, 1.0, &"wood")
	StylizedMesh.add_box(log, Vector3(0.4, 0.14, 0.4), WorldPalette.LEAF_DARK, Vector3(0.5, 0.3, 0), "Moss", false, 1.0, &"leaf")


static func _trail_cairn(parent: Node3D, pos: Vector3, seed_i: int) -> void:
	var m := Node3D.new()
	m.name = "Cairn_%d" % seed_i
	m.position = GrasslandHeightField.snap(pos)
	parent.add_child(m)
	StylizedMesh.add_box(m, Vector3(0.45, 0.35, 0.4), WorldPalette.ROCK, Vector3(0, 0.18, 0), "A", false, 1.0, &"dirt")
	StylizedMesh.add_box(m, Vector3(0.32, 0.28, 0.3), WorldPalette.ROCK.lightened(0.05), Vector3(0.05, 0.45, 0), "B", false, 1.0, &"dirt")
	StylizedMesh.add_box(m, Vector3(0.2, 0.22, 0.2), WorldPalette.ROCK.darkened(0.05), Vector3(-0.02, 0.68, 0.02), "C", false, 1.0, &"dirt")


static func _xf(world: Vector3, scale_v: float, yaw: float) -> Transform3D:
	var y := GrasslandHeightField.height_at(world.x, world.z)
	var xf := Transform3D.IDENTITY.scaled(Vector3(scale_v, scale_v, scale_v))
	xf = xf.rotated(Vector3.UP, yaw)
	xf.origin = Vector3(world.x, y, world.z)
	return xf


static func _emit_mm(parent: Node3D, node_name: String, xfs: Array[Transform3D], mesh: Mesh, color: Color) -> void:
	if xfs.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mmi.multimesh = mm
	mmi.material_override = StylizedMesh.make_material(color, 1.0, 0.0, 0.0, &"leaf")
	mmi.visibility_range_end = AdventureNodeBudget.LOD_BUSH_END
	parent.add_child(mmi)


static func _flower_mesh() -> ArrayMesh:
	return _box_cluster([[Vector3(0.12, 0.2, 0.12), Vector3(0, 0.1, 0)], [Vector3(0.22, 0.12, 0.22), Vector3(0, 0.26, 0)]])


static func _bush_mesh() -> ArrayMesh:
	return _box_cluster([[Vector3(1.0, 0.7, 1.0), Vector3(0, 0.35, 0)]])


static func _rock_mesh() -> ArrayMesh:
	return _box_cluster([[Vector3(1.0, 0.55, 0.85), Vector3(0, 0.28, 0)]])


static func _mushroom_mesh() -> ArrayMesh:
	return _box_cluster([[Vector3(0.12, 0.28, 0.12), Vector3(0, 0.14, 0)], [Vector3(0.35, 0.12, 0.35), Vector3(0, 0.32, 0)]])


static func _tree_mesh() -> ArrayMesh:
	return _box_cluster([
		[Vector3(0.3, 1.7, 0.3), Vector3(0, 0.85, 0)],
		[Vector3(1.55, 1.2, 1.55), Vector3(0, 2.15, 0)],
		[Vector3(0.95, 0.85, 0.95), Vector3(0.2, 2.85, 0.1)],
	])


static func _box_cluster(parts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		_append_box(st, part[0], part[1])
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
	var faces := [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0]]
	for f in faces:
		st.add_vertex(verts[f[0]])
		st.add_vertex(verts[f[1]])
		st.add_vertex(verts[f[2]])
		st.add_vertex(verts[f[0]])
		st.add_vertex(verts[f[2]])
		st.add_vertex(verts[f[3]])
