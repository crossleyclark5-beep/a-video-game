class_name RegionTerrainBuilder
extends RefCounted
## Hills, valleys, and mountains with intended climb paths.
## Steep mountain faces block / slide the player; switchback trails are the route up.


static func build(root: Node3D, result: Dictionary) -> void:
	var terrain := Node3D.new()
	terrain.name = "RegionTerrain"
	root.add_child(terrain)
	_build_rolling_hills(terrain)
	_build_west_ridge(terrain, result)
	_build_north_pass(terrain, result)
	_build_south_bluffs(terrain, result)
	_build_valleys(terrain)


static func _build_rolling_hills(parent: Node3D) -> void:
	## Walkable mounds — gentle ramps from multiple sides.
	var hills := [
		{"pos": Vector3(120, 0, 160), "h": 2.4, "r": 14.0},
		{"pos": Vector3(-60, 0, -140), "h": 1.8, "r": 11.0},
		{"pos": Vector3(320, 0, 380), "h": 2.8, "r": 16.0},
		{"pos": Vector3(600, 0, -400), "h": 2.2, "r": 13.0},
		{"pos": Vector3(1100, 0, -900), "h": 2.6, "r": 15.0},
		{"pos": Vector3(750, 0, 1800), "h": 2.0, "r": 12.0},
		{"pos": Vector3(400, 0, 2800), "h": 2.4, "r": 14.0},
		{"pos": Vector3(2000, 0, -1800), "h": 2.2, "r": 13.0},
	]
	for i in hills.size():
		_hill(parent, hills[i]["pos"], float(hills[i]["h"]), float(hills[i]["r"]), i)


static func _hill(parent: Node3D, pos: Vector3, height: float, radius: float, idx: int) -> void:
	var h := Node3D.new()
	h.name = "Hill_%d" % idx
	h.position = pos
	parent.add_child(h)
	## Core mound (collision) + soft visual layers.
	StylizedMesh.add_box(h, Vector3(radius * 1.6, height, radius * 1.6), WorldPalette.GRASS_DARK, Vector3(0, height * 0.5, 0), "Core", true, 1.0, &"grass")
	StylizedMesh.add_box(h, Vector3(radius * 1.1, height * 0.55, radius * 1.1), WorldPalette.GRASS, Vector3(0, height * 0.85, 0), "Cap", false, 1.0, &"grass")
	## Approach ramps (climbable) on 4 sides — pitch ~28°.
	_ramp(h, Vector3(0, height * 0.35, radius * 0.95), Vector3(radius * 1.2, 0.5, radius * 0.9), 28.0, 0.0, "RampS")
	_ramp(h, Vector3(0, height * 0.35, -radius * 0.95), Vector3(radius * 1.2, 0.5, radius * 0.9), -28.0, 0.0, "RampN")
	_ramp(h, Vector3(radius * 0.95, height * 0.35, 0), Vector3(radius * 0.9, 0.5, radius * 1.2), 0.0, 0.0, "RampE", 28.0)
	_ramp(h, Vector3(-radius * 0.95, height * 0.35, 0), Vector3(radius * 0.9, 0.5, radius * 1.2), 0.0, 0.0, "RampW", -28.0)
	## Small plants on crest.
	StylizedMesh.add_box(h, Vector3(0.12, 0.28, 0.12), WorldPalette.LEAF_DARK, Vector3(1.2, height + 0.15, 0.4), "Plant", false, 1.0, &"leaf")


static func _ramp(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	pitch_deg: float,
	yaw_deg: float,
	node_name: String,
	roll_deg: float = 0.0,
) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.rotation_degrees = Vector3(pitch_deg, yaw_deg, roll_deg)
	parent.add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = StylizedMesh.make_material(WorldPalette.GRASS, 1.0, 0.0, 0.0, &"dirt")
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)


static func _build_valleys(parent: Node3D) -> void:
	## Subtle lower dirt channels between hills — reads as valleys without digging mesh.
	var valleys := [
		[Vector3(80, 0.01, 90), Vector3(40, 0.04, 10)],
		[Vector3(500, 0.01, -200), Vector3(60, 0.04, 12)],
		[Vector3(900, 0.01, 2000), Vector3(50, 0.04, 14)],
	]
	for i in valleys.size():
		var v: Array = valleys[i]
		StylizedMesh.add_box(parent, v[1], WorldPalette.DIRT.darkened(0.05), v[0], "Valley_%d" % i, false, 1.0, &"dirt")


static func _build_west_ridge(parent: Node3D, result: Dictionary) -> void:
	## Boundary mountain west of Park — summit only via switchback trail.
	var ridge := Node3D.new()
	ridge.name = "WestRidge"
	ridge.position = Vector3(-420.0, 0.0, 80.0)
	parent.add_child(ridge)
	_mountain_mass(ridge, Vector3(70, 22, 55), WorldPalette.ROCK)
	## Steep cliff faces (near-vertical) — blocks direct climb.
	StylizedMesh.add_box(ridge, Vector3(8, 18, 50), WorldPalette.ROCK.darkened(0.08), Vector3(28, 9, 0), "CliffE", true, 1.0, &"dirt")
	StylizedMesh.add_box(ridge, Vector3(60, 16, 8), WorldPalette.ROCK.darkened(0.1), Vector3(0, 8, 24), "CliffS", true, 1.0, &"dirt")
	## Switchback trail from SE approach.
	_switchback_trail(ridge, Vector3(36, 0.2, 30), -90.0, 5, 3.6)
	## Summit plateau.
	StylizedMesh.add_box(ridge, Vector3(16, 1.2, 14), WorldPalette.ROCK.lightened(0.05), Vector3(-8, 18.5, -4), "Summit", true, 1.0, &"dirt")
	StylizedMesh.add_box(ridge, Vector3(3.5, 0.15, 1.2), WorldPalette.WOOD, Vector3(-8, 19.3, -2), "SummitBench", false, 1.0, &"wood")
	RegionPropKit.add_discoverable(ridge, &"west_ridge", "West Ridge", Vector3(-8, 19.5, -2), 18, "Wind at the crest — Pleasant Park looks tiny from here.")
	result[&"chests"].append(
		RegionPropKit.build_chest(ridge, "WestRidgeChest", Vector3(-6, 19.0, -6), ChestInteractable.Rarity.RARE, 0.0, "Search the ridge cache")
	)


static func _build_north_pass(parent: Node3D, result: Dictionary) -> void:
	## Mountain pass on the NE road toward Risky Reels — trail required.
	var pass_n := Node3D.new()
	pass_n.name = "NorthPass"
	pass_n.position = Vector3(900.0, 0.0, -900.0)
	parent.add_child(pass_n)
	_mountain_mass(pass_n, Vector3(90, 26, 70), WorldPalette.ROCK.darkened(0.04))
	StylizedMesh.add_box(pass_n, Vector3(10, 22, 60), WorldPalette.ROCK, Vector3(40, 11, 0), "WallE", true, 1.0, &"dirt")
	StylizedMesh.add_box(pass_n, Vector3(10, 22, 60), WorldPalette.ROCK, Vector3(-40, 11, 0), "WallW", true, 1.0, &"dirt")
	## Pass corridor through the middle (walkable floor + side rails).
	StylizedMesh.add_box(pass_n, Vector3(14, 0.5, 80), WorldPalette.PATH, Vector3(0, 4.0, 0), "PassRoad", true, 1.0, &"path")
	## Climb onto the pass from south via switchbacks, then continue north.
	_switchback_trail(pass_n, Vector3(0, 0.2, 42), 180.0, 4, 3.8)
	_switchback_trail(pass_n, Vector3(0, 4.2, -42), 0.0, 3, 3.5)
	## High overlook shelf.
	StylizedMesh.add_box(pass_n, Vector3(12, 1.0, 10), WorldPalette.ROCK.lightened(0.06), Vector3(18, 14.0, -10), "Shelf", true, 1.0, &"dirt")
	_ramp(pass_n, Vector3(10, 9.0, -10), Vector3(8, 0.5, 14), 0.0, 90.0, "ShelfRamp", 32.0)
	RegionPropKit.add_discoverable(pass_n, &"north_pass", "North Pass", Vector3(0, 4.8, 0), 16, "Stone walls funnel the road — the only sane way through.")
	result[&"chests"].append(
		RegionPropKit.build_chest(pass_n, "NorthPassChest", Vector3(18, 14.5, -10), ChestInteractable.Rarity.RARE, 0.0, "Claim the pass stash")
	)


static func _build_south_bluffs(parent: Node3D, result: Dictionary) -> void:
	## Southern boundary cliffs beyond Fatal Fields.
	var bluffs := Node3D.new()
	bluffs.name = "SouthBluffs"
	bluffs.position = Vector3(520.0, 0.0, 4900.0)
	parent.add_child(bluffs)
	_mountain_mass(bluffs, Vector3(110, 28, 50), WorldPalette.ROCK.darkened(0.06))
	StylizedMesh.add_box(bluffs, Vector3(100, 20, 10), WorldPalette.ROCK, Vector3(0, 10, -22), "FaceN", true, 1.0, &"dirt")
	_switchback_trail(bluffs, Vector3(0, 0.2, -28), 0.0, 6, 4.0)
	StylizedMesh.add_box(bluffs, Vector3(18, 1.2, 12), WorldPalette.ROCK.lightened(0.04), Vector3(0, 22.0, 4), "BluffTop", true, 1.0, &"dirt")
	RegionPropKit.add_discoverable(bluffs, &"south_bluffs", "South Bluffs", Vector3(0, 22.8, 4), 20, "The grassland ends in stone — a gate to chapters ahead.")
	result[&"chests"].append(
		RegionPropKit.build_chest(bluffs, "SouthBluffsChest", Vector3(4, 22.5, 2), ChestInteractable.Rarity.LEGENDARY, 0.0, "Open the bluff chest")
	)


static func _mountain_mass(parent: Node3D, size: Vector3, color: Color) -> void:
	StylizedMesh.add_box(parent, size, color, Vector3(0, size.y * 0.45, 0), "Mass", true, 1.0, &"dirt")
	StylizedMesh.add_box(parent, size * Vector3(0.7, 0.45, 0.7), color.darkened(0.08), Vector3(0, size.y * 0.85, 0), "Peak", false, 1.0, &"dirt")
	## Snow/highlight cap for silhouette.
	StylizedMesh.add_box(parent, size * Vector3(0.35, 0.12, 0.35), Color(0.85, 0.86, 0.88), Vector3(0, size.y * 1.05, 0), "Cap")


static func _switchback_trail(parent: Node3D, start: Vector3, yaw_deg: float, steps: int, rise: float) -> void:
	## Zig-zag climbable path — intended mountain access.
	var yaw := deg_to_rad(yaw_deg)
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(forward.z, 0.0, -forward.x)
	for i in steps:
		var side := 1.0 if i % 2 == 0 else -1.0
		var pos := start + forward * (float(i) * 7.5) + right * (side * 6.0) + Vector3(0, float(i) * rise + rise * 0.5, 0)
		var body := StaticBody3D.new()
		body.name = "Trail_%d" % i
		body.collision_layer = 1
		body.position = pos
		body.rotation_degrees.y = yaw_deg + (90.0 if side > 0.0 else -90.0)
		## Mild pitch along travel — walkable with floor_max_angle.
		body.rotation_degrees.x = -18.0
		parent.add_child(body)
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(10.0, 0.45, 3.2)
		mi.mesh = mesh
		mi.material_override = StylizedMesh.make_material(WorldPalette.PATH, 1.0, 0.0, 0.0, &"path")
		body.add_child(mi)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		col.shape = shape
		body.add_child(col)
		## Rail so player doesn't fall off switchback.
		StylizedMesh.add_box(body, Vector3(10.0, 0.55, 0.15), WorldPalette.ROCK, Vector3(0, 0.4, 1.5), "Rail")
