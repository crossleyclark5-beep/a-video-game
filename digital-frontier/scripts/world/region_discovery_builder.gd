class_name RegionDiscoveryBuilder
extends RefCounted
## Minor + secret points of interest — environmental storytelling off the mini-map.
## Major landmarks stay in RegionMapCatalog; these only appear when the player finds them.


static func build(root: Node3D, result: Dictionary) -> void:
	var disc := Node3D.new()
	disc.name = "RegionDiscoveries"
	root.add_child(disc)
	_build_minor_sites(disc, result)
	_build_secret_sites(disc, result)
	_build_viewpoints(disc)
	_build_creature_nests(disc)
	_build_ruined_structures(disc, result)


static func _snap(pos: Vector3) -> Vector3:
	return GrasslandHeightField.snap(pos)


static func _build_minor_sites(parent: Node3D, result: Dictionary) -> void:
	## Off-map discoveries — curiosity stops along travel.
	var sites := [
		{
			"id": &"abandoned_camp",
			"name": "Abandoned Camp",
			"pos": Vector3(380, 0, 520),
			"bits": 8,
			"msg": "Cold ash and a torn map scrap — someone left in a hurry.",
			"kind": &"camp",
		},
		{
			"id": &"stone_circle",
			"name": "Stone Circle",
			"pos": Vector3(-180, 0, -520),
			"bits": 10,
			"msg": "Eight stones lean toward the north pass like a quiet compass.",
			"kind": &"stones",
		},
		{
			"id": &"broken_wagon",
			"name": "Broken Wagon",
			"pos": Vector3(980, 0, 340),
			"bits": 7,
			"msg": "Axle snapped. Hex shards glitter in the grass.",
			"kind": &"wreck",
		},
		{
			"id": &"willow_pond",
			"name": "Willow Pond",
			"pos": Vector3(450, 0, 600),
			"bits": 9,
			"msg": "A pocket lake mirrors the clouds — fish flicker below.",
			"kind": &"pond",
		},
		{
			"id": &"ridge_bench",
			"name": "Ridge Bench",
			"pos": Vector3(-300, 0, 40),
			"bits": 6,
			"msg": "Someone carved initials into the armrest years ago.",
			"kind": &"viewpoint",
		},
		{
			"id": &"hay_ruin",
			"name": "Collapsed Barn",
			"pos": Vector3(2900, 0, 3000),
			"bits": 8,
			"msg": "Roof gone. Swallows nest in the rafters.",
			"kind": &"ruin",
		},
		{
			"id": &"signal_tower",
			"name": "Old Signal Tower",
			"pos": Vector3(150, 0, -2400),
			"bits": 12,
			"msg": "A rusted ladder still reaches the platform — the view runs forever.",
			"kind": &"tower",
		},
		{
			"id": &"moss_cave_trail",
			"name": "Moss Cave",
			"pos": Vector3(900, 0, -200),
			"bits": 11,
			"msg": "Damp air and soft green light spill from the mouth.",
			"kind": &"cave",
		},
		{
			"id": &"echo_cave_trail",
			"name": "Echo Cave",
			"pos": Vector3(-500, 0, 900),
			"bits": 11,
			"msg": "A shout comes back three times — something answers on the fourth.",
			"kind": &"cave",
		},
		{
			"id": &"dust_cave_trail",
			"name": "Dust Cave",
			"pos": Vector3(2200, 0, 1600),
			"bits": 11,
			"msg": "Boot prints vanish into dark powder.",
			"kind": &"cave",
		},
		{
			"id": &"lone_oak",
			"name": "Lone Oak",
			"pos": Vector3(1600, 0, 50),
			"bits": 6,
			"msg": "One tree claims the whole meadow like a green lighthouse.",
			"kind": &"grove",
		},
		{
			"id": &"fisherman_dock",
			"name": "Fisherman Dock",
			"pos": Vector3(-320, 0, -600),
			"bits": 8,
			"msg": "A half-sunken pier and a bucket of empty hooks.",
			"kind": &"pond",
		},
		{
			"id": &"glider_wreck",
			"name": "Crashed Glider",
			"pos": Vector3(700, 0, -1400),
			"bits": 14,
			"msg": "Fabric wings tangled in brush — someone tried the sky too soon.",
			"kind": &"wreck",
		},
		{
			"id": &"flower_shelf",
			"name": "Flower Shelf",
			"pos": Vector3(400, 0, 1600),
			"bits": 7,
			"msg": "A natural terrace painted with wild blooms.",
			"kind": &"viewpoint",
		},
		{
			"id": &"boulder_arch",
			"name": "Boulder Arch",
			"pos": Vector3(-1100, 0, 500),
			"bits": 9,
			"msg": "Two rocks lean into a doorway only the wind uses.",
			"kind": &"stones",
		},
	]
	for i in sites.size():
		var s: Dictionary = sites[i]
		var node := Node3D.new()
		node.name = String(s["id"]).capitalize().replace(" ", "")
		node.position = _snap(s["pos"])
		parent.add_child(node)
		_dress_site(node, StringName(s["kind"]), i)
		RegionPropKit.add_discoverable(node, s["id"], String(s["name"]), Vector3(0, 0.6, 0), int(s["bits"]), String(s["msg"]))
		if i % 5 == 0:
			result[&"chests"].append(
				RegionPropKit.build_chest(node, "MinorChest_%d" % i, Vector3(1.5, 0, -1.2), ChestInteractable.Rarity.NORMAL, 48.0, "Search the stash")
			)


static func _build_secret_sites(parent: Node3D, result: Dictionary) -> void:
	## Only found by exploring — no map markers.
	var secrets := [
		{
			"id": &"secret_grove",
			"name": "Secret Grove",
			"pos": Vector3(-60, 0, 420),
			"bits": 18,
			"msg": "The canopy seals out the road. Hex moths drift like embers.",
		},
		{
			"id": &"buried_cache",
			"name": "Buried Cache",
			"pos": Vector3(1250, 0, -350),
			"bits": 20,
			"msg": "A loose stone hides a Field Unit crate stamped CLASSIFIED.",
		},
		{
			"id": &"sky_altar",
			"name": "Sky Altar",
			"pos": Vector3(2100, 0, 2700),
			"bits": 22,
			"msg": "A flat rock faces the bluffs — perfect for watching storms roll in.",
		},
		{
			"id": &"hollow_log_cache",
			"name": "Hollow Log",
			"pos": Vector3(240, 0, -780),
			"bits": 15,
			"msg": "Something digital nested here. Warm resin still glows.",
		},
		{
			"id": &"forgotten_well",
			"name": "Forgotten Well",
			"pos": Vector3(-750, 0, 1100),
			"bits": 16,
			"msg": "The rope is new. The stone is older than the towns.",
		},
	]
	for i in secrets.size():
		var s: Dictionary = secrets[i]
		var node := Node3D.new()
		node.name = "Secret_%s" % String(s["id"])
		node.position = _snap(s["pos"])
		parent.add_child(node)
		match i:
			0:
				_dress_site(node, &"grove", 100 + i)
			1:
				StylizedMesh.add_box(node, Vector3(1.2, 0.4, 1.2), WorldPalette.ROCK, Vector3(0, 0.2, 0), "Stone", true, 1.0, &"dirt")
				StylizedMesh.add_box(node, Vector3(0.7, 0.35, 0.7), WorldPalette.METAL.darkened(0.2), Vector3(0, 0.45, 0), "Cache", false, 1.0, &"brick")
			2:
				_dress_site(node, &"viewpoint", 100 + i)
			3:
				StylizedMesh.add_box(node, Vector3(2.4, 0.5, 0.6), WorldPalette.TRUNK, Vector3(0, 0.25, 0), "Log", false, 1.0, &"wood")
				StylizedMesh.add_box(node, Vector3(0.35, 0.25, 0.35), Color(0.4, 0.85, 0.55), Vector3(0.4, 0.45, 0), "Glow", false, 1.0, &"leaf")
			_:
				StylizedMesh.add_box(node, Vector3(1.6, 0.35, 1.6), WorldPalette.ROCK, Vector3(0, 0.1, 0), "Rim", true, 1.0, &"dirt")
				StylizedMesh.add_box(node, Vector3(0.9, 1.4, 0.9), Color(0.1, 0.12, 0.14), Vector3(0, 0.2, 0), "Shaft")
		RegionPropKit.add_discoverable(node, s["id"], String(s["name"]), Vector3(0, 0.7, 0), int(s["bits"]), String(s["msg"]))
		if i <= 1:
			result[&"chests"].append(
				RegionPropKit.build_chest(node, "SecretChest_%d" % i, Vector3(0.8, 0, 1.0), ChestInteractable.Rarity.RARE, 0.0, "Claim the secret")
			)


static func _build_viewpoints(parent: Node3D) -> void:
	var views := [
		{"id": &"west_foothill_view", "name": "West Foothill View", "pos": Vector3(-240, 0, 120), "msg": "Pleasant Park sits in a green bowl below."},
		{"id": &"mere_approach_view", "name": "Mere Approach View", "pos": Vector3(1000, 0, -1000), "msg": "Water flashes between the trees."},
		{"id": &"fields_rise_view", "name": "Fields Rise View", "pos": Vector3(2600, 0, 2900), "msg": "Barn roofs and dust roads stitch the southeast."},
		{"id": &"reels_lookout", "name": "Reels Lookout", "pos": Vector3(60, 0, -3000), "msg": "The drive-in screen is a pale rectangle on the horizon."},
	]
	for i in views.size():
		var v: Dictionary = views[i]
		var node := Node3D.new()
		node.name = String(v["id"]).capitalize().replace(" ", "")
		node.position = _snap(v["pos"])
		parent.add_child(node)
		_dress_site(node, &"viewpoint", 200 + i)
		RegionPropKit.add_discoverable(node, v["id"], String(v["name"]), Vector3(0, 0.6, 0), 8, String(v["msg"]))


static func _build_creature_nests(parent: Node3D) -> void:
	var nests := [
		{"id": &"rabbit_warren", "name": "Rabbit Warren", "pos": Vector3(180, 0, 240), "msg": "Fresh diggings — cotton rabbits den here at dusk."},
		{"id": &"bird_cliff", "name": "Bird Cliff", "pos": Vector3(-200, 0, -180), "msg": "Nests cling to the rock face. Meadow birds wheel above."},
		{"id": &"boar_wallow", "name": "Boar Wallow", "pos": Vector3(1050, 0, 700), "msg": "Mud churned by tusks. Thorn boars visit after rain."},
		{"id": &"bat_crack", "name": "Bat Crack", "pos": Vector3(320, 0, 1100), "msg": "A thin fissure breathes cool air — byte bats sleep inside."},
	]
	for i in nests.size():
		var n: Dictionary = nests[i]
		var node := Node3D.new()
		node.name = String(n["id"]).capitalize().replace(" ", "")
		node.position = _snap(n["pos"])
		parent.add_child(node)
		StylizedMesh.add_box(node, Vector3(2.2, 0.25, 2.0), WorldPalette.DIRT.darkened(0.1), Vector3(0, 0.08, 0), "Dirt", false, 1.0, &"dirt")
		StylizedMesh.add_box(node, Vector3(0.8, 0.35, 0.8), WorldPalette.ROCK, Vector3(0.6, 0.2, -0.4), "Rock", false, 1.0, &"dirt")
		StylizedMesh.add_box(node, Vector3(0.4, 0.2, 0.4), WorldPalette.LEAF_DARK, Vector3(-0.5, 0.15, 0.5), "Litter", false, 1.0, &"leaf")
		RegionPropKit.add_discoverable(node, n["id"], String(n["name"]), Vector3(0, 0.5, 0), 7, String(n["msg"]))


static func _build_ruined_structures(parent: Node3D, result: Dictionary) -> void:
	var ruins := [
		{"id": &"watch_hut", "name": "Watch Hut", "pos": Vector3(550, 0, -900), "msg": "Four posts and no roof — a ranger hut gone soft."},
		{"id": &"shrine_stub", "name": "Shrine Stub", "pos": Vector3(1700, 0, -200), "msg": "Only the plinth remains. Offerings of flowers still appear."},
		{"id": &"fence_maze", "name": "Fence Maze", "pos": Vector3(3100, 0, 3400), "msg": "Broken rails form a puzzle only cattle understand."},
	]
	for i in ruins.size():
		var r: Dictionary = ruins[i]
		var node := Node3D.new()
		node.name = String(r["id"]).capitalize().replace(" ", "")
		node.position = _snap(r["pos"])
		parent.add_child(node)
		_dress_site(node, &"ruin", 300 + i)
		RegionPropKit.add_discoverable(node, r["id"], String(r["name"]), Vector3(0, 0.6, 0), 9, String(r["msg"]))
		if i == 1:
			result[&"chests"].append(
				RegionPropKit.build_chest(node, "ShrineChest", Vector3(0, 0, 1.2), ChestInteractable.Rarity.NORMAL, 72.0, "Search the plinth")
			)


static func _dress_site(node: Node3D, kind: StringName, seed_i: int) -> void:
	match kind:
		&"camp":
			StylizedMesh.add_box(node, Vector3(2.6, 0.04, 2.6), WorldPalette.DIRT, Vector3(0, 0.02, 0), "Pad", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(0.8, 0.25, 0.8), WorldPalette.ROCK, Vector3(0, 0.15, 0), "Fire", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(1.4, 0.9, 0.1), WorldPalette.WOOD, Vector3(1.2, 0.5, -0.8), "LeanTo", false, 1.0, &"wood")
		&"stones":
			for j in 6:
				var ang := float(j) * TAU / 6.0
				StylizedMesh.add_box(node, Vector3(0.55, 0.9 + float(j % 3) * 0.15, 0.4), WorldPalette.ROCK, Vector3(cos(ang) * 2.2, 0.45, sin(ang) * 2.2), "Stone_%d" % j, true, 1.0, &"dirt")
		&"wreck":
			StylizedMesh.add_box(node, Vector3(2.8, 0.7, 1.4), WorldPalette.WOOD.darkened(0.15), Vector3(0, 0.4, 0), "Hull", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.9, 0.15, 2.2), WorldPalette.METAL.darkened(0.25), Vector3(0.2, 0.9, 0), "Wing", false, 1.0, &"brick")
			StylizedMesh.add_box(node, Vector3(0.4, 0.4, 0.4), WorldPalette.METAL, Vector3(-1.0, 0.3, 0.6), "Gear", false, 1.0, &"brick")
		&"pond":
			StylizedMesh.add_box(node, Vector3(6, 0.08, 5), WorldPalette.DIRT.darkened(0.1), Vector3(0, -0.05, 0), "Bed", false, 1.0, &"dirt")
			var water := MeshInstance3D.new()
			water.name = "Water"
			var wm := BoxMesh.new()
			wm.size = Vector3(5.2, 0.06, 4.2)
			water.mesh = wm
			water.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
			water.position = Vector3(0, 0.03, 0)
			node.add_child(water)
			RegionPropKit.attach_living_water(water, Vector3(4.8, 0.05, 3.8))
		&"viewpoint":
			StylizedMesh.add_box(node, Vector3(2.4, 0.2, 1.2), WorldPalette.ROCK.lightened(0.05), Vector3(0, 0.12, 0), "Shelf", true, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(1.6, 0.12, 0.4), WorldPalette.WOOD, Vector3(0, 0.35, 0), "Bench", false, 1.0, &"wood")
		&"ruin":
			StylizedMesh.add_box(node, Vector3(3.5, 1.8, 0.3), WorldPalette.WOOD.darkened(0.2), Vector3(0, 0.9, -1.2), "Wall", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.3, 1.6, 2.8), WorldPalette.WOOD.darkened(0.15), Vector3(-1.6, 0.8, 0), "WallB", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(1.0, 0.5, 1.0), WorldPalette.ROCK, Vector3(0.8, 0.25, 0.6), "Rubble", false, 1.0, &"dirt")
		&"tower":
			StylizedMesh.add_box(node, Vector3(1.2, 6.0, 1.2), WorldPalette.WOOD.darkened(0.1), Vector3(0, 3.0, 0), "Mast", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(2.4, 0.2, 2.4), WorldPalette.WOOD, Vector3(0, 5.8, 0), "Deck", true, 1.0, &"wood")
			StylizedMesh.add_box(node, Vector3(0.15, 2.5, 0.4), WorldPalette.WOOD.darkened(0.2), Vector3(0.7, 1.2, 0), "Ladder", false, 1.0, &"wood")
		&"cave":
			StylizedMesh.add_box(node, Vector3(1.0, 1.4, 0.4), WorldPalette.ROCK, Vector3(-1.2, 0.7, 1.5), "FrameL", false, 1.0, &"dirt")
			StylizedMesh.add_box(node, Vector3(1.0, 1.4, 0.4), WorldPalette.ROCK, Vector3(1.2, 0.7, 1.5), "FrameR", false, 1.0, &"dirt")
		&"grove":
			for j in 5:
				var ang := float(j) * TAU / 5.0 + float(seed_i) * 0.1
				StylizedMesh.add_box(node, Vector3(0.35, 2.0, 0.35), WorldPalette.TRUNK, Vector3(cos(ang) * 3.5, 1.0, sin(ang) * 3.5), "Trunk_%d" % j, false, 1.0, &"wood")
				StylizedMesh.add_box(node, Vector3(1.6, 1.2, 1.6), WorldPalette.LEAF_DARK, Vector3(cos(ang) * 3.5, 2.4, sin(ang) * 3.5), "Canopy_%d" % j, false, 1.0, &"leaf")
		_:
			StylizedMesh.add_box(node, Vector3(1.0, 0.4, 1.0), WorldPalette.ROCK, Vector3(0, 0.2, 0), "Mark", false, 1.0, &"dirt")
