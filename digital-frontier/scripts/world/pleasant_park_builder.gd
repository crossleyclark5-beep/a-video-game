class_name PleasantParkBuilder
extends RefCounted
## Pleasant Park — OG-inspired suburban block for Digital Frontier.
## Layout mirrors classic Pleasant Park structure (not franchise IP):
## 8 houses facing a central park + gazebo, soccer field north, fuel stop east.
## Original procedural art only. Contracts: player_spawn, chests[], enterable_houses[].

## Shared limited palette — pixel diorama, not soft AAA clay.
const GROUND := WorldPalette.GRASS
const GRASS_A := WorldPalette.GRASS_LIGHT
const GRASS_B := WorldPalette.GRASS
const GRASS_C := WorldPalette.GRASS_DARK
const GRASS_D := WorldPalette.LEAF_LIT
const DIRT := WorldPalette.DIRT
const PARK_GREEN := WorldPalette.GRASS_LIGHT
const ROAD := WorldPalette.ROAD
const ROAD_EDGE := WorldPalette.ROAD_EDGE
const SIDEWALK := WorldPalette.SIDEWALK
const CURB := WorldPalette.CURB
const PATH := WorldPalette.PATH

## Ring geometry (park lawn ends ~11, inner curb road centered ~14.5, houses ~27).
const PARK_HALF := 11.0
const ROAD_RING := 14.5
const HOUSE_RING := 27.0


static func build(root: Node3D) -> Dictionary:
	var result := {
		&"player_spawn": Vector3(0.0, 0.15, 18.0),
		&"chests": [],
		&"enterable_houses": [],
	}
	_add_terrain(root)
	_add_road_network(root)
	_add_central_park(root)
	_add_sports_field(root)
	_add_fuel_stop(root, result)
	_add_houses(root, result)
	_add_fences(root)
	_add_vegetation(root)
	_add_street_furniture(root)
	_add_parked_cars(root)
	_add_chests(root, result)
	_add_sign(root, Vector3(0.0, 0.0, 18.5), "PLEASANT PARK")
	_add_exploration_pois(root, result)
	return result


# --- Terrain -----------------------------------------------------------------

static func _add_terrain(root: Node3D) -> void:
	var terrain := Node3D.new()
	terrain.name = "Terrain"
	root.add_child(terrain)
	StylizedMesh.add_box(terrain, Vector3(110, 0.3, 110), GROUND, Vector3(0, -0.15, 0), "BaseGround", true, 1.0, &"grass")

	## Pixel grass fields — central park lawn + house yards + soccer north + fuel east.
	var patches := [
		[Vector3(0, 0.02, 0), Vector3(24, 0.05, 24), PARK_GREEN],
		[Vector3(0, 0.02, -38), Vector3(22, 0.045, 14), GRASS_A],
		[Vector3(-12, 0.02, -27), Vector3(10, 0.04, 8), GRASS_B],
		[Vector3(12, 0.02, -27), Vector3(10, 0.04, 8), GRASS_C],
		[Vector3(-27, 0.02, -12), Vector3(8, 0.04, 10), GRASS_A],
		[Vector3(-27, 0.02, 12), Vector3(8, 0.04, 10), GRASS_D],
		[Vector3(27, 0.02, -12), Vector3(8, 0.04, 10), GRASS_B],
		[Vector3(27, 0.02, 12), Vector3(8, 0.04, 10), GRASS_C],
		[Vector3(-12, 0.02, 27), Vector3(10, 0.04, 8), GRASS_A],
		[Vector3(12, 0.02, 27), Vector3(10, 0.04, 8), GRASS_B],
		[Vector3(40, 0.02, 0), Vector3(12, 0.04, 12), GRASS_C],
		[Vector3(0, 0.02, 38), Vector3(16, 0.04, 8), GRASS_D],
	]
	for i in patches.size():
		var p: Array = patches[i]
		StylizedMesh.add_box(terrain, p[1], p[2], p[0], "GrassPatch_%d" % i, false, 1.0, &"grass")

	## Dirt / worn patches near roads and yards.
	var dirt_spots := [
		[Vector3(-14.5, 0.025, -14.5), Vector3(3.5, 0.03, 2.2)],
		[Vector3(14.5, 0.025, 14.5), Vector3(2.8, 0.03, 2.5)],
		[Vector3(32, 0.025, -2), Vector3(4.0, 0.03, 2.0)],
		[Vector3(-22, 0.025, 0), Vector3(2.5, 0.03, 3.0)],
		[Vector3(0, 0.025, 20), Vector3(2.2, 0.03, 1.8)],
		[Vector3(0, 0.025, -30), Vector3(3.0, 0.03, 2.0)],
	]
	for i in dirt_spots.size():
		var d: Array = dirt_spots[i]
		var tint := DIRT.lightened(0.04 * float(i % 3))
		StylizedMesh.add_box(terrain, d[1], tint, d[0], "Dirt_%d" % i, false, 1.0, &"dirt")

	## Tiny ground imperfections (pebbles / bare spots / grass clumps).
	for i in 18:
		var ang := float(i) * 2.15
		var r := 7.0 + float(i % 6) * 4.2
		var pos := Vector3(cos(ang) * r, 0.04, sin(ang) * r * 0.85)
		var s := 0.22 + float(i % 3) * 0.1
		if i % 3 == 0:
			StylizedMesh.add_box(terrain, Vector3(s, 0.05, s * 0.65), DIRT.darkened(0.08), pos, "Pebble_%d" % i, false, 1.0, &"dirt")
		elif i % 3 == 1:
			StylizedMesh.add_box(terrain, Vector3(s * 1.4, 0.03, s * 1.1), GRASS_D, pos, "Tuft_%d" % i, false, 1.0, &"grass")
		else:
			StylizedMesh.add_box(terrain, Vector3(0.12, 0.22, 0.12), WorldPalette.LEAF_DARK, pos + Vector3(0, 0.1, 0), "Plant_%d" % i, false, 1.0, &"leaf")
			StylizedMesh.add_box(terrain, Vector3(0.2, 0.14, 0.2), WorldPalette.LEAF_LIT, pos + Vector3(0, 0.22, 0), "PlantTop_%d" % i, false, 1.0, &"leaf")

	## Path edge wear — denser dirt/path texture along park ring approaches.
	for i in 8:
		var a := float(i) * TAU / 8.0
		var edge := Vector3(cos(a) * (PARK_HALF + 0.8), 0.028, sin(a) * (PARK_HALF + 0.8))
		StylizedMesh.add_box(terrain, Vector3(1.6, 0.025, 0.9), PATH.darkened(0.05), edge, "PathWear_%d" % i, false, 1.0, &"path")


# --- Roads -------------------------------------------------------------------

static func _add_road_network(root: Node3D) -> void:
	var roads := Node3D.new()
	roads.name = "Roads"
	root.add_child(roads)
	## Inner ring around the central park (classic suburban square).
	_road_segment(roads, Vector3(0, 0.04, -ROAD_RING), Vector3(34, 0.08, 5.5), "RoadN", true)
	_road_segment(roads, Vector3(0, 0.04, ROAD_RING), Vector3(34, 0.08, 5.5), "RoadS", true)
	_road_segment(roads, Vector3(-ROAD_RING, 0.04, 0), Vector3(5.5, 0.08, 34), "RoadW", false)
	_road_segment(roads, Vector3(ROAD_RING, 0.04, 0), Vector3(5.5, 0.08, 34), "RoadE", false)
	## Outer connectors: soccer north, fuel east, south approach.
	_road_segment(roads, Vector3(0, 0.04, -32), Vector3(8, 0.08, 14), "RoadSoccer", false)
	_road_segment(roads, Vector3(32, 0.04, 0), Vector3(14, 0.08, 5.0), "RoadFuel", true)
	_road_segment(roads, Vector3(0, 0.04, 34), Vector3(8, 0.08, 10), "RoadApproach", false)
	_sidewalk_ring(roads)
	_add_crosswalk(roads, Vector3(0, 0.09, -ROAD_RING), true)
	_add_crosswalk(roads, Vector3(0, 0.09, ROAD_RING), true)
	_add_crosswalk(roads, Vector3(-ROAD_RING, 0.09, 0), false)
	_add_crosswalk(roads, Vector3(ROAD_RING, 0.09, 0), false)
	## Driveway stubs from ring road into house yards (toward each house).
	var drives := [
		Vector3(-12, 0.05, -20), Vector3(12, 0.05, -20),
		Vector3(20, 0.05, -12), Vector3(20, 0.05, 12),
		Vector3(-12, 0.05, 20), Vector3(12, 0.05, 20),
		Vector3(-20, 0.05, -12), Vector3(-20, 0.05, 12),
	]
	for dpos in drives:
		StylizedMesh.add_box(roads, Vector3(3.0, 0.05, 3.8), ROAD.lightened(0.06), dpos, "Drive", true, 1.0, &"asphalt")


static func _road_segment(parent: Node3D, pos: Vector3, size: Vector3, node_name: String, along_x: bool) -> void:
	StylizedMesh.add_box(parent, size, ROAD, pos, node_name, true, 1.0, &"asphalt")
	## Darker edge strips (wear / curb shadow).
	if along_x:
		StylizedMesh.add_box(parent, Vector3(size.x, 0.02, 0.2), ROAD_EDGE, pos + Vector3(0, 0.05, size.z * 0.45), node_name + "EdgeA", false, 1.0, &"asphalt")
		StylizedMesh.add_box(parent, Vector3(size.x, 0.02, 0.2), ROAD_EDGE, pos + Vector3(0, 0.05, -size.z * 0.45), node_name + "EdgeB", false, 1.0, &"asphalt")
		_dashed_line(parent, pos, size.x * 0.85, true, node_name)
	else:
		StylizedMesh.add_box(parent, Vector3(0.2, 0.02, size.z), ROAD_EDGE, pos + Vector3(size.x * 0.45, 0.05, 0), node_name + "EdgeA", false, 1.0, &"asphalt")
		StylizedMesh.add_box(parent, Vector3(0.2, 0.02, size.z), ROAD_EDGE, pos + Vector3(-size.x * 0.45, 0.05, 0), node_name + "EdgeB", false, 1.0, &"asphalt")
		_dashed_line(parent, pos, size.z * 0.85, false, node_name)


static func _dashed_line(parent: Node3D, center: Vector3, length: float, along_x: bool, prefix: String) -> void:
	var dash := 1.1
	var gap := 0.7
	var cursor := -length * 0.5
	var i := 0
	while cursor < length * 0.5:
		var seg := mini(dash, length * 0.5 - cursor)
		if along_x:
			StylizedMesh.add_box(parent, Vector3(seg, 0.015, 0.14), WorldPalette.ROAD_LINE, center + Vector3(cursor + seg * 0.5, 0.055, 0), "%sDash_%d" % [prefix, i])
		else:
			StylizedMesh.add_box(parent, Vector3(0.14, 0.015, seg), WorldPalette.ROAD_LINE, center + Vector3(0, 0.055, cursor + seg * 0.5), "%sDash_%d" % [prefix, i])
		cursor += dash + gap
		i += 1


static func _add_crosswalk(parent: Node3D, pos: Vector3, road_along_x: bool) -> void:
	for i in 5:
		var o := float(i - 2) * 0.7
		if road_along_x:
			StylizedMesh.add_box(parent, Vector3(0.45, 0.02, 3.6), Color(0.92, 0.92, 0.88), pos + Vector3(o, 0, 0), "Xing")
		else:
			StylizedMesh.add_box(parent, Vector3(3.6, 0.02, 0.45), Color(0.92, 0.92, 0.88), pos + Vector3(0, 0, o), "Xing")


static func _sidewalk_ring(parent: Node3D) -> void:
	## Park-side walk (inside ring road) + house-side walk (outside ring road).
	var inner := PARK_HALF + 0.2
	var outer := ROAD_RING + 3.2
	StylizedMesh.add_box(parent, Vector3(28, 0.07, 1.6), SIDEWALK, Vector3(0, 0.05, -inner), "WalkN", true, 1.0, &"asphalt")
	StylizedMesh.add_box(parent, Vector3(28, 0.07, 1.6), SIDEWALK, Vector3(0, 0.05, inner), "WalkS", true, 1.0, &"asphalt")
	StylizedMesh.add_box(parent, Vector3(1.6, 0.07, 24), SIDEWALK, Vector3(-inner, 0.05, 0), "WalkW", true, 1.0, &"asphalt")
	StylizedMesh.add_box(parent, Vector3(1.6, 0.07, 24), SIDEWALK, Vector3(inner, 0.05, 0), "WalkE", true, 1.0, &"asphalt")
	StylizedMesh.add_box(parent, Vector3(40, 0.07, 1.4), SIDEWALK, Vector3(0, 0.05, -outer), "WalkOuterN", true, 1.0, &"asphalt")
	StylizedMesh.add_box(parent, Vector3(40, 0.07, 1.4), SIDEWALK, Vector3(0, 0.05, outer), "WalkOuterS", true, 1.0, &"asphalt")
	StylizedMesh.add_box(parent, Vector3(1.4, 0.07, 36), SIDEWALK, Vector3(-outer, 0.05, 0), "WalkOuterW", true, 1.0, &"asphalt")
	StylizedMesh.add_box(parent, Vector3(1.4, 0.07, 36), SIDEWALK, Vector3(outer, 0.05, 0), "WalkOuterE", true, 1.0, &"asphalt")
	## Curb lips on park edge
	for c in [
		[Vector3(0, 0.02, -(PARK_HALF - 0.7)), Vector3(24, 0.12, 0.25)],
		[Vector3(0, 0.02, PARK_HALF - 0.7), Vector3(24, 0.12, 0.25)],
		[Vector3(-(PARK_HALF - 0.7), 0.02, 0), Vector3(0.25, 0.12, 22)],
		[Vector3(PARK_HALF - 0.7, 0.02, 0), Vector3(0.25, 0.12, 22)],
	]:
		StylizedMesh.add_box(parent, c[1], CURB, c[0], "Curb")


# --- Central park ------------------------------------------------------------

static func _add_central_park(root: Node3D) -> void:
	var park := Node3D.new()
	park.name = "CentralPark"
	root.add_child(park)
	StylizedMesh.add_box(park, Vector3(PARK_HALF * 2.0, 0.08, PARK_HALF * 2.0), PARK_GREEN, Vector3(0, 0.05, 0), "Lawn", true, 1.0, &"grass")
	## Cross paths through the square (gazebo sits on the intersection).
	StylizedMesh.add_box(park, Vector3(2.6, 0.04, PARK_HALF * 2.0 - 1.0), PATH, Vector3(0, 0.08, 0), "PathNS", false, 1.0, &"dirt")
	StylizedMesh.add_box(park, Vector3(PARK_HALF * 2.0 - 1.0, 0.04, 2.6), PATH, Vector3(0, 0.08, 0), "PathEW", false, 1.0, &"dirt")
	StylizedMesh.add_box(park, Vector3(3.0, 0.02, PARK_HALF * 2.0 - 0.8), PATH.darkened(0.1), Vector3(0, 0.07, 0), "PathEdgeNS", false, 1.0, &"dirt")

	## Iconic centerpiece gazebo (OG identity).
	var gazebo := Node3D.new()
	gazebo.name = "Gazebo"
	park.add_child(gazebo)
	for offset in [Vector3(-2.4, 1.35, -2.4), Vector3(2.4, 1.35, -2.4), Vector3(-2.4, 1.35, 2.4), Vector3(2.4, 1.35, 2.4)]:
		StylizedMesh.add_box(gazebo, Vector3(0.32, 2.7, 0.32), WorldPalette.WOOD, offset, "Post", true, 1.0, &"wood")
	var gazebo_roof := StylizedMesh.add_box(gazebo, Vector3(7.0, 0.2, 7.0), WorldPalette.ROOF_RED, Vector3(0, 2.75, 0), "RoofDeck", false, 1.0, &"wood")
	var gazebo_peak := StylizedMesh.add_box(gazebo, Vector3(4.6, 0.55, 4.6), WorldPalette.ROOF_RED.darkened(0.08), Vector3(0, 3.2, 0), "RoofPeak", false, 1.0, &"wood")
	OcclusionUtil.mark(gazebo_roof)
	OcclusionUtil.mark(gazebo_peak)
	StylizedMesh.add_box(gazebo, Vector3(5.2, 0.16, 5.2), WorldPalette.WOOD.lightened(0.1), Vector3(0, 0.14, 0), "Floor", true, 1.0, &"wood")
	for z in [-2.5, 2.5]:
		StylizedMesh.add_box(gazebo, Vector3(4.6, 0.08, 0.08), WorldPalette.WOOD.lightened(0.15), Vector3(0, 1.05, z), "Rail")
	for x in [-2.5, 2.5]:
		StylizedMesh.add_box(gazebo, Vector3(0.08, 0.08, 4.6), WorldPalette.WOOD.lightened(0.15), Vector3(x, 1.05, 0), "Rail")

	## Picnic tables around the gazebo (OG park staple).
	_picnic_set(park, Vector3(-7.0, 0, -6.0))
	_picnic_set(park, Vector3(7.0, 0, 6.0))
	_picnic_set(park, Vector3(-6.5, 0, 6.5))
	_picnic_set(park, Vector3(6.5, 0, -6.5))

	## Small fountain offset on south path — secondary landmark, gazebo stays hero.
	var fountain := Node3D.new()
	fountain.name = "Fountain"
	fountain.position = Vector3(0, 0, 7.5)
	park.add_child(fountain)
	StylizedMesh.add_box(fountain, Vector3(3.0, 0.28, 3.0), WorldPalette.SIDEWALK, Vector3(0, 0.22, 0), "Basin", true)
	var water_mi := MeshInstance3D.new()
	water_mi.name = "Water"
	var water_mesh := BoxMesh.new()
	water_mesh.size = Vector3(2.4, 0.12, 2.4)
	water_mi.mesh = water_mesh
	water_mi.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
	water_mi.position = Vector3(0, 0.35, 0)
	fountain.add_child(water_mi)
	StylizedMesh.add_box(fountain, Vector3(0.4, 1.0, 0.4), WorldPalette.METAL, Vector3(0, 0.85, 0), "Spire")
	StylizedMesh.add_box(fountain, Vector3(0.55, 0.28, 0.55), WorldPalette.WATER.lightened(0.15), Vector3(0, 1.35, 0), "WaterTop")
	for i in 4:
		var a := float(i) / 4.0 * TAU
		StylizedMesh.add_box(fountain, Vector3(0.36, 0.16, 0.24), WorldPalette.METAL, Vector3(cos(a) * 1.55, 0.32, sin(a) * 1.55), "Rim")

	## Playground tucked in NE park corner.
	var play := Node3D.new()
	play.name = "Playground"
	play.position = Vector3(7.5, 0, -7.5)
	park.add_child(play)
	StylizedMesh.add_box(play, Vector3(4.5, 0.06, 4.0), WorldPalette.SAND, Vector3(0, 0.06, 0), "Sand", true, 1.0, &"dirt")
	StylizedMesh.add_box(play, Vector3(0.2, 1.6, 0.2), WorldPalette.UI_ACCENT, Vector3(-1.2, 0.9, 0), "SwingPostL", true)
	StylizedMesh.add_box(play, Vector3(0.2, 1.6, 0.2), WorldPalette.UI_ACCENT, Vector3(1.2, 0.9, 0), "SwingPostR", true)
	StylizedMesh.add_box(play, Vector3(2.6, 0.12, 0.16), WorldPalette.BRICK, Vector3(0, 1.65, 0), "SwingBeam")
	StylizedMesh.add_box(play, Vector3(0.5, 0.1, 0.28), WorldPalette.WINDOW, Vector3(0, 0.7, 0), "Seat")
	StylizedMesh.add_box(play, Vector3(1.0, 0.7, 1.0), WorldPalette.UI_ACCENT, Vector3(0, 0.45, 1.3), "SlideBase", true)
	StylizedMesh.add_box(play, Vector3(0.7, 0.1, 1.4), WorldPalette.UI_ACCENT.lightened(0.1), Vector3(0, 0.85, 0.6), "Slide")


static func _picnic_set(parent: Node3D, pos: Vector3) -> void:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	StylizedMesh.add_box(p, Vector3(2.4, 0.12, 1.1), WorldPalette.WOOD, Vector3(0, 0.55, 0), "Table", false, 1.0, &"wood")
	StylizedMesh.add_box(p, Vector3(0.14, 0.55, 0.14), WorldPalette.WOOD.darkened(0.15), Vector3(-0.9, 0.28, -0.35), "Leg1", false, 1.0, &"wood")
	StylizedMesh.add_box(p, Vector3(0.14, 0.55, 0.14), WorldPalette.WOOD.darkened(0.15), Vector3(0.9, 0.28, 0.35), "Leg2", false, 1.0, &"wood")
	StylizedMesh.add_box(p, Vector3(2.2, 0.1, 0.45), WorldPalette.WOOD.darkened(0.08), Vector3(0, 0.35, -1.0), "BenchA", false, 1.0, &"wood")
	StylizedMesh.add_box(p, Vector3(2.2, 0.1, 0.45), WorldPalette.WOOD.darkened(0.08), Vector3(0, 0.35, 1.0), "BenchB", false, 1.0, &"wood")


# --- Sports / fuel -----------------------------------------------------------

static func _add_sports_field(root: Node3D) -> void:
	## Soccer pitch north of the house ring (OG places the field on the north side).
	var field := Node3D.new()
	field.name = "SportsField"
	field.position = Vector3(0, 0, -40)
	root.add_child(field)
	StylizedMesh.add_box(field, Vector3(20, 0.06, 14), WorldPalette.GRASS_DARK, Vector3(0, 0.06, 0), "Pitch", true, 1.0, &"grass")
	StylizedMesh.add_box(field, Vector3(0.12, 0.02, 14), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 0), "MidLine")
	StylizedMesh.add_box(field, Vector3(2.6, 0.03, 2.6), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 0), "CenterBox")
	StylizedMesh.add_box(field, Vector3(20.2, 0.02, 0.12), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, -7), "EndLineS")
	StylizedMesh.add_box(field, Vector3(20.2, 0.02, 0.12), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 7), "EndLineN")
	StylizedMesh.add_box(field, Vector3(0.12, 0.02, 14.2), Color(0.95, 0.95, 0.9), Vector3(-10, 0.1, 0), "SideW")
	StylizedMesh.add_box(field, Vector3(0.12, 0.02, 14.2), Color(0.95, 0.95, 0.9), Vector3(10, 0.1, 0), "SideE")
	for z in [-7.0, 7.0]:
		var goal := Node3D.new()
		goal.position = Vector3(0, 0, z)
		field.add_child(goal)
		StylizedMesh.add_box(goal, Vector3(0.18, 2.0, 0.18), Color(0.92, 0.92, 0.95), Vector3(-2.2, 1.0, 0), "PostL", true)
		StylizedMesh.add_box(goal, Vector3(0.18, 2.0, 0.18), Color(0.92, 0.92, 0.95), Vector3(2.2, 1.0, 0), "PostR", true)
		StylizedMesh.add_box(goal, Vector3(4.55, 0.18, 0.18), Color(0.92, 0.92, 0.95), Vector3(0, 2.0, 0), "Crossbar")
	## Tiered bleachers on the east sideline
	for i in 3:
		StylizedMesh.add_box(field, Vector3(1.15, 0.35, 7.5), WorldPalette.ROOF_RED.darkened(0.1), Vector3(12.0 + float(i) * 0.3, 0.35 + float(i) * 0.4, 0), "Bleacher%d" % i, true, 1.0, &"wood")
	StylizedMesh.add_box(field, Vector3(0.12, 1.4, 7.5), WorldPalette.METAL, Vector3(13.2, 1.0, 0), "BleacherRail")


static func _add_fuel_stop(root: Node3D, result: Dictionary) -> void:
	## Peripheral fuel stop on the east edge (yellow shop + red accents — original branding).
	var fuel := Node3D.new()
	fuel.name = "FuelStop"
	fuel.position = Vector3(42, 0, 0)
	root.add_child(fuel)
	StylizedMesh.add_box(fuel, Vector3(14, 0.12, 12), WorldPalette.ROAD, Vector3(0, 0.08, 0), "Lot", true, 1.0, &"asphalt")
	for i in 4:
		StylizedMesh.add_box(fuel, Vector3(0.08, 0.02, 2.4), Color(0.9, 0.9, 0.85), Vector3(-5 + float(i) * 2.4, 0.14, -3.5), "Stall")
	RegionPropKit.make_enterable_building(
		fuel, "PassNFuelShop", Vector3(2.0, 0, 1.8), Color(0.86, 0.76, 0.30), WorldPalette.ROOF_RED, 0.0, result, InteriorKinds.SHOP, Vector3(7.5, 3.2, 5.2)
	)
	var canopy := StylizedMesh.add_box(fuel, Vector3(9, 0.24, 5.5), WorldPalette.ROAD.darkened(0.1), Vector3(-1.5, 3.5, -2.2), "Canopy")
	OcclusionUtil.mark(canopy)
	StylizedMesh.add_box(fuel, Vector3(0.32, 3.3, 0.32), WorldPalette.METAL, Vector3(-4, 1.65, -2.2), "CanopyPost1", true)
	StylizedMesh.add_box(fuel, Vector3(0.32, 3.3, 0.32), WorldPalette.METAL, Vector3(1, 1.65, -2.2), "CanopyPost2", true)
	StylizedMesh.add_box(fuel, Vector3(0.8, 1.5, 0.6), WorldPalette.ROOF_RED, Vector3(-4, 0.85, -3.0), "Pump1", true)
	StylizedMesh.add_box(fuel, Vector3(0.8, 1.5, 0.6), WorldPalette.ROOF_RED, Vector3(1, 0.85, -3.0), "Pump2", true)
	StylizedMesh.add_box(fuel, Vector3(0.8, 1.5, 0.6), WorldPalette.ROOF_RED, Vector3(-1.5, 0.85, -3.0), "Pump3", true)
	StylizedMesh.add_box(fuel, Vector3(0.2, 0.15, 0.15), Color(0.15, 0.15, 0.15), Vector3(-4, 1.45, -2.7), "Nozzle1")
	StylizedMesh.add_box(fuel, Vector3(2.8, 2.0, 0.3), WorldPalette.LEAF_DARK, Vector3(2.0, 2.6, 4.85), "PriceSign")
	var brand := Label3D.new()
	brand.text = "PASS N FUEL"
	brand.font_size = 48
	brand.position = Vector3(2.0, 2.6, 5.05)
	brand.modulate = WorldPalette.FLOWER_Y
	fuel.add_child(brand)
	StylizedMesh.add_box(fuel, Vector3(0.55, 0.75, 0.55), WorldPalette.BUSH, Vector3(5.5, 0.4, 4.0), "Bin", true)
	StylizedMesh.add_box(fuel, Vector3(0.28, 1.1, 0.28), WorldPalette.FLOWER_Y, Vector3(-6, 0.55, 2.5), "AirPump", true)


# --- Houses ------------------------------------------------------------------

static func _add_houses(root: Node3D, result: Dictionary) -> void:
	## Eight houses on N/E/S/W sides, doors facing the central park (OG block layout).
	## Door local +Z: yaw 0 = south, 90 = east, 180 = north, -90 = west.
	var h := HOUSE_RING
	var specs := [
		## North row — face south toward park
		{"name": "BrickHouse", "pos": Vector3(-12, 0, -h), "color": Color(0.68, 0.34, 0.28), "roof": Color(0.34, 0.22, 0.18), "enterable": true, "yaw": 0.0, "style": &"brick"},
		{"name": "WhiteHouse", "pos": Vector3(12, 0, -h), "color": Color(0.92, 0.92, 0.88), "roof": Color(0.32, 0.38, 0.48), "enterable": true, "yaw": 0.0, "style": &"colonial"},
		## East row — face west toward park
		{"name": "YellowHouse", "pos": Vector3(h, 0, -12), "color": Color(0.90, 0.78, 0.28), "roof": Color(0.42, 0.26, 0.14), "enterable": true, "yaw": -90.0, "style": &"cottage"},
		{"name": "ModernHouse", "pos": Vector3(h, 0, 12), "color": Color(0.36, 0.55, 0.85), "roof": Color(0.18, 0.22, 0.32), "enterable": true, "yaw": -90.0, "style": &"modern"},
		## South row — face north toward park
		{"name": "GreenHouse", "pos": Vector3(-12, 0, h), "color": Color(0.28, 0.58, 0.36), "roof": Color(0.22, 0.28, 0.20), "enterable": true, "yaw": 180.0, "style": &"garden"},
		{"name": "CoralHouse", "pos": Vector3(12, 0, h), "color": Color(0.88, 0.50, 0.42), "roof": Color(0.38, 0.24, 0.18), "enterable": true, "yaw": 180.0, "style": &"bungalow"},
		## West row — face east toward park
		{"name": "SkyHouse", "pos": Vector3(-h, 0, -12), "color": Color(0.52, 0.75, 0.90), "roof": Color(0.28, 0.32, 0.38), "enterable": true, "yaw": 90.0, "style": &"ranch"},
		{"name": "LavenderHouse", "pos": Vector3(-h, 0, 12), "color": Color(0.70, 0.56, 0.86), "roof": Color(0.32, 0.24, 0.38), "enterable": true, "yaw": 90.0, "style": &"victorian"},
	]
	var houses := Node3D.new()
	houses.name = "Houses"
	root.add_child(houses)
	for spec in specs:
		var house := _build_detailed_house(houses, spec)
		if spec["enterable"]:
			result[&"enterable_houses"].append(house)


static func _build_detailed_house(parent: Node3D, spec: Dictionary) -> Node3D:
	var house := Node3D.new()
	var house_name: String = String(spec["name"])
	house.name = house_name
	house.position = spec["pos"]
	house.rotation_degrees.y = float(spec["yaw"])
	parent.add_child(house)

	var wall: Color = spec["color"]
	var roof_c: Color = spec["roof"]
	var enterable: bool = spec["enterable"]
	var style: StringName = spec["style"]

	## Outer lawn (grass) + clean dirt pad under the footprint — no grass through floors.
	var yard_tint := WorldPalette.GRASS
	if style == &"garden":
		yard_tint = WorldPalette.GRASS_DARK
	elif style == &"modern":
		yard_tint = WorldPalette.GRASS_LIGHT
	StylizedMesh.add_box(house, Vector3(11, 0.04, 10), yard_tint, Vector3(0, 0.02, 0), "Lawn", false, 1.0, &"grass")
	StylizedMesh.add_box(house, Vector3(8.2, 0.05, 7.0), WorldPalette.DIRT.lightened(0.06), Vector3(0, 0.04, 0), "Yard", false, 1.0, &"dirt")

	## Driveway
	StylizedMesh.add_box(house, Vector3(3.0, 0.04, 4.2), ROAD.lightened(0.08), Vector3(4.2, 0.04, 3.5), "Driveway", true, 1.0, &"asphalt")

	## Main body + foundation
	var wall_pattern: StringName = &"brick" if style == &"brick" else &"wood"
	StylizedMesh.add_box(house, Vector3(7.6, 0.25, 6.3), WorldPalette.SIDEWALK, Vector3(0, 0.12, 0), "Foundation", false, 1.0, &"asphalt")
	if enterable:
		## Open-top shell — walls with front doorway so interiors stay visible under a faded roof.
		_add_enterable_shell(house, wall, wall_pattern)
	else:
		StylizedMesh.add_box(house, Vector3(7.5, 3.4, 6.2), wall, Vector3(0, 1.7, 0), "Body", true, 1.0, wall_pattern)

	## Garage
	StylizedMesh.add_box(house, Vector3(3.2, 2.4, 4.5), wall.darkened(0.05), Vector3(5.0, 1.2, -0.5), "Garage", true, 1.0, wall_pattern)
	StylizedMesh.add_box(house, Vector3(2.7, 1.85, 0.1), WorldPalette.ROAD, Vector3(5.0, 1.1, 1.78), "GarageDoor")
	StylizedMesh.add_box(house, Vector3(0.15, 0.15, 0.12), WorldPalette.FLOWER_Y, Vector3(5.9, 1.1, 1.85), "GarageHandle")

	## Porch
	StylizedMesh.add_box(house, Vector3(3.6, 0.22, 1.9), WorldPalette.WOOD, Vector3(0, 0.2, 3.6), "Porch", true, 1.0, &"wood")
	var post_color := WorldPalette.WALL_CREAM if style != &"modern" else WorldPalette.METAL
	StylizedMesh.add_box(house, Vector3(0.18, 2.0, 0.18), post_color, Vector3(-1.35, 1.2, 4.25), "PorchPostL", true)
	StylizedMesh.add_box(house, Vector3(0.18, 2.0, 0.18), post_color, Vector3(1.35, 1.2, 4.25), "PorchPostR", true)
	StylizedMesh.add_box(house, Vector3(3.7, 0.14, 2.05), roof_c, Vector3(0, 2.25, 3.6), "PorchRoof", false, 1.0, &"wood")

	## Roof (named Roof for enterable fade) + eaves / gutters
	var roof_mi := MeshInstance3D.new()
	roof_mi.name = "Roof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(8.5, 0.65, 7.3)
	roof_mi.mesh = roof_mesh
	if enterable:
		roof_mi.material_override = StylizedMesh.make_transparent_material(roof_c)
	else:
		roof_mi.material_override = StylizedMesh.make_material(roof_c, 1.0, 0.0, 0.0, &"roof")
	roof_mi.position = Vector3(0, 3.72, 0)
	house.add_child(roof_mi)
	StylizedMesh.add_box(house, Vector3(5.2, 0.85, 4.6), roof_c.darkened(0.1), Vector3(0, 4.28, 0), "RoofPeak", false, 1.0, &"roof")
	## Ridge tile + eave shingles for high-res roof read.
	StylizedMesh.add_box(house, Vector3(5.4, 0.12, 0.35), roof_c.lightened(0.06), Vector3(0, 4.72, 0), "Ridge", false, 1.0, &"roof")
	StylizedMesh.add_box(house, Vector3(8.6, 0.1, 0.28), roof_c.darkened(0.15), Vector3(0, 3.45, 3.45), "EaveF", false, 1.0, &"roof")
	StylizedMesh.add_box(house, Vector3(8.6, 0.1, 0.28), roof_c.darkened(0.15), Vector3(0, 3.45, -3.45), "EaveB", false, 1.0, &"roof")
	StylizedMesh.add_box(house, Vector3(8.7, 0.08, 0.12), WorldPalette.METAL, Vector3(0, 3.35, 3.55), "GutterF")
	StylizedMesh.add_box(house, Vector3(8.7, 0.08, 0.12), WorldPalette.METAL, Vector3(0, 3.35, -3.55), "GutterB")
	StylizedMesh.add_box(house, Vector3(0.1, 3.2, 0.1), WorldPalette.METAL, Vector3(-4.1, 1.7, 3.5), "Downspout")

	## Chimney with cap
	StylizedMesh.add_box(house, Vector3(0.75, 1.5, 0.75), WorldPalette.BRICK, Vector3(-2.5, 4.65, -1.5), "Chimney", true, 1.0, &"brick")
	StylizedMesh.add_box(house, Vector3(0.95, 0.12, 0.95), WorldPalette.ROCK, Vector3(-2.5, 5.4, -1.5), "ChimneyCap")

	## Door with frame + knob
	StylizedMesh.add_box(house, Vector3(1.35, 2.25, 0.08), WorldPalette.WOOD, Vector3(0, 1.2, 3.12), "DoorFrame", false, 1.0, &"wood")
	StylizedMesh.add_box(house, Vector3(1.1, 2.05, 0.1), WorldPalette.WOOD.darkened(0.25), Vector3(0, 1.15, 3.16), "Door", false, 1.0, &"wood")
	StylizedMesh.add_box(house, Vector3(0.1, 0.1, 0.1), WorldPalette.FLOWER_Y, Vector3(0.4, 1.15, 3.25), "Knob")

	## Windows with glass
	StylizedMesh.add_window_pane(house, Vector3(1.25, 1.05, 0.08), Vector3(-2.2, 2.0, 3.14), "WinL")
	StylizedMesh.add_window_pane(house, Vector3(1.25, 1.05, 0.08), Vector3(2.2, 2.0, 3.14), "WinR")
	StylizedMesh.add_window_pane(house, Vector3(1.0, 0.85, 0.08), Vector3(-2.0, 2.2, -3.14), "WinBack")
	StylizedMesh.add_window_pane(house, Vector3(0.9, 0.8, 0.08), Vector3(2.2, 2.0, -3.14), "WinBackR")

	## Mailbox
	StylizedMesh.add_box(house, Vector3(0.1, 0.85, 0.1), WorldPalette.METAL, Vector3(2.9, 0.42, 5.3), "MailPost", true)
	StylizedMesh.add_box(house, Vector3(0.4, 0.28, 0.22), WorldPalette.WINDOW, Vector3(2.9, 0.95, 5.3), "Mailbox")

	_apply_house_style(house, style, wall, roof_c)

	if enterable:
		var door := Interactable.new()
		door.name = "DoorInteractable"
		door.position = Vector3(0, 1.0, 3.55)
		door.once = false
		door.prompt_verb = "Enter %s" % house_name
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		## Tight doorway volume — must not swallow nearby outdoor chests.
		box.size = Vector3(1.5, 2.4, 1.1)
		shape.shape = box
		door.add_child(shape)
		house.add_child(door)
		var exit_m := Marker3D.new()
		exit_m.name = "ExteriorExit"
		exit_m.position = Vector3(0, 0.15, 5.5)
		house.add_child(exit_m)
		var entry_m := Marker3D.new()
		entry_m.name = "InteriorEntry"
		entry_m.position = Vector3(0, 0.15, 1.2)
		house.add_child(entry_m)
		## Apply BuildingVolume before bind so door Enter/Exit works.
		house.set_script(load("res://scripts/systems/buildings/building_volume.gd"))
		house.set("building_id", StringName(house_name.to_snake_case()))
		house.set("display_name", house_name)
		house.set("exterior_zoom", 14.5)
		house.set("interior_zoom", 9.5)
		house.set("roof_paths", [
			NodePath("Roof"),
			NodePath("RoofPeak"),
			NodePath("PorchRoof"),
			NodePath("Ridge"),
			NodePath("EaveF"),
			NodePath("EaveB"),
		])
		house.set("cutaway_paths", [
			NodePath("Garage"),
			NodePath("Chimney"),
			NodePath("ChimneyCap"),
		])
		## Every enterable house gets a real interior room to explore.
		var kind: StringName = spec.get("kind", InteriorKinds.HOUSE)
		if style == &"modern":
			kind = InteriorKinds.OFFICE
		elif style == &"ranch":
			kind = InteriorKinds.APARTMENT
		house.set("interior_kind", kind)
		house.set("interior_scene", null)
		if house.has_method("bind_door_now"):
			house.call("bind_door_now")
		OcclusionUtil.mark_named_in(house, PackedStringArray(["Roof", "RoofPeak", "PorchRoof", "Ridge", "EaveF", "EaveB"]))

	return house


static func _add_enterable_shell(house: Node3D, wall: Color, wall_pattern: StringName = &"flat") -> void:
	## Perimeter walls with a front doorway. Open top = camera sees furniture when roof fades.
	StylizedMesh.add_box(house, Vector3(7.5, 3.2, 0.22), wall, Vector3(0, 1.7, -3.0), "WallBack", true, 1.0, wall_pattern)
	StylizedMesh.add_box(house, Vector3(0.22, 3.2, 6.0), wall, Vector3(-3.65, 1.7, 0), "WallL", true, 1.0, wall_pattern)
	StylizedMesh.add_box(house, Vector3(0.22, 3.2, 6.0), wall, Vector3(3.65, 1.7, 0), "WallR", true, 1.0, wall_pattern)
	StylizedMesh.add_box(house, Vector3(2.7, 3.2, 0.22), wall, Vector3(-2.4, 1.7, 3.0), "WallF1", true, 1.0, wall_pattern)
	StylizedMesh.add_box(house, Vector3(2.7, 3.2, 0.22), wall, Vector3(2.4, 1.7, 3.0), "WallF2", true, 1.0, wall_pattern)
	## Invisible "Body" placeholder for cutaway API compatibility (no solid block).
	var body_mark := Node3D.new()
	body_mark.name = "Body"
	house.add_child(body_mark)
	StylizedMesh.add_box(house, Vector3(7.0, 0.08, 5.6), WorldPalette.WOOD, Vector3(0, 0.16, 0), "ShellFloor", false, 1.0, &"wood")


static func _apply_house_style(house: Node3D, style: StringName, wall: Color, _roof: Color) -> void:
	match style:
		&"brick":
			## Brick belt course + shutters
			StylizedMesh.add_box(house, Vector3(7.55, 0.2, 6.25), wall.darkened(0.12), Vector3(0, 2.4, 0), "Belt", false, 0.8)
			_shutters(house, Vector3(-2.2, 2.0, 3.2), Color(0.25, 0.3, 0.22))
			_shutters(house, Vector3(2.2, 2.0, 3.2), Color(0.25, 0.3, 0.22))
			StylizedMesh.add_box(house, Vector3(1.4, 0.35, 0.45), Color(0.35, 0.55, 0.3), Vector3(-2.2, 1.2, 3.4), "Planter", false, 0.75)
		&"cottage":
			_picket_fence(house, Vector3(0, 0, 5.5), 6)
			StylizedMesh.add_box(house, Vector3(1.2, 0.3, 0.4), WorldPalette.WOOD, Vector3(-2.2, 1.35, 3.35), "FlowerBox", false, 1.0, &"wood")
			StylizedMesh.add_box(house, Vector3(0.28, 0.28, 0.28), WorldPalette.FLOWER, Vector3(-2.2, 1.55, 3.4), "Flower")
			StylizedMesh.add_box(house, Vector3(0.24, 0.24, 0.24), WorldPalette.FLOWER_Y, Vector3(-1.95, 1.52, 3.4), "Flower2")
		&"colonial":
			StylizedMesh.add_box(house, Vector3(0.26, 2.2, 0.26), WorldPalette.WALL_CREAM, Vector3(-1.8, 1.3, 3.9), "ColumnL", true)
			StylizedMesh.add_box(house, Vector3(0.26, 2.2, 0.26), WorldPalette.WALL_CREAM, Vector3(1.8, 1.3, 3.9), "ColumnR", true)
			_shutters(house, Vector3(-2.2, 2.0, 3.2), Color(0.15, 0.2, 0.35))
			_shutters(house, Vector3(2.2, 2.0, 3.2), Color(0.15, 0.2, 0.35))
		&"garden":
			StylizedMesh.add_box(house, Vector3(2.8, 0.3, 1.2), WorldPalette.DIRT, Vector3(-3.5, 0.2, 3.8), "GardenBed", true, 1.0, &"dirt")
			for i in 4:
				StylizedMesh.add_box(house, Vector3(0.32, 0.32, 0.32), Color(0.85, 0.3 + float(i) * 0.1, 0.4), Vector3(-4.2 + float(i) * 0.5, 0.5, 3.8), "Bloom")
			StylizedMesh.add_box(house, Vector3(1.6, 1.4, 1.2), WorldPalette.WOOD, Vector3(-4.5, 0.8, -2.5), "Shed", true, 1.0, &"wood")
			StylizedMesh.add_box(house, Vector3(1.8, 0.2, 1.4), WorldPalette.WOOD.darkened(0.15), Vector3(-4.5, 1.55, -2.5), "ShedRoof", false, 1.0, &"wood")
		&"modern":
			StylizedMesh.add_box(house, Vector3(3.2, 1.4, 0.12), WorldPalette.ROAD, Vector3(-1.5, 2.2, 3.18), "RibbonWinFrame")
			var glass := MeshInstance3D.new()
			glass.name = "RibbonGlass"
			var gm := BoxMesh.new()
			gm.size = Vector3(3.0, 1.2, 0.06)
			glass.mesh = gm
			glass.material_override = StylizedMesh.make_glass_material(WorldPalette.WINDOW)
			glass.position = Vector3(-1.5, 2.2, 3.22)
			house.add_child(glass)
			StylizedMesh.add_box(house, Vector3(2.0, 0.08, 1.2), WorldPalette.UI_INK, Vector3(2.5, 4.6, 0), "Solar")
		&"bungalow":
			StylizedMesh.add_box(house, Vector3(2.0, 0.5, 1.0), WorldPalette.WOOD, Vector3(3.5, 0.35, 4.0), "PorchSwing", false, 1.0, &"wood")
			StylizedMesh.add_box(house, Vector3(0.7, 0.55, 0.7), WorldPalette.BUSH, Vector3(-4.0, 0.35, 2.0), "Bush", false, 1.0, &"grass")
		&"ranch":
			StylizedMesh.add_box(house, Vector3(1.4, 0.9, 0.5), WorldPalette.METAL, Vector3(-3.5, 0.5, 4.5), "BikeRack")
			StylizedMesh.add_box(house, Vector3(0.5, 0.12, 0.5), WorldPalette.UI_INK, Vector3(-3.2, 0.35, 4.5), "Wheel")
			StylizedMesh.add_box(house, Vector3(1.6, 0.06, 0.9), WorldPalette.METAL.darkened(0.2), Vector3(2.0, 4.55, 0.5), "SolarPanel")
		&"victorian":
			StylizedMesh.add_box(house, Vector3(0.15, 2.2, 1.4), Color(0.55, 0.4, 0.65), Vector3(-3.9, 1.2, 2.5), "Trellis")
			StylizedMesh.add_box(house, Vector3(0.32, 0.32, 0.32), WorldPalette.FLOWER, Vector3(-3.9, 1.8, 2.2), "Rose")
			StylizedMesh.add_box(house, Vector3(0.85, 0.25, 0.85), WorldPalette.METAL, Vector3(3.8, 0.2, 4.2), "BirdBath", true)
			StylizedMesh.add_box(house, Vector3(0.22, 0.7, 0.22), WorldPalette.METAL, Vector3(3.8, 0.55, 4.2), "BathStem")
		_:
			pass


static func _shutters(house: Node3D, center: Vector3, color: Color) -> void:
	StylizedMesh.add_box(house, Vector3(0.28, 1.05, 0.06), color, center + Vector3(-0.78, 0, 0), "ShutL", false, 0.75)
	StylizedMesh.add_box(house, Vector3(0.28, 1.05, 0.06), color, center + Vector3(0.78, 0, 0), "ShutR", false, 0.75)


static func _picket_fence(house: Node3D, center: Vector3, posts: int) -> void:
	for i in posts:
		var x := -2.5 + float(i) * (5.0 / float(posts - 1))
		StylizedMesh.add_box(house, Vector3(0.08, 0.7, 0.08), Color(0.9, 0.9, 0.85), center + Vector3(x, 0.35, 0), "Picket", false, 0.7)
	StylizedMesh.add_box(house, Vector3(5.2, 0.06, 0.06), Color(0.88, 0.88, 0.82), center + Vector3(0, 0.55, 0), "PicketRail", false, 0.7)


# --- Fences / vegetation -----------------------------------------------------

static func _add_fences(root: Node3D) -> void:
	var fences := Node3D.new()
	fences.name = "Fences"
	root.add_child(fences)
	## Low park perimeter fence (open at path midpoints conceptually via shorter runs).
	var ph := PARK_HALF - 0.5
	_fence_line(fences, Vector3(-ph, 0, -ph), Vector3(-2.5, 0, -ph), 5)
	_fence_line(fences, Vector3(2.5, 0, -ph), Vector3(ph, 0, -ph), 5)
	_fence_line(fences, Vector3(-ph, 0, ph), Vector3(-2.5, 0, ph), 5)
	_fence_line(fences, Vector3(2.5, 0, ph), Vector3(ph, 0, ph), 5)
	_fence_line(fences, Vector3(-ph, 0, -ph), Vector3(-ph, 0, -2.5), 5)
	_fence_line(fences, Vector3(-ph, 0, 2.5), Vector3(-ph, 0, ph), 5)
	_fence_line(fences, Vector3(ph, 0, -ph), Vector3(ph, 0, -2.5), 5)
	_fence_line(fences, Vector3(ph, 0, 2.5), Vector3(ph, 0, ph), 5)
	## Soccer field sideline fences
	_fence_line(fences, Vector3(-11, 0, -48), Vector3(-11, 0, -32), 6)
	_fence_line(fences, Vector3(11, 0, -48), Vector3(11, 0, -32), 6)


static func _fence_line(parent: Node3D, a: Vector3, b: Vector3, posts: int) -> void:
	for i in range(posts):
		var t := float(i) / float(maxi(posts - 1, 1))
		var p := a.lerp(b, t)
		StylizedMesh.add_box(parent, Vector3(0.12, 0.95, 0.12), WorldPalette.FENCE, p + Vector3(0, 0.48, 0), "FencePost", true)
	var mid := a.lerp(b, 0.5)
	var length := a.distance_to(b)
	var delta := b - a
	var rail_size := Vector3(length, 0.08, 0.08) if absf(delta.x) >= absf(delta.z) else Vector3(0.08, 0.08, length)
	StylizedMesh.add_box(parent, rail_size, WorldPalette.FENCE.darkened(0.08), mid + Vector3(0, 0.75, 0), "FenceRail")
	StylizedMesh.add_box(parent, rail_size, WorldPalette.FENCE.darkened(0.08), mid + Vector3(0, 0.4, 0), "FenceRailLow")


static func _add_vegetation(root: Node3D) -> void:
	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	## Trees ring the central park + fill yard gaps (OG park is tree-framed).
	var tree_specs := [
		{"pos": Vector3(-8.5, 0, -8.5), "kind": &"oak", "scale": 1.05},
		{"pos": Vector3(8.5, 0, -8.0), "kind": &"round", "scale": 0.9},
		{"pos": Vector3(-8.5, 0, 8.0), "kind": &"pine", "scale": 1.15},
		{"pos": Vector3(8.5, 0, 8.5), "kind": &"oak", "scale": 0.95},
		{"pos": Vector3(-4.0, 0, -9.5), "kind": &"pine", "scale": 0.85},
		{"pos": Vector3(4.0, 0, 9.5), "kind": &"round", "scale": 0.9},
		{"pos": Vector3(-9.5, 0, 0), "kind": &"oak", "scale": 1.0},
		{"pos": Vector3(9.5, 0, 0), "kind": &"pine", "scale": 1.05},
		{"pos": Vector3(-18, 0, -20), "kind": &"oak", "scale": 1.1},
		{"pos": Vector3(18, 0, -20), "kind": &"round", "scale": 1.0},
		{"pos": Vector3(20, 0, -18), "kind": &"pine", "scale": 0.9},
		{"pos": Vector3(20, 0, 18), "kind": &"oak", "scale": 0.95},
		{"pos": Vector3(-20, 0, 18), "kind": &"round", "scale": 1.05},
		{"pos": Vector3(-20, 0, -18), "kind": &"pine", "scale": 1.0},
		{"pos": Vector3(-12, 0, 20), "kind": &"oak", "scale": 0.88},
		{"pos": Vector3(12, 0, 20), "kind": &"pine", "scale": 0.92},
		{"pos": Vector3(-6, 0, -34), "kind": &"round", "scale": 1.0},
		{"pos": Vector3(6, 0, -34), "kind": &"oak", "scale": 1.05},
		{"pos": Vector3(36, 0, -8), "kind": &"pine", "scale": 0.85},
		{"pos": Vector3(36, 0, 8), "kind": &"oak", "scale": 0.9},
		{"pos": Vector3(-34, 0, 0), "kind": &"round", "scale": 1.1},
		{"pos": Vector3(0, 0, 36), "kind": &"pine", "scale": 0.95},
	]
	for i in tree_specs.size():
		var s: Dictionary = tree_specs[i]
		_tree(trees, s["pos"], s["kind"], float(s["scale"]), i)

	var bushes := Node3D.new()
	bushes.name = "Bushes"
	root.add_child(bushes)
	var bush_spots := [
		Vector3(-6, 0, -10.5), Vector3(6, 0, 10.5), Vector3(-10.5, 0, 4), Vector3(10.5, 0, -4),
		Vector3(-16, 0, -24), Vector3(16, 0, -24), Vector3(24, 0, -16), Vector3(24, 0, 16),
		Vector3(-24, 0, 16), Vector3(-24, 0, -16), Vector3(3, 0, -8), Vector3(-3, 0, 8),
		Vector3(40, 0, 6), Vector3(-8, 0, -36),
	]
	for i in bush_spots.size():
		_bush(bushes, bush_spots[i], i)

	var rocks := Node3D.new()
	rocks.name = "Rocks"
	root.add_child(rocks)
	for i in 16:
		var a := float(i) * 1.55
		var pos := Vector3(cos(a) * (9.5 + float(i) * 0.9), 0.08, sin(a) * (7.5 + float(i % 5) * 1.8))
		var c := WorldPalette.ROCK.darkened(0.05 * float(i % 3))
		var rs := Vector3(0.32 + float(i % 3) * 0.12, 0.16 + float(i % 2) * 0.1, 0.28 + float(i % 4) * 0.06)
		StylizedMesh.add_box(rocks, rs, c, pos, "Rock_%d" % i, false, 1.0, &"dirt")
		if i % 3 == 0:
			StylizedMesh.add_box(rocks, rs * Vector3(0.55, 0.7, 0.5), c.lightened(0.08), pos + Vector3(0.12, 0.06, -0.08), "RockChip_%d" % i)

	var leaves := Node3D.new()
	leaves.name = "FallenLeaves"
	root.add_child(leaves)
	for i in 20:
		var pos := Vector3(-7 + float(i % 5) * 3.5, 0.05, -6 + float(i / 5) * 4.0)
		var lc := Color(0.75, 0.45, 0.2) if i % 2 == 0 else Color(0.7, 0.55, 0.15)
		StylizedMesh.add_box(leaves, Vector3(0.35, 0.02, 0.22), lc, pos, "Leaf_%d" % i, false, 1.0, &"leaf")

	## Small roadside plants for high-res ground clutter.
	var plants := Node3D.new()
	plants.name = "SmallPlants"
	root.add_child(plants)
	var plant_spots := [
		Vector3(-7, 0, -11), Vector3(7.5, 0, 11), Vector3(-11, 0, 6), Vector3(11, 0, -6),
		Vector3(2, 0, -12), Vector3(-3, 0, 12), Vector3(22, 0, -10), Vector3(-22, 0, 10),
		Vector3(38, 0, 2), Vector3(-15, 0, -28), Vector3(15, 0, -28), Vector3(0, 0, 34),
	]
	for i in plant_spots.size():
		var pp: Vector3 = plant_spots[i]
		StylizedMesh.add_box(plants, Vector3(0.1, 0.28, 0.1), WorldPalette.LEAF_DARK, pp + Vector3(0, 0.14, 0), "Stem_%d" % i)
		StylizedMesh.add_box(plants, Vector3(0.28, 0.16, 0.28), WorldPalette.LEAF if i % 2 == 0 else WorldPalette.LEAF_LIT, pp + Vector3(0, 0.32, 0), "Foliage_%d" % i, false, 1.0, &"leaf")
		if i % 2 == 0:
			StylizedMesh.add_box(plants, Vector3(0.14, 0.14, 0.14), WorldPalette.FLOWER if i % 4 == 0 else WorldPalette.FLOWER_Y, pp + Vector3(0.12, 0.4, 0), "Bloom_%d" % i)

	_flower_bed(root, Vector3(-5, 0, -9))
	_flower_bed(root, Vector3(6, 0, 9))
	_flower_bed(root, Vector3(-9, 0, 5))
	_flower_bed(root, Vector3(5, 0, -5))


static func _tree(parent: Node3D, pos: Vector3, kind: StringName, scale_v: float, idx: int) -> void:
	## High-res pixel trees — denser leaf clusters + stronger silhouettes, still boxy.
	var tree := Node3D.new()
	tree.name = "Tree_%d" % idx
	tree.position = pos
	tree.rotation_degrees.y = float(idx * 37 % 360)
	parent.add_child(tree)
	var trunk_c := WorldPalette.TRUNK
	var tw := 0.32 * scale_v
	StylizedMesh.add_box(tree, Vector3(tw, 1.75 * scale_v, tw), trunk_c, Vector3(0, 0.88 * scale_v, 0), "Trunk", true, 1.0, &"wood")
	StylizedMesh.add_box(tree, Vector3(tw * 0.55, 0.7 * scale_v, tw * 0.55), trunk_c.lightened(0.06), Vector3(0.28 * scale_v, 1.5 * scale_v, 0.1), "Branch", false, 1.0, &"wood")
	match kind:
		&"pine":
			var leaf := WorldPalette.LEAF_DARK
			StylizedMesh.add_box(tree, Vector3(1.85 * scale_v, 0.95 * scale_v, 1.85 * scale_v), leaf, Vector3(0, 1.95 * scale_v, 0), "Canopy1", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(1.35 * scale_v, 0.85 * scale_v, 1.35 * scale_v), leaf.lightened(0.05), Vector3(0, 2.7 * scale_v, 0), "Canopy2", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.85 * scale_v, 0.7 * scale_v, 0.85 * scale_v), leaf.lightened(0.1), Vector3(0, 3.35 * scale_v, 0), "Canopy3", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.45 * scale_v, 0.5 * scale_v, 0.45 * scale_v), leaf.lightened(0.14), Vector3(0, 3.85 * scale_v, 0), "Tip", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.55 * scale_v, 0.4 * scale_v, 0.55 * scale_v), leaf.darkened(0.06), Vector3(0.45 * scale_v, 2.2 * scale_v, 0.2), "Needle", false, 1.0, &"leaf")
		&"oak":
			var leaf := WorldPalette.LEAF if idx % 2 == 0 else WorldPalette.LEAF_LIT
			StylizedMesh.add_box(tree, Vector3(2.0 * scale_v, 1.35 * scale_v, 2.0 * scale_v), leaf, Vector3(0, 2.3 * scale_v, 0), "Canopy", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(1.15 * scale_v, 0.9 * scale_v, 1.15 * scale_v), leaf.lightened(0.06), Vector3(0.6 * scale_v, 2.9 * scale_v, 0.25), "Canopy2", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(1.0 * scale_v, 0.85 * scale_v, 1.0 * scale_v), leaf.darkened(0.05), Vector3(-0.55 * scale_v, 2.6 * scale_v, -0.3), "Canopy3", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.7 * scale_v, 0.55 * scale_v, 0.7 * scale_v), leaf.lightened(0.1), Vector3(0.15 * scale_v, 3.35 * scale_v, -0.35), "Canopy4", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.55 * scale_v, 0.45 * scale_v, 0.55 * scale_v), leaf.darkened(0.08), Vector3(-0.7 * scale_v, 2.15 * scale_v, 0.45), "Canopy5", false, 1.0, &"leaf")
		_:
			var leaf := WorldPalette.LEAF_LIT
			StylizedMesh.add_box(tree, Vector3(1.7 * scale_v, 1.2 * scale_v, 1.7 * scale_v), leaf, Vector3(0, 2.15 * scale_v, 0), "Canopy", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.95 * scale_v, 0.8 * scale_v, 0.95 * scale_v), leaf.lightened(0.08), Vector3(0.45 * scale_v, 2.6 * scale_v, 0.2), "Canopy2", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.8 * scale_v, 0.7 * scale_v, 0.8 * scale_v), leaf.darkened(0.05), Vector3(-0.4 * scale_v, 2.45 * scale_v, -0.25), "Canopy3", false, 1.0, &"leaf")
			StylizedMesh.add_box(tree, Vector3(0.5 * scale_v, 0.45 * scale_v, 0.5 * scale_v), leaf.lightened(0.12), Vector3(0.1 * scale_v, 3.05 * scale_v, 0.1), "Canopy4", false, 1.0, &"leaf")


static func _bush(parent: Node3D, pos: Vector3, idx: int) -> void:
	var b := Node3D.new()
	b.name = "Bush_%d" % idx
	b.position = pos
	parent.add_child(b)
	var c := WorldPalette.BUSH if idx % 2 == 0 else WorldPalette.LEAF
	var s := 0.65 + float(idx % 3) * 0.14
	StylizedMesh.add_box(b, Vector3(s, s * 0.8, s), c, Vector3(0, s * 0.4, 0), "A", false, 1.0, &"leaf")
	StylizedMesh.add_box(b, Vector3(s * 0.65, s * 0.55, s * 0.65), c.lightened(0.06), Vector3(s * 0.32, s * 0.4, 0.08), "B", false, 1.0, &"leaf")
	StylizedMesh.add_box(b, Vector3(s * 0.45, s * 0.4, s * 0.45), c.darkened(0.05), Vector3(-s * 0.28, s * 0.35, -0.1), "C", false, 1.0, &"leaf")


static func _flower_bed(parent: Node3D, pos: Vector3) -> void:
	var bed := Node3D.new()
	bed.position = pos
	parent.add_child(bed)
	StylizedMesh.add_box(bed, Vector3(2.6, 0.22, 1.0), WorldPalette.DIRT, Vector3(0, 0.15, 0), "Bed", true, 1.0, &"dirt")
	var colors := [WorldPalette.FLOWER, WorldPalette.FLOWER_Y, WorldPalette.WINDOW, Color(0.85, 0.45, 0.85)]
	for i in 6:
		var fx := -1.0 + float(i) * 0.4
		var fz := 0.12 if i % 2 == 0 else -0.12
		StylizedMesh.add_box(bed, Vector3(0.1, 0.18, 0.1), WorldPalette.LEAF_DARK, Vector3(fx, 0.28, fz), "Stem")
		StylizedMesh.add_box(bed, Vector3(0.26, 0.26, 0.26), colors[i % colors.size()], Vector3(fx, 0.48, fz), "Flower")


# --- Street furniture / cars -------------------------------------------------

static func _add_street_furniture(root: Node3D) -> void:
	var decor := Node3D.new()
	decor.name = "Decor"
	root.add_child(decor)
	## Street lamps at ring-road corners + approach.
	var lamp_spots := [
		Vector3(-ROAD_RING, 0, -ROAD_RING), Vector3(ROAD_RING, 0, -ROAD_RING),
		Vector3(-ROAD_RING, 0, ROAD_RING), Vector3(ROAD_RING, 0, ROAD_RING),
		Vector3(0, 0, -ROAD_RING), Vector3(0, 0, ROAD_RING),
		Vector3(-ROAD_RING, 0, 0), Vector3(ROAD_RING, 0, 0),
	]
	for i in lamp_spots.size():
		_street_lamp(decor, lamp_spots[i], i < 6)

	## Bus stop on the south ring (OG Pleasant Park street amenity).
	_bus_stop(decor, Vector3(-6.0, 0.0, ROAD_RING + 0.5))

	_bench(decor, Vector3(-4.5, 0, 8.5), 0)
	_bench(decor, Vector3(4.5, 0, -8.5), 180)
	_bench(decor, Vector3(-8.5, 0, -3.5), 90)
	_bench(decor, Vector3(8.5, 0, 3.5), -90)

	for p in [Vector3(9.5, 0, -9.5), Vector3(-9.5, 0, 9.5), Vector3(10.5, 0, 10.5), Vector3(-10.5, 0, -10.5), Vector3(40, 0, 4)]:
		StylizedMesh.add_cylinder(decor, 0.28, 0.75, Color(0.32, 0.38, 0.32), p + Vector3(0, 0.4, 0), "Bin", true, 12, 0.7)
		StylizedMesh.add_cylinder(decor, 0.3, 0.08, Color(0.25, 0.28, 0.25), p + Vector3(0, 0.8, 0), "BinLid", false, 12, 0.55)

	for p in [Vector3(-16, 0, -8), Vector3(16, 0, 8), Vector3(-8, 0, 16), Vector3(32, 0, -6)]:
		_utility_pole(decor, p)

	_street_sign(decor, Vector3(-13, 0, -13), "PARK")
	_street_sign(decor, Vector3(13, 0, -13), "OAK ST")
	_street_sign(decor, Vector3(-13, 0, 13), "MAPLE")
	_street_sign(decor, Vector3(13, 0, 13), "PINE")


static func _bus_stop(parent: Node3D, pos: Vector3) -> void:
	var stop := Node3D.new()
	stop.name = "BusStop"
	stop.position = pos
	parent.add_child(stop)
	StylizedMesh.add_box(stop, Vector3(0.15, 2.4, 0.15), WorldPalette.METAL, Vector3(-1.4, 1.2, 0), "PostL", true)
	StylizedMesh.add_box(stop, Vector3(0.15, 2.4, 0.15), WorldPalette.METAL, Vector3(1.4, 1.2, 0), "PostR", true)
	StylizedMesh.add_box(stop, Vector3(3.2, 0.12, 1.4), WorldPalette.METAL.darkened(0.1), Vector3(0, 2.45, 0), "Roof")
	StylizedMesh.add_box(stop, Vector3(2.8, 0.7, 0.45), WorldPalette.UI_INK, Vector3(0, 1.1, -0.35), "BenchBack")
	StylizedMesh.add_box(stop, Vector3(2.8, 0.12, 0.55), WorldPalette.WOOD, Vector3(0, 0.75, 0), "Seat", false, 1.0, &"wood")
	var label := Label3D.new()
	label.text = "BUS"
	label.font_size = 42
	label.position = Vector3(0, 2.55, 0.2)
	label.modulate = WorldPalette.UI_PAPER
	stop.add_child(label)


static func _street_lamp(parent: Node3D, pos: Vector3, with_light: bool) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	parent.add_child(lamp)
	StylizedMesh.add_box(lamp, Vector3(0.2, 3.4, 0.2), WorldPalette.METAL, Vector3(0, 1.7, 0), "Pole", true)
	StylizedMesh.add_box(lamp, Vector3(0.9, 0.12, 0.28), WorldPalette.METAL.darkened(0.1), Vector3(0, 3.35, 0.15), "Arm")
	var bulb := StylizedMesh.add_box(lamp, Vector3(0.32, 0.32, 0.32), WorldPalette.LAMP_GLOW, Vector3(0, 3.2, 0.4), "Bulb")
	if bulb is MeshInstance3D:
		(bulb as MeshInstance3D).material_override = StylizedMesh.make_material(WorldPalette.LAMP_GLOW, 1.0, 0.0, 0.5)
	if with_light:
		var light := OmniLight3D.new()
		light.name = "LampLight"
		light.position = Vector3(0, 3.1, 0.4)
		light.light_color = WorldPalette.LAMP_GLOW
		light.light_energy = 0.48
		light.omni_range = 7.5
		light.shadow_enabled = false
		lamp.add_child(light)


static func _bench(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var b := Node3D.new()
	b.position = pos
	b.rotation_degrees.y = yaw
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(1.9, 0.12, 0.52), WorldPalette.WOOD, Vector3(0, 0.45, 0), "Seat", false, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(1.9, 0.55, 0.1), WorldPalette.WOOD, Vector3(0, 0.72, -0.22), "Back", false, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(0.12, 0.45, 0.42), WorldPalette.METAL, Vector3(-0.75, 0.22, 0), "LegL", true)
	StylizedMesh.add_box(b, Vector3(0.12, 0.45, 0.42), WorldPalette.METAL, Vector3(0.75, 0.22, 0), "LegR", true)


static func _utility_pole(parent: Node3D, pos: Vector3) -> void:
	var pole := Node3D.new()
	pole.position = pos
	parent.add_child(pole)
	StylizedMesh.add_cylinder(pole, 0.14, 5.0, Color(0.35, 0.28, 0.2), Vector3(0, 2.5, 0), "Pole", true, 10, 0.8)
	StylizedMesh.add_box(pole, Vector3(1.4, 0.1, 0.1), Color(0.3, 0.3, 0.32), Vector3(0, 4.6, 0), "Crossarm", false, 0.5)
	StylizedMesh.add_cylinder(pole, 0.08, 0.25, Color(0.2, 0.2, 0.22), Vector3(-0.5, 4.5, 0), "Insulator", false, 8, 0.4)


static func _street_sign(parent: Node3D, pos: Vector3, text: String) -> void:
	var s := Node3D.new()
	s.position = pos
	parent.add_child(s)
	StylizedMesh.add_cylinder(s, 0.06, 2.4, Color(0.4, 0.4, 0.42), Vector3(0, 1.2, 0), "Post", true, 8, 0.5)
	StylizedMesh.add_box(s, Vector3(1.4, 0.45, 0.08), Color(0.15, 0.45, 0.25), Vector3(0, 2.3, 0), "Board", false, 0.55)
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.position = Vector3(0, 2.3, 0.06)
	label.modulate = Color(0.95, 0.95, 0.9)
	s.add_child(label)


static func _add_parked_cars(root: Node3D) -> void:
	var cars := Node3D.new()
	cars.name = "ParkedCars"
	root.add_child(cars)
	var specs := [
		{"pos": Vector3(-12, 0, -20), "yaw": 0.0, "color": Color(0.75, 0.2, 0.18)},
		{"pos": Vector3(12, 0, -20), "yaw": 0.0, "color": Color(0.2, 0.35, 0.7)},
		{"pos": Vector3(20, 0, -12), "yaw": -90.0, "color": Color(0.85, 0.85, 0.82)},
		{"pos": Vector3(20, 0, 12), "yaw": -90.0, "color": Color(0.2, 0.55, 0.35)},
		{"pos": Vector3(40, 0, -4), "yaw": 90.0, "color": Color(0.15, 0.15, 0.18)},
		{"pos": Vector3(-20, 0, 12), "yaw": 90.0, "color": Color(0.9, 0.7, 0.2)},
	]
	for i in specs.size():
		_car(cars, specs[i]["pos"], float(specs[i]["yaw"]), specs[i]["color"], i)


static func _car(parent: Node3D, pos: Vector3, yaw: float, color: Color, idx: int) -> void:
	var car := Node3D.new()
	car.name = "Car_%d" % idx
	car.position = pos
	car.rotation_degrees.y = yaw
	parent.add_child(car)
	StylizedMesh.add_box(car, Vector3(1.8, 0.55, 3.6), color, Vector3(0, 0.45, 0), "Body", true)
	StylizedMesh.add_box(car, Vector3(1.6, 0.5, 1.8), color.lightened(0.08), Vector3(0, 0.95, -0.2), "Cabin")
	## Windows
	var win := MeshInstance3D.new()
	win.name = "Windshield"
	var wm := BoxMesh.new()
	wm.size = Vector3(1.5, 0.4, 0.08)
	win.mesh = wm
	win.material_override = StylizedMesh.make_glass_material()
	win.position = Vector3(0, 0.95, 0.7)
	car.add_child(win)
	## Wheels — chunky boxes, not smooth cylinders
	for wp in [Vector3(-0.85, 0.28, 1.1), Vector3(0.85, 0.28, 1.1), Vector3(-0.85, 0.28, -1.1), Vector3(0.85, 0.28, -1.1)]:
		StylizedMesh.add_box(car, Vector3(0.22, 0.45, 0.45), Color(0.12, 0.12, 0.12), wp, "Wheel")
	StylizedMesh.add_box(car, Vector3(0.25, 0.12, 0.15), WorldPalette.LAMP_GLOW, Vector3(-0.6, 0.45, 1.8), "HeadL")
	StylizedMesh.add_box(car, Vector3(0.25, 0.12, 0.15), WorldPalette.LAMP_GLOW, Vector3(0.6, 0.45, 1.8), "HeadR")


# --- Gameplay props (contracts preserved) ------------------------------------

static func _add_chests(root: Node3D, result: Dictionary) -> void:
	var chests_root := Node3D.new()
	chests_root.name = "Chests"
	root.add_child(chests_root)
	var specs := [
		{"name": "Chest_0", "pos": Vector3(3.5, 0, 3.5), "rarity": ChestInteractable.Rarity.NORMAL, "respawn": 24.0},
		## Keep clear of BrickHouse door at (-12, -27) porch.
		{"name": "Chest_1", "pos": Vector3(-18, 0, -18), "rarity": ChestInteractable.Rarity.NORMAL, "respawn": 24.0},
		{"name": "Chest_2", "pos": Vector3(27, 0, 12), "rarity": ChestInteractable.Rarity.RARE, "respawn": 0.0},
		{"name": "Chest_3", "pos": Vector3(0, 0, -40), "rarity": ChestInteractable.Rarity.NORMAL, "respawn": 24.0},
		{"name": "Chest_4", "pos": Vector3(42, 0, -5), "rarity": ChestInteractable.Rarity.NORMAL, "respawn": 24.0},
	]
	for spec in specs:
		result[&"chests"].append(
			_build_chest(
				chests_root,
				String(spec["name"]),
				spec["pos"],
				spec["rarity"],
				float(spec.get("respawn", 0.0)),
			)
		)


static func _build_chest(
	parent: Node3D,
	chest_name: String,
	pos: Vector3,
	rarity: ChestInteractable.Rarity = ChestInteractable.Rarity.NORMAL,
	respawn_hours: float = 0.0,
) -> Area3D:
	var area := ChestInteractable.new()
	area.name = chest_name
	area.chest_id = StringName(chest_name.to_snake_case())
	area.rarity = rarity
	area.respawn_hours = respawn_hours
	area.position = pos + Vector3(0, 0.4, 0)
	area.loot_item_id = &"hex_shard"
	area.loot_quantity = 1
	match rarity:
		ChestInteractable.Rarity.RARE:
			area.loot_table_id = &"loot_chest_rare"
			area.creature_xp_on_open = 10
		ChestInteractable.Rarity.LEGENDARY:
			area.loot_table_id = &"loot_chest_legendary"
			area.creature_xp_on_open = 18
		_:
			area.loot_table_id = &"loot_chest_normal"
			area.creature_xp_on_open = 6
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.95, 0.55, 0.7)
	body.mesh = box
	var body_color := Color(0.88, 0.68, 0.18)
	match rarity:
		ChestInteractable.Rarity.RARE:
			body_color = Color(0.45, 0.65, 0.95)
		ChestInteractable.Rarity.LEGENDARY:
			body_color = Color(0.95, 0.55, 0.2)
	body.material_override = StylizedMesh.make_material(body_color, 0.5)
	area.add_child(body)
	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.98, 0.18, 0.72)
	lid.mesh = lid_mesh
	lid.material_override = StylizedMesh.make_material(body_color.darkened(0.15), 0.5)
	lid.position = Vector3(0, 0.35, 0)
	area.add_child(lid)
	var shape := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(1.5, 1.3, 1.5)
	shape.shape = s
	area.add_child(shape)
	parent.add_child(area)
	return area


static func _add_exploration_pois(root: Node3D, result: Dictionary) -> void:
	var pois := Node3D.new()
	pois.name = "ExplorationPOIs"
	root.add_child(pois)
	## Alley stash behind the east fuel stop.
	StylizedMesh.add_box(pois, Vector3(3.5, 2.2, 1.0), Color(0.34, 0.36, 0.40), Vector3(48, 1.1, 6), "AlleyWall", true, 0.8)
	var secret := _build_chest(pois, "SecretAlleyChest", Vector3(48, 0, 8), ChestInteractable.Rarity.LEGENDARY)
	(secret as ChestInteractable).prompt_verb = "Open legendary stash"
	result[&"chests"].append(secret)

	var bush := Node3D.new()
	bush.name = "MysteryBush"
	bush.position = Vector3(-9, 0, -4)
	pois.add_child(bush)
	StylizedMesh.add_sphere(bush, 0.9, Color(0.18, 0.48, 0.22), Vector3(0, 0.7, 0), "BushA", 12, 8, 0.85)
	StylizedMesh.add_sphere(bush, 0.7, Color(0.22, 0.52, 0.25), Vector3(0.5, 0.55, 0.2), "BushB", 12, 8, 0.85)
	var bush_chest := _build_chest(bush, "BushChest", Vector3(0, 0, 0), ChestInteractable.Rarity.RARE)
	bush_chest.position = Vector3(0, 0.35, 0)
	(bush_chest as ChestInteractable).prompt_verb = "Search the bushes"
	result[&"chests"].append(bush_chest)

	var plaque := DiscoverableInteractable.new()
	plaque.name = "ParkPlaque"
	plaque.position = Vector3(3.8, 0.6, 2.0)
	plaque.location_id = &"park_plaque"
	plaque.location_name = "Park Plaque"
	plaque.discover_message = "Pleasant Park — Where every path leads to a story."
	plaque.bits_reward = 8
	var pshape := CollisionShape3D.new()
	var pb := BoxShape3D.new()
	pb.size = Vector3(1.6, 1.4, 1.6)
	pshape.shape = pb
	plaque.add_child(pshape)
	StylizedMesh.add_box(plaque, Vector3(1.2, 0.8, 0.15), Color(0.52, 0.42, 0.28), Vector3(0, 0, 0), "PlaqueBoard", false, 0.7)
	pois.add_child(plaque)

	var field_chest := _build_chest(pois, "BleacherChest", Vector3(12, 0, -40), ChestInteractable.Rarity.RARE)
	(field_chest as ChestInteractable).prompt_verb = "Check under the bleachers"
	result[&"chests"].append(field_chest)

	## Landmark discoveries (positions match new OG layout).
	_add_discoverable(pois, &"central_fountain", "Central Fountain", Vector3(0, 0.5, 7.5), 12, "The fountain hums with soft digital ripples.")
	_add_discoverable(pois, &"sports_field", "Sports Field", Vector3(0, 0.5, -40), 10, "Cleats and chalk — the field is ready for a match.")
	_add_discoverable(pois, &"fuel_stop", "Fuel Stop", Vector3(42, 0.5, 0), 10, "A bright canopy over sleepy pumps.")
	_add_discoverable(pois, &"park_gazebo", "Park Gazebo", Vector3(0, 0.5, 0), 10, "The heart of Pleasant Park — shade, stories, and soft light.")

	## Park Guide near the south park entrance (quest talk target).
	var guide := NpcTalkInteractable.new()
	guide.name = "ParkGuide"
	guide.npc_id = &"park_guide"
	guide.npc_display_name = "Park Guide"
	guide.position = Vector3(2.5, 0, 12)
	guide.dialogue_lines = PackedStringArray([
		"Welcome to Pleasant Park! Check the welcome sign, open a chest, then talk to me again.",
		"Nice exploring! Keep caring for your creature at Home, too.",
		"Rare chests sparkle blue. Legendary ones glow orange — check behind the fuel stop!",
	])
	var gshape := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(1.8, 2.2, 1.8)
	gshape.shape = gb
	guide.add_child(gshape)
	StylizedMesh.add_cylinder(guide, 0.35, 1.2, Color(0.3, 0.55, 0.45), Vector3(0, 0.7, 0), "Body", false, 12, 0.7)
	StylizedMesh.add_sphere(guide, 0.28, Color(0.96, 0.8, 0.65), Vector3(0, 1.5, 0), "Head", 12, 8, 0.6)
	StylizedMesh.add_box(guide, Vector3(0.7, 0.15, 0.4), Color(0.2, 0.45, 0.35), Vector3(0, 1.75, 0), "Hat", false, 0.65)
	pois.add_child(guide)


static func _add_discoverable(
	parent: Node3D,
	loc_id: StringName,
	loc_name: String,
	pos: Vector3,
	bits: int,
	message: String,
) -> void:
	var d := DiscoverableInteractable.new()
	d.name = "Discover_%s" % String(loc_id)
	d.location_id = loc_id
	d.location_name = loc_name
	d.discover_message = message
	d.bits_reward = bits
	d.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 2.4)
	shape.shape = box
	d.add_child(shape)
	parent.add_child(d)


static func _add_sign(root: Node3D, pos: Vector3, text: String) -> void:
	var sign := Node3D.new()
	sign.name = "WelcomeSign"
	sign.position = pos
	root.add_child(sign)
	StylizedMesh.add_cylinder(sign, 0.12, 2.4, Color(0.38, 0.26, 0.14), Vector3(-2.2, 1.2, 0), "PostL", true, 12, 0.75)
	StylizedMesh.add_cylinder(sign, 0.12, 2.4, Color(0.38, 0.26, 0.14), Vector3(2.2, 1.2, 0), "PostR", true, 12, 0.75)
	StylizedMesh.add_box(sign, Vector3(5.2, 1.4, 0.28), Color(0.16, 0.45, 0.26), Vector3(0, 2.1, 0), "Board", true, 0.7)
	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.position = Vector3(0, 2.1, 0.2)
	label.modulate = Color(0.98, 0.96, 0.85)
	label.outline_modulate = Color(0.1, 0.2, 0.12)
	label.outline_size = 8
	sign.add_child(label)

	## Primary tutorial discovery target for first_steps quest.
	var discover := DiscoverableInteractable.new()
	discover.name = "WelcomeDiscover"
	discover.location_id = &"park_welcome"
	discover.location_name = "Pleasant Park Welcome Sign"
	discover.discover_message = "Welcome to Pleasant Park! Explore houses, chests, and quiet corners."
	discover.bits_reward = 15
	discover.item_reward_id = &"park_map_fragment"
	discover.item_reward_qty = 1
	discover.position = Vector3(0, 1.2, 0.5)
	var dshape := CollisionShape3D.new()
	var db := BoxShape3D.new()
	db.size = Vector3(5.5, 2.5, 2.0)
	dshape.shape = db
	discover.add_child(dshape)
	sign.add_child(discover)
