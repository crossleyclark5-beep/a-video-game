class_name GrasslandRegionBuilder
extends RefCounted
## Grassland Region orchestrator — first major Digital Frontier chapter.
## Builds Pleasant Park + Salty Springs + Fatal Fields + Risky Reels
## with sparse scenic corridors between them.
##
## Contracts (unchanged shape):
##   player_spawn, chests[], enterable_houses[]
## Extra keys:
##   expansion_points[], poi_centers{}


static func build(root: Node3D) -> Dictionary:
	var result := {
		&"player_spawn": Vector3(0.0, 0.15, 18.0),
		&"chests": [],
		&"enterable_houses": [],
		&"expansion_points": [],
		&"poi_centers": {
			&"pleasant_park": GrasslandLayout.PLEASANT_PARK,
			&"salty_springs": GrasslandLayout.SALTY_SPRINGS,
			&"risky_reels": GrasslandLayout.RISKY_REELS,
			&"fatal_fields": GrasslandLayout.FATAL_FIELDS,
		},
	}

	_add_region_ground(root)
	_add_pleasant_park(root, result)
	SaltySpringsBuilder.build_at(root, GrasslandLayout.SALTY_SPRINGS, result)
	FatalFieldsBuilder.build_at(root, GrasslandLayout.FATAL_FIELDS, result)
	RiskyReelsBuilder.build_at(root, GrasslandLayout.RISKY_REELS, result)
	RegionCorridorBuilder.build_all(root, result)
	_add_expansion_points(root, result)
	_add_region_welcome(root)
	return result


static func _add_region_ground(root: Node3D) -> void:
	## One cheap mega-plane so corridors never fall into void. Dense detail lives in POIs.
	var terrain := Node3D.new()
	terrain.name = "GrasslandTerrain"
	root.add_child(terrain)
	var center := (GrasslandLayout.REGION_MIN + GrasslandLayout.REGION_MAX) * 0.5
	var size := GrasslandLayout.REGION_MAX - GrasslandLayout.REGION_MIN
	StylizedMesh.add_box(
		terrain,
		Vector3(size.x + 200.0, 0.2, size.z + 200.0),
		WorldPalette.GRASS,
		Vector3(center.x, -0.18, center.z),
		"RegionGround",
		true,
		1.0,
		&"grass",
	)
	## Soft color variation patches far from hubs (cheap read of rolling countryside).
	var patches := [
		[Vector3(600, 0.01, 800), Vector3(180, 0.04, 140), WorldPalette.GRASS_LIGHT, &"grass"],
		[Vector3(400, 0.01, 2800), Vector3(200, 0.04, 160), WorldPalette.GRASS_DARK, &"grass"],
		[Vector3(1600, 0.01, -1400), Vector3(160, 0.04, 180), WorldPalette.LEAF_LIT, &"grass"],
		[Vector3(200, 0.01, 3600), Vector3(220, 0.04, 150), WorldPalette.SAND.darkened(0.15), &"dirt"],
		[Vector3(900, 0.015, 1500), Vector3(90, 0.03, 70), WorldPalette.DIRT.lightened(0.05), &"dirt"],
		[Vector3(1400, 0.015, -800), Vector3(70, 0.03, 90), WorldPalette.PATH, &"path"],
	]
	for i in patches.size():
		var p: Array = patches[i]
		StylizedMesh.add_box(terrain, p[1], p[2], p[0], "CountryPatch_%d" % i, false, 1.0, p[3])


static func _add_pleasant_park(root: Node3D, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "PleasantPark"
	hub.position = GrasslandLayout.PLEASANT_PARK
	root.add_child(hub)
	var local: Dictionary = PleasantParkBuilder.build(hub)
	## Preserve starter spawn (world == local while Park is at origin).
	if local.has(&"player_spawn"):
		result[&"player_spawn"] = hub.to_global(local[&"player_spawn"])
		result[&"player_spawn"].y = 0.15
	for chest in local.get(&"chests", []):
		result[&"chests"].append(chest)
	for house in local.get(&"enterable_houses", []):
		result[&"enterable_houses"].append(house)


static func _add_expansion_points(root: Node3D, result: Dictionary) -> void:
	var expand := Node3D.new()
	expand.name = "ExpansionPoints"
	root.add_child(expand)
	var specs := [
		{"id": &"expand_north", "pos": GrasslandLayout.EXPAND_NORTH, "label": "HIGHLANDS AHEAD"},
		{"id": &"expand_east", "pos": GrasslandLayout.EXPAND_EAST, "label": "COAST ROAD"},
		{"id": &"expand_west", "pos": GrasslandLayout.EXPAND_WEST, "label": "STORM PRAIRIE"},
		{"id": &"expand_south", "pos": GrasslandLayout.EXPAND_SOUTH, "label": "SOUTH GATE"},
	]
	for spec in specs:
		var m := Marker3D.new()
		m.name = String(spec["id"])
		m.position = spec["pos"]
		expand.add_child(m)
		result[&"expansion_points"].append(m)
		StylizedMesh.add_box(expand, Vector3(1.2, 2.8, 0.2), WorldPalette.METAL, spec["pos"] + Vector3(0, 1.4, 0), "GatePost", true)
		var label := Label3D.new()
		label.text = String(spec["label"])
		label.font_size = 48
		label.position = spec["pos"] + Vector3(0, 3.2, 0)
		label.modulate = WorldPalette.UI_PAPER
		expand.add_child(label)
		RegionPropKit.add_discoverable(
			expand,
			spec["id"],
			String(spec["label"]).capitalize(),
			spec["pos"] + Vector3(0, 0.6, 1.5),
			8,
			"A future path out of the Grassland — not open yet.",
		)


static func _add_region_welcome(root: Node3D) -> void:
	## Soft region-level discovery near spawn so the Field Unit can name the chapter.
	RegionPropKit.add_discoverable(
		root,
		&"grassland_region",
		"Grassland Region",
		Vector3(0, 0.5, 22),
		10,
		"Chapter One: rolling hills, quiet towns, and roads that go somewhere.",
	)
