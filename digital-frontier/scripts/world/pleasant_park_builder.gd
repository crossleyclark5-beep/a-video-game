class_name PleasantParkBuilder
extends RefCounted
## Pleasant Park — polished suburban starter town for Digital Frontier.
## Visual upgrade pass: terrain variation, unique houses, lived-in props, lamps.
## Preserves interact contracts: player_spawn, chests[], enterable_houses[] with DoorArea + roof_node.

const GROUND := Color(0.38, 0.62, 0.32)
const GRASS_A := Color(0.36, 0.68, 0.34)
const GRASS_B := Color(0.44, 0.72, 0.38)
const GRASS_C := Color(0.32, 0.58, 0.30)
const GRASS_D := Color(0.40, 0.66, 0.36)
const DIRT := Color(0.48, 0.36, 0.24)
const PARK_GREEN := Color(0.30, 0.70, 0.40)
const ROAD := Color(0.27, 0.27, 0.30)
const ROAD_EDGE := Color(0.22, 0.22, 0.24)
const SIDEWALK := Color(0.70, 0.70, 0.68)
const CURB := Color(0.58, 0.58, 0.55)
const PATH := Color(0.72, 0.62, 0.44)


static func build(root: Node3D) -> Dictionary:
	var result := {
		&"player_spawn": Vector3(0.0, 0.15, 10.0),
		&"chests": [],
		&"enterable_houses": [],
	}
	_add_terrain(root)
	_add_road_network(root)
	_add_central_park(root)
	_add_sports_field(root)
	_add_fuel_stop(root)
	_add_houses(root, result)
	_add_fences(root)
	_add_vegetation(root)
	_add_street_furniture(root)
	_add_parked_cars(root)
	_add_chests(root, result)
	_add_sign(root, Vector3(0.0, 0.0, 16.0), "PLEASANT PARK")
	_add_exploration_pois(root, result)
	return result


# --- Terrain -----------------------------------------------------------------

static func _add_terrain(root: Node3D) -> void:
	var terrain := Node3D.new()
	terrain.name = "Terrain"
	root.add_child(terrain)
	StylizedMesh.add_box(terrain, Vector3(90, 0.3, 90), GROUND, Vector3(0, -0.15, 0), "BaseGround", true, 0.9)

	## Larger soft grass fields with tone variation (terrain blending feel).
	var patches := [
		[Vector3(0, 0.02, 0), Vector3(22, 0.05, 22), PARK_GREEN],
		[Vector3(-20, 0.02, 8), Vector3(11, 0.045, 9), GRASS_A],
		[Vector3(18, 0.02, -10), Vector3(13, 0.045, 10), GRASS_B],
		[Vector3(-8, 0.02, 28), Vector3(15, 0.045, 11), GRASS_C],
		[Vector3(12, 0.02, 30), Vector3(11, 0.045, 9), GRASS_A],
		[Vector3(-28, 0.02, -12), Vector3(10, 0.045, 11), GRASS_B],
		[Vector3(30, 0.02, 18), Vector3(9, 0.045, 9), GRASS_C],
		[Vector3(-16, 0.02, -28), Vector3(8, 0.04, 7), GRASS_D],
		[Vector3(20, 0.02, 8), Vector3(7, 0.04, 6), GRASS_A],
		[Vector3(6, 0.02, -32), Vector3(9, 0.04, 6), GRASS_C],
	]
	for i in patches.size():
		var p: Array = patches[i]
		StylizedMesh.add_box(terrain, p[1], p[2], p[0], "GrassPatch_%d" % i, false, 0.88)

	## Dirt / worn patches near roads and yards.
	var dirt_spots := [
		[Vector3(-15, 0.025, -15), Vector3(3.5, 0.03, 2.2)],
		[Vector3(15, 0.025, 15), Vector3(2.8, 0.03, 2.5)],
		[Vector3(24, 0.025, -2), Vector3(4.0, 0.03, 2.0)],
		[Vector3(-22, 0.025, 18), Vector3(2.5, 0.03, 3.0)],
		[Vector3(8, 0.025, 18), Vector3(2.2, 0.03, 1.8)],
		[Vector3(-4, 0.025, -22), Vector3(3.0, 0.03, 2.0)],
	]
	for i in dirt_spots.size():
		var d: Array = dirt_spots[i]
		var tint := DIRT.lightened(0.04 * float(i % 3))
		StylizedMesh.add_box(terrain, d[1], tint, d[0], "Dirt_%d" % i, false, 0.95)

	## Tiny ground imperfections (pebbles / bare spots).
	for i in 14:
		var ang := float(i) * 2.3
		var r := 8.0 + float(i % 5) * 4.5
		var pos := Vector3(cos(ang) * r, 0.04, sin(ang) * r * 0.85)
		var s := 0.25 + float(i % 3) * 0.12
		StylizedMesh.add_box(terrain, Vector3(s, 0.04, s * 0.7), DIRT.darkened(0.08), pos, "Pebble_%d" % i, false, 0.95)


# --- Roads -------------------------------------------------------------------

static func _add_road_network(root: Node3D) -> void:
	var roads := Node3D.new()
	roads.name = "Roads"
	root.add_child(roads)
	_road_segment(roads, Vector3(0, 0.04, -15), Vector3(40, 0.08, 5.5), "RoadN", true)
	_road_segment(roads, Vector3(0, 0.04, 15), Vector3(40, 0.08, 5.5), "RoadS", true)
	_road_segment(roads, Vector3(-15, 0.04, 0), Vector3(5.5, 0.08, 35), "RoadW", false)
	_road_segment(roads, Vector3(15, 0.04, 0), Vector3(5.5, 0.08, 35), "RoadE", false)
	_sidewalk_ring(roads)
	_road_segment(roads, Vector3(24, 0.04, 0), Vector3(12, 0.08, 4.5), "RoadFuel", true)
	_add_crosswalk(roads, Vector3(0, 0.09, -15), true)
	_add_crosswalk(roads, Vector3(0, 0.09, 15), true)
	_add_crosswalk(roads, Vector3(-15, 0.09, 0), false)
	_add_crosswalk(roads, Vector3(15, 0.09, 0), false)
	## Driveway stubs into house yards.
	for dpos in [Vector3(-24, 0.05, -18), Vector3(24, 0.05, -18), Vector3(-20, 0.05, 0), Vector3(22, 0.05, 14)]:
		StylizedMesh.add_box(roads, Vector3(3.2, 0.05, 4.5), ROAD.lightened(0.06), dpos, "Drive", true, 0.9)


static func _road_segment(parent: Node3D, pos: Vector3, size: Vector3, node_name: String, along_x: bool) -> void:
	StylizedMesh.add_box(parent, size, ROAD, pos, node_name, true, 0.92)
	## Darker edge strips (wear / curb shadow).
	if along_x:
		StylizedMesh.add_box(parent, Vector3(size.x, 0.02, 0.2), ROAD_EDGE, pos + Vector3(0, 0.05, size.z * 0.45), node_name + "EdgeA", false, 0.95)
		StylizedMesh.add_box(parent, Vector3(size.x, 0.02, 0.2), ROAD_EDGE, pos + Vector3(0, 0.05, -size.z * 0.45), node_name + "EdgeB", false, 0.95)
		_dashed_line(parent, pos, size.x * 0.85, true, node_name)
	else:
		StylizedMesh.add_box(parent, Vector3(0.2, 0.02, size.z), ROAD_EDGE, pos + Vector3(size.x * 0.45, 0.05, 0), node_name + "EdgeA", false, 0.95)
		StylizedMesh.add_box(parent, Vector3(0.2, 0.02, size.z), ROAD_EDGE, pos + Vector3(-size.x * 0.45, 0.05, 0), node_name + "EdgeB", false, 0.95)
		_dashed_line(parent, pos, size.z * 0.85, false, node_name)


static func _dashed_line(parent: Node3D, center: Vector3, length: float, along_x: bool, prefix: String) -> void:
	var dash := 1.1
	var gap := 0.7
	var cursor := -length * 0.5
	var i := 0
	while cursor < length * 0.5:
		var seg := mini(dash, length * 0.5 - cursor)
		if along_x:
			StylizedMesh.add_box(parent, Vector3(seg, 0.015, 0.14), Color(0.88, 0.82, 0.35), center + Vector3(cursor + seg * 0.5, 0.055, 0), "%sDash_%d" % [prefix, i], false, 0.55)
		else:
			StylizedMesh.add_box(parent, Vector3(0.14, 0.015, seg), Color(0.88, 0.82, 0.35), center + Vector3(0, 0.055, cursor + seg * 0.5), "%sDash_%d" % [prefix, i], false, 0.55)
		cursor += dash + gap
		i += 1


static func _add_crosswalk(parent: Node3D, pos: Vector3, road_along_x: bool) -> void:
	for i in 5:
		var o := float(i - 2) * 0.7
		if road_along_x:
			StylizedMesh.add_box(parent, Vector3(0.45, 0.02, 3.6), Color(0.92, 0.92, 0.88), pos + Vector3(o, 0, 0), "Xing", false, 0.6)
		else:
			StylizedMesh.add_box(parent, Vector3(3.6, 0.02, 0.45), Color(0.92, 0.92, 0.88), pos + Vector3(0, 0, o), "Xing", false, 0.6)


static func _sidewalk_ring(parent: Node3D) -> void:
	StylizedMesh.add_box(parent, Vector3(28, 0.07, 1.6), SIDEWALK, Vector3(0, 0.05, -11.2), "WalkN", true, 0.85)
	StylizedMesh.add_box(parent, Vector3(28, 0.07, 1.6), SIDEWALK, Vector3(0, 0.05, 11.2), "WalkS", true, 0.85)
	StylizedMesh.add_box(parent, Vector3(1.6, 0.07, 24), SIDEWALK, Vector3(-11.2, 0.05, 0), "WalkW", true, 0.85)
	StylizedMesh.add_box(parent, Vector3(1.6, 0.07, 24), SIDEWALK, Vector3(11.2, 0.05, 0), "WalkE", true, 0.85)
	StylizedMesh.add_box(parent, Vector3(42, 0.07, 1.4), SIDEWALK, Vector3(0, 0.05, -18.5), "WalkOuterN", true, 0.85)
	StylizedMesh.add_box(parent, Vector3(42, 0.07, 1.4), SIDEWALK, Vector3(0, 0.05, 18.5), "WalkOuterS", true, 0.85)
	StylizedMesh.add_box(parent, Vector3(1.4, 0.07, 38), SIDEWALK, Vector3(-18.5, 0.05, 0), "WalkOuterW", true, 0.85)
	StylizedMesh.add_box(parent, Vector3(1.4, 0.07, 38), SIDEWALK, Vector3(18.5, 0.05, 0), "WalkOuterE", true, 0.85)
	## Curb lips
	for c in [
		[Vector3(0, 0.02, -10.3), Vector3(28, 0.12, 0.25)],
		[Vector3(0, 0.02, 10.3), Vector3(28, 0.12, 0.25)],
		[Vector3(-10.3, 0.02, 0), Vector3(0.25, 0.12, 22)],
		[Vector3(10.3, 0.02, 0), Vector3(0.25, 0.12, 22)],
	]:
		StylizedMesh.add_box(parent, c[1], CURB, c[0], "Curb", false, 0.8)


# --- Central park ------------------------------------------------------------

static func _add_central_park(root: Node3D) -> void:
	var park := Node3D.new()
	park.name = "CentralPark"
	root.add_child(park)
	StylizedMesh.add_box(park, Vector3(20, 0.08, 20), PARK_GREEN, Vector3(0, 0.05, 0), "Lawn", true, 0.88)
	## Path with edge wear
	StylizedMesh.add_box(park, Vector3(2.4, 0.04, 18), PATH, Vector3(0, 0.08, 0), "PathNS", false, 0.82)
	StylizedMesh.add_box(park, Vector3(18, 0.04, 2.4), PATH, Vector3(0, 0.08, 0), "PathEW", false, 0.82)
	StylizedMesh.add_box(park, Vector3(2.8, 0.02, 18.2), PATH.darkened(0.1), Vector3(0, 0.07, 0), "PathEdgeNS", false, 0.9)

	var gazebo := Node3D.new()
	gazebo.name = "Gazebo"
	park.add_child(gazebo)
	for offset in [Vector3(-2.2, 1.3, -2.2), Vector3(2.2, 1.3, -2.2), Vector3(-2.2, 1.3, 2.2), Vector3(2.2, 1.3, 2.2)]:
		StylizedMesh.add_cylinder(gazebo, 0.16, 2.6, Color(0.72, 0.52, 0.30), offset, "Post", true, 14, 0.7)
	StylizedMesh.add_box(gazebo, Vector3(6.4, 0.18, 6.4), Color(0.68, 0.26, 0.22), Vector3(0, 2.65, 0), "RoofDeck", false, 0.65)
	StylizedMesh.add_box(gazebo, Vector3(4.2, 0.5, 4.2), Color(0.60, 0.20, 0.18), Vector3(0, 3.05, 0), "RoofPeak", false, 0.65)
	StylizedMesh.add_cylinder(gazebo, 2.5, 0.14, Color(0.68, 0.52, 0.34), Vector3(0, 0.14, 0), "Floor", true, 16, 0.75)
	## Gazebo railing
	for z in [-2.3, 2.3]:
		StylizedMesh.add_box(gazebo, Vector3(4.2, 0.08, 0.08), Color(0.75, 0.55, 0.32), Vector3(0, 1.0, z), "Rail", false, 0.7)

	_picnic_set(park, Vector3(-6.5, 0, -5.5))
	_picnic_set(park, Vector3(6.5, 0, 5.5))
	_picnic_set(park, Vector3(-5.5, 0, 6.0))

	var fountain := Node3D.new()
	fountain.name = "Fountain"
	park.add_child(fountain)
	StylizedMesh.add_cylinder(fountain, 1.7, 0.3, Color(0.72, 0.72, 0.76), Vector3(0, 0.22, 0), "Basin", true, 18, 0.45)
	StylizedMesh.add_cylinder(fountain, 1.4, 0.2, Color(0.45, 0.68, 0.9), Vector3(0, 0.35, 0), "Water", false, 16, 0.15)
	StylizedMesh.add_cylinder(fountain, 0.32, 1.15, Color(0.68, 0.68, 0.72), Vector3(0, 0.9, 0), "Spire", false, 12, 0.4)
	StylizedMesh.add_sphere(fountain, 0.38, Color(0.5, 0.75, 0.98), Vector3(0, 1.55, 0), "WaterTop", 12, 8, 0.12)
	## Rim stones
	for i in 6:
		var a := float(i) / 6.0 * TAU
		StylizedMesh.add_box(fountain, Vector3(0.35, 0.18, 0.25), Color(0.65, 0.65, 0.68), Vector3(cos(a) * 1.85, 0.35, sin(a) * 1.85), "Rim", false, 0.7)

	## Playground corner
	var play := Node3D.new()
	play.name = "Playground"
	play.position = Vector3(7, 0, -7)
	park.add_child(play)
	StylizedMesh.add_box(play, Vector3(4.5, 0.06, 4.0), Color(0.78, 0.62, 0.38), Vector3(0, 0.06, 0), "Sand", true, 0.9)
	StylizedMesh.add_box(play, Vector3(0.15, 1.6, 0.15), Color(0.85, 0.35, 0.3), Vector3(-1.2, 0.9, 0), "SwingPostL", true, 0.5)
	StylizedMesh.add_box(play, Vector3(0.15, 1.6, 0.15), Color(0.85, 0.35, 0.3), Vector3(1.2, 0.9, 0), "SwingPostR", true, 0.5)
	StylizedMesh.add_box(play, Vector3(2.6, 0.1, 0.12), Color(0.8, 0.3, 0.25), Vector3(0, 1.65, 0), "SwingBeam", false, 0.5)
	StylizedMesh.add_box(play, Vector3(0.5, 0.08, 0.25), Color(0.2, 0.45, 0.8), Vector3(0, 0.7, 0), "Seat", false, 0.6)
	StylizedMesh.add_cylinder(play, 0.55, 0.7, Color(0.95, 0.55, 0.2), Vector3(0, 0.45, 1.3), "SlideBase", true, 12, 0.55)
	StylizedMesh.add_box(play, Vector3(0.7, 0.08, 1.4), Color(0.9, 0.5, 0.2), Vector3(0, 0.85, 0.6), "Slide", false, 0.5)


static func _picnic_set(parent: Node3D, pos: Vector3) -> void:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	StylizedMesh.add_box(p, Vector3(2.4, 0.12, 1.1), Color(0.52, 0.34, 0.18), Vector3(0, 0.55, 0), "Table", false, 0.72)
	StylizedMesh.add_box(p, Vector3(0.14, 0.55, 0.14), Color(0.38, 0.24, 0.12), Vector3(-0.9, 0.28, -0.35), "Leg1", false, 0.75)
	StylizedMesh.add_box(p, Vector3(0.14, 0.55, 0.14), Color(0.38, 0.24, 0.12), Vector3(0.9, 0.28, 0.35), "Leg2", false, 0.75)
	StylizedMesh.add_box(p, Vector3(2.2, 0.1, 0.45), Color(0.48, 0.30, 0.16), Vector3(0, 0.35, -1.0), "BenchA", false, 0.72)
	StylizedMesh.add_box(p, Vector3(2.2, 0.1, 0.45), Color(0.48, 0.30, 0.16), Vector3(0, 0.35, 1.0), "BenchB", false, 0.72)


# --- Sports / fuel -----------------------------------------------------------

static func _add_sports_field(root: Node3D) -> void:
	var field := Node3D.new()
	field.name = "SportsField"
	field.position = Vector3(0, 0, 26)
	root.add_child(field)
	StylizedMesh.add_box(field, Vector3(18, 0.06, 12), Color(0.28, 0.58, 0.28), Vector3(0, 0.06, 0), "Pitch", true, 0.88)
	StylizedMesh.add_box(field, Vector3(0.12, 0.02, 12), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 0), "MidLine", false, 0.55)
	StylizedMesh.add_cylinder(field, 1.25, 0.03, Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 0), "CenterCircle", false, 16, 0.55)
	StylizedMesh.add_box(field, Vector3(18.2, 0.02, 0.12), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, -6), "EndLineS", false, 0.55)
	StylizedMesh.add_box(field, Vector3(18.2, 0.02, 0.12), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 6), "EndLineN", false, 0.55)
	for z in [-6.0, 6.0]:
		var goal := Node3D.new()
		goal.position = Vector3(0, 0, z)
		field.add_child(goal)
		StylizedMesh.add_box(goal, Vector3(0.15, 2.0, 0.15), Color(0.92, 0.92, 0.95), Vector3(-2, 1.0, 0), "PostL", true, 0.4)
		StylizedMesh.add_box(goal, Vector3(0.15, 2.0, 0.15), Color(0.92, 0.92, 0.95), Vector3(2, 1.0, 0), "PostR", true, 0.4)
		StylizedMesh.add_box(goal, Vector3(4.15, 0.15, 0.15), Color(0.92, 0.92, 0.95), Vector3(0, 2.0, 0), "Crossbar", false, 0.4)
	## Tiered bleachers with rails
	for i in 3:
		StylizedMesh.add_box(field, Vector3(6.2, 0.35, 1.15), Color(0.52, 0.2, 0.16), Vector3(10.2 + float(i) * 0.25, 0.35 + float(i) * 0.4, 0), "Bleacher%d" % i, true, 0.7)
	StylizedMesh.add_box(field, Vector3(0.1, 1.4, 3.2), Color(0.75, 0.75, 0.72), Vector3(11.5, 1.0, 0), "BleacherRail", false, 0.5)


static func _add_fuel_stop(root: Node3D) -> void:
	var fuel := Node3D.new()
	fuel.name = "FuelStop"
	fuel.position = Vector3(30, 0, 0)
	root.add_child(fuel)
	StylizedMesh.add_box(fuel, Vector3(12, 0.12, 10), Color(0.24, 0.24, 0.26), Vector3(0, 0.08, 0), "Lot", true, 0.92)
	## Parking stall marks
	for i in 3:
		StylizedMesh.add_box(fuel, Vector3(0.08, 0.02, 2.2), Color(0.9, 0.9, 0.85), Vector3(-4 + float(i) * 2.2, 0.14, -3.2), "Stall", false, 0.55)
	StylizedMesh.add_box(fuel, Vector3(7.5, 3.4, 5.5), Color(0.86, 0.76, 0.30), Vector3(1.5, 1.7, 1.5), "Shop", true, 0.75)
	StylizedMesh.add_box(fuel, Vector3(8.4, 0.32, 6.4), Color(0.72, 0.18, 0.16), Vector3(1.5, 3.55, 1.5), "ShopRoof", false, 0.65)
	StylizedMesh.add_window_pane(fuel, Vector3(1.5, 1.5, 0.08), Vector3(1.5, 1.8, 4.28), "ShopWindow")
	StylizedMesh.add_box(fuel, Vector3(8, 0.22, 5), Color(0.2, 0.2, 0.22), Vector3(-1, 3.4, -2), "Canopy", false, 0.55)
	StylizedMesh.add_cylinder(fuel, 0.18, 3.2, Color(0.42, 0.42, 0.45), Vector3(-3, 1.6, -2), "CanopyPost1", true, 12, 0.45)
	StylizedMesh.add_cylinder(fuel, 0.18, 3.2, Color(0.42, 0.42, 0.45), Vector3(1, 1.6, -2), "CanopyPost2", true, 12, 0.45)
	StylizedMesh.add_box(fuel, Vector3(0.75, 1.45, 0.55), Color(0.82, 0.22, 0.18), Vector3(-3, 0.8, -2.8), "Pump1", true, 0.5)
	StylizedMesh.add_box(fuel, Vector3(0.75, 1.45, 0.55), Color(0.82, 0.22, 0.18), Vector3(1, 0.8, -2.8), "Pump2", true, 0.5)
	StylizedMesh.add_box(fuel, Vector3(0.2, 0.15, 0.15), Color(0.15, 0.15, 0.15), Vector3(-3, 1.4, -2.5), "Nozzle1", false, 0.4)
	StylizedMesh.add_box(fuel, Vector3(2.6, 1.9, 0.28), Color(0.12, 0.42, 0.22), Vector3(1.5, 2.5, 4.4), "PriceSign", false, 0.6)
	## Trash + air pump prop
	StylizedMesh.add_cylinder(fuel, 0.28, 0.75, Color(0.32, 0.38, 0.32), Vector3(4.5, 0.4, 3.5), "Bin", true, 12, 0.7)
	StylizedMesh.add_cylinder(fuel, 0.15, 1.1, Color(0.85, 0.85, 0.2), Vector3(-5, 0.55, 2), "AirPump", true, 10, 0.5)


# --- Houses ------------------------------------------------------------------

static func _add_houses(root: Node3D, result: Dictionary) -> void:
	var specs := [
		{"name": "BrickHouse", "pos": Vector3(-24, 0, -24), "color": Color(0.68, 0.34, 0.28), "roof": Color(0.34, 0.22, 0.18), "enterable": true, "yaw": 45.0, "style": &"brick"},
		{"name": "YellowHouse", "pos": Vector3(0, 0, -28), "color": Color(0.90, 0.78, 0.28), "roof": Color(0.42, 0.26, 0.14), "enterable": false, "yaw": 0.0, "style": &"cottage"},
		{"name": "WhiteHouse", "pos": Vector3(24, 0, -24), "color": Color(0.92, 0.92, 0.88), "roof": Color(0.32, 0.38, 0.48), "enterable": false, "yaw": -45.0, "style": &"colonial"},
		{"name": "GreenHouse", "pos": Vector3(-28, 0, 0), "color": Color(0.28, 0.58, 0.36), "roof": Color(0.22, 0.28, 0.20), "enterable": true, "yaw": 90.0, "style": &"garden"},
		{"name": "ModernHouse", "pos": Vector3(28, 0, 14), "color": Color(0.36, 0.55, 0.85), "roof": Color(0.18, 0.22, 0.32), "enterable": false, "yaw": -90.0, "style": &"modern"},
		{"name": "CoralHouse", "pos": Vector3(-24, 0, 24), "color": Color(0.88, 0.50, 0.42), "roof": Color(0.38, 0.24, 0.18), "enterable": false, "yaw": 135.0, "style": &"bungalow"},
		{"name": "SkyHouse", "pos": Vector3(0, 0, 36), "color": Color(0.52, 0.75, 0.90), "roof": Color(0.28, 0.32, 0.38), "enterable": false, "yaw": 180.0, "style": &"ranch"},
		{"name": "LavenderHouse", "pos": Vector3(24, 0, 24), "color": Color(0.70, 0.56, 0.86), "roof": Color(0.32, 0.24, 0.38), "enterable": false, "yaw": -135.0, "style": &"victorian"},
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

	## Yard with subtle tone
	var yard_tint := Color(0.40, 0.66, 0.36)
	if style == &"garden":
		yard_tint = Color(0.34, 0.62, 0.32)
	elif style == &"modern":
		yard_tint = Color(0.42, 0.58, 0.40)
	StylizedMesh.add_box(house, Vector3(11, 0.05, 10), yard_tint, Vector3(0, 0.03, 0), "Yard", false, 0.88)

	## Driveway
	StylizedMesh.add_box(house, Vector3(3.0, 0.04, 4.2), ROAD.lightened(0.08), Vector3(4.2, 0.04, 3.5), "Driveway", true, 0.9)

	## Main body + foundation
	StylizedMesh.add_box(house, Vector3(7.6, 0.25, 6.3), Color(0.55, 0.52, 0.48), Vector3(0, 0.12, 0), "Foundation", false, 0.85)
	StylizedMesh.add_box(house, Vector3(7.5, 3.4, 6.2), wall, Vector3(0, 1.7, 0), "Body", true, 0.78)

	## Garage
	StylizedMesh.add_box(house, Vector3(3.2, 2.4, 4.5), wall.darkened(0.05), Vector3(5.0, 1.2, -0.5), "Garage", true, 0.78)
	StylizedMesh.add_box(house, Vector3(2.7, 1.85, 0.1), Color(0.22, 0.25, 0.32), Vector3(5.0, 1.1, 1.78), "GarageDoor", false, 0.55)
	StylizedMesh.add_box(house, Vector3(0.15, 0.15, 0.12), Color(0.7, 0.7, 0.2), Vector3(5.9, 1.1, 1.85), "GarageHandle", false, 0.4)

	## Porch
	StylizedMesh.add_box(house, Vector3(3.6, 0.22, 1.9), Color(0.62, 0.52, 0.38), Vector3(0, 0.2, 3.6), "Porch", true, 0.75)
	var post_color := Color(0.88, 0.88, 0.82) if style != &"modern" else Color(0.35, 0.38, 0.45)
	StylizedMesh.add_cylinder(house, 0.1, 2.0, post_color, Vector3(-1.35, 1.2, 4.25), "PorchPostL", true, 12, 0.55)
	StylizedMesh.add_cylinder(house, 0.1, 2.0, post_color, Vector3(1.35, 1.2, 4.25), "PorchPostR", true, 12, 0.55)
	StylizedMesh.add_box(house, Vector3(3.7, 0.14, 2.05), roof_c, Vector3(0, 2.25, 3.6), "PorchRoof", false, 0.68)

	## Roof (named Roof for enterable fade) + eaves / gutters
	var roof_mi := MeshInstance3D.new()
	roof_mi.name = "Roof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(8.5, 0.65, 7.3)
	roof_mi.mesh = roof_mesh
	if enterable:
		roof_mi.material_override = StylizedMesh.make_transparent_material(roof_c)
	else:
		roof_mi.material_override = StylizedMesh.make_material(roof_c, 0.68)
	roof_mi.position = Vector3(0, 3.72, 0)
	house.add_child(roof_mi)
	StylizedMesh.add_box(house, Vector3(5.2, 0.85, 4.6), roof_c.darkened(0.1), Vector3(0, 4.28, 0), "RoofPeak", false, 0.68)
	StylizedMesh.add_box(house, Vector3(8.7, 0.08, 0.12), Color(0.45, 0.45, 0.48), Vector3(0, 3.35, 3.55), "GutterF", false, 0.4)
	StylizedMesh.add_box(house, Vector3(8.7, 0.08, 0.12), Color(0.45, 0.45, 0.48), Vector3(0, 3.35, -3.55), "GutterB", false, 0.4)
	StylizedMesh.add_cylinder(house, 0.05, 3.2, Color(0.45, 0.45, 0.48), Vector3(-4.1, 1.7, 3.5), "Downspout", false, 8, 0.4)

	## Chimney with cap
	StylizedMesh.add_box(house, Vector3(0.75, 1.5, 0.75), Color(0.48, 0.32, 0.26), Vector3(-2.5, 4.65, -1.5), "Chimney", true, 0.75)
	StylizedMesh.add_box(house, Vector3(0.95, 0.12, 0.95), Color(0.35, 0.32, 0.3), Vector3(-2.5, 5.4, -1.5), "ChimneyCap", false, 0.55)

	## Door with frame + knob
	StylizedMesh.add_box(house, Vector3(1.35, 2.25, 0.08), Color(0.55, 0.42, 0.28), Vector3(0, 1.2, 3.12), "DoorFrame", false, 0.7)
	StylizedMesh.add_box(house, Vector3(1.1, 2.05, 0.1), Color(0.30, 0.18, 0.12), Vector3(0, 1.15, 3.16), "Door", false, 0.65)
	StylizedMesh.add_sphere(house, 0.05, Color(0.85, 0.75, 0.3), Vector3(0.4, 1.15, 3.25), "Knob", 8, 6, 0.3)

	## Windows with glass
	StylizedMesh.add_window_pane(house, Vector3(1.25, 1.05, 0.08), Vector3(-2.2, 2.0, 3.14), "WinL")
	StylizedMesh.add_window_pane(house, Vector3(1.25, 1.05, 0.08), Vector3(2.2, 2.0, 3.14), "WinR")
	StylizedMesh.add_window_pane(house, Vector3(1.0, 0.85, 0.08), Vector3(-2.0, 2.2, -3.14), "WinBack")
	StylizedMesh.add_window_pane(house, Vector3(0.9, 0.8, 0.08), Vector3(2.2, 2.0, -3.14), "WinBackR")

	## Mailbox
	StylizedMesh.add_cylinder(house, 0.05, 0.85, Color(0.35, 0.35, 0.38), Vector3(2.9, 0.42, 5.3), "MailPost", true, 8, 0.5)
	StylizedMesh.add_box(house, Vector3(0.4, 0.28, 0.22), Color(0.18, 0.32, 0.62), Vector3(2.9, 0.95, 5.3), "Mailbox", false, 0.55)

	_apply_house_style(house, style, wall, roof_c)

	if enterable:
		var door := Interactable.new()
		door.name = "DoorInteractable"
		door.position = Vector3(0, 1.0, 4.2)
		door.prompt_text = "Press E to enter %s" % house_name
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.8, 2.6, 2.4)
		shape.shape = box
		door.add_child(shape)
		house.add_child(door)
		var exit_m := Marker3D.new()
		exit_m.name = "ExteriorExit"
		exit_m.position = Vector3(0, 0.15, 5.5)
		house.add_child(exit_m)
		var entry_m := Marker3D.new()
		entry_m.name = "InteriorEntry"
		entry_m.position = Vector3(0, 0.15, 0.4)
		house.add_child(entry_m)
		if house_name != "BrickHouse":
			StylizedMesh.add_box(house, Vector3(6.6, 0.08, 5.4), Color(0.60, 0.46, 0.32), Vector3(0, 0.18, 0), "InteriorFloor", false, 0.8)
			StylizedMesh.add_box(house, Vector3(1.6, 0.7, 0.8), Color(0.38, 0.24, 0.14), Vector3(-1.8, 0.55, -1.2), "Table", false, 0.7)
			StylizedMesh.add_box(house, Vector3(1.0, 1.5, 0.45), Color(0.48, 0.34, 0.62), Vector3(2.2, 0.95, -1.5), "Shelf", false, 0.7)
		var body_node := house.get_node_or_null("Body")
		if body_node is StaticBody3D:
			(body_node as StaticBody3D).collision_layer = 0
		house.set_script(load("res://scripts/systems/buildings/building_volume.gd"))
		house.set("building_id", StringName(house_name.to_snake_case()))
		house.set("display_name", house_name)
		house.set("roof_paths", [NodePath("Roof")])
		if house_name == "BrickHouse":
			house.set("interior_scene", load("res://scenes/world/buildings/interiors/test_house_interior.tscn"))

	return house


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
			StylizedMesh.add_box(house, Vector3(1.2, 0.3, 0.4), Color(0.4, 0.28, 0.16), Vector3(-2.2, 1.35, 3.35), "FlowerBox", false, 0.75)
			StylizedMesh.add_sphere(house, 0.15, Color(0.9, 0.35, 0.5), Vector3(-2.2, 1.55, 3.4), "Flower", 8, 6, 0.7)
			StylizedMesh.add_sphere(house, 0.12, Color(0.95, 0.8, 0.2), Vector3(-1.95, 1.52, 3.4), "Flower2", 8, 6, 0.7)
		&"colonial":
			StylizedMesh.add_cylinder(house, 0.14, 2.2, Color(0.9, 0.9, 0.88), Vector3(-1.8, 1.3, 3.9), "ColumnL", true, 12, 0.5)
			StylizedMesh.add_cylinder(house, 0.14, 2.2, Color(0.9, 0.9, 0.88), Vector3(1.8, 1.3, 3.9), "ColumnR", true, 12, 0.5)
			_shutters(house, Vector3(-2.2, 2.0, 3.2), Color(0.15, 0.2, 0.35))
			_shutters(house, Vector3(2.2, 2.0, 3.2), Color(0.15, 0.2, 0.35))
		&"garden":
			StylizedMesh.add_box(house, Vector3(2.8, 0.3, 1.2), Color(0.4, 0.28, 0.16), Vector3(-3.5, 0.2, 3.8), "GardenBed", true, 0.8)
			for i in 4:
				StylizedMesh.add_sphere(house, 0.18, Color(0.85, 0.3 + float(i) * 0.1, 0.4), Vector3(-4.2 + float(i) * 0.5, 0.5, 3.8), "Bloom", 8, 6, 0.7)
			StylizedMesh.add_box(house, Vector3(1.6, 1.4, 1.2), Color(0.45, 0.32, 0.18), Vector3(-4.5, 0.8, -2.5), "Shed", true, 0.75)
			StylizedMesh.add_box(house, Vector3(1.8, 0.2, 1.4), Color(0.3, 0.25, 0.18), Vector3(-4.5, 1.55, -2.5), "ShedRoof", false, 0.7)
		&"modern":
			StylizedMesh.add_box(house, Vector3(3.2, 1.4, 0.12), Color(0.2, 0.22, 0.28), Vector3(-1.5, 2.2, 3.18), "RibbonWinFrame", false, 0.45)
			var glass := MeshInstance3D.new()
			glass.name = "RibbonGlass"
			var gm := BoxMesh.new()
			gm.size = Vector3(3.0, 1.2, 0.06)
			glass.mesh = gm
			glass.material_override = StylizedMesh.make_glass_material(Color(0.4, 0.7, 0.95, 0.65))
			glass.position = Vector3(-1.5, 2.2, 3.22)
			house.add_child(glass)
			StylizedMesh.add_box(house, Vector3(2.0, 0.08, 1.2), Color(0.15, 0.15, 0.18), Vector3(2.5, 4.6, 0), "Solar", false, 0.35)
		&"bungalow":
			StylizedMesh.add_box(house, Vector3(2.0, 0.5, 1.0), Color(0.55, 0.4, 0.28), Vector3(3.5, 0.35, 4.0), "PorchSwing", false, 0.7)
			StylizedMesh.add_sphere(house, 0.35, Color(0.2, 0.5, 0.25), Vector3(-4.0, 0.4, 2.0), "Bush", 10, 8, 0.85)
		&"ranch":
			StylizedMesh.add_box(house, Vector3(1.4, 0.9, 0.5), Color(0.2, 0.25, 0.3), Vector3(-3.5, 0.5, 4.5), "BikeRack", false, 0.5)
			StylizedMesh.add_cylinder(house, 0.28, 0.08, Color(0.15, 0.15, 0.15), Vector3(-3.2, 0.35, 4.5), "Wheel", false, 12, 0.4)
			StylizedMesh.add_box(house, Vector3(1.6, 0.06, 0.9), Color(0.25, 0.28, 0.35), Vector3(2.0, 4.55, 0.5), "SolarPanel", false, 0.35)
		&"victorian":
			StylizedMesh.add_box(house, Vector3(0.15, 2.2, 1.4), Color(0.55, 0.4, 0.65), Vector3(-3.9, 1.2, 2.5), "Trellis", false, 0.7)
			StylizedMesh.add_sphere(house, 0.2, Color(0.85, 0.4, 0.7), Vector3(-3.9, 1.8, 2.2), "Rose", 8, 6, 0.65)
			StylizedMesh.add_cylinder(house, 0.45, 0.25, Color(0.55, 0.55, 0.6), Vector3(3.8, 0.2, 4.2), "BirdBath", true, 12, 0.45)
			StylizedMesh.add_cylinder(house, 0.12, 0.7, Color(0.5, 0.5, 0.55), Vector3(3.8, 0.55, 4.2), "BathStem", false, 8, 0.45)
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
	_fence_line(fences, Vector3(-10, 0, -10), Vector3(10, 0, -10), 8)
	_fence_line(fences, Vector3(-10, 0, 10), Vector3(10, 0, 10), 8)
	_fence_line(fences, Vector3(-10, 0, -10), Vector3(-10, 0, 10), 8)
	_fence_line(fences, Vector3(10, 0, -10), Vector3(10, 0, 10), 8)
	_fence_line(fences, Vector3(-9, 0, 20), Vector3(-9, 0, 32), 6)
	_fence_line(fences, Vector3(9, 0, 20), Vector3(9, 0, 32), 6)


static func _fence_line(parent: Node3D, a: Vector3, b: Vector3, posts: int) -> void:
	for i in range(posts):
		var t := float(i) / float(maxi(posts - 1, 1))
		var p := a.lerp(b, t)
		StylizedMesh.add_box(parent, Vector3(0.12, 0.95, 0.12), Color(0.72, 0.72, 0.68), p + Vector3(0, 0.48, 0), "FencePost", true, 0.7)
	var mid := a.lerp(b, 0.5)
	var length := a.distance_to(b)
	var delta := b - a
	var rail_size := Vector3(length, 0.08, 0.08) if absf(delta.x) >= absf(delta.z) else Vector3(0.08, 0.08, length)
	StylizedMesh.add_box(parent, rail_size, Color(0.68, 0.68, 0.64), mid + Vector3(0, 0.75, 0), "FenceRail", false, 0.7)
	StylizedMesh.add_box(parent, rail_size, Color(0.68, 0.68, 0.64), mid + Vector3(0, 0.4, 0), "FenceRailLow", false, 0.7)


static func _add_vegetation(root: Node3D) -> void:
	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	## Mixed species / sizes — avoid uniform copy-paste.
	var tree_specs := [
		{"pos": Vector3(-7, 0, -7), "kind": &"oak", "scale": 1.05},
		{"pos": Vector3(7, 0, -6), "kind": &"round", "scale": 0.9},
		{"pos": Vector3(-8, 0, 6), "kind": &"pine", "scale": 1.15},
		{"pos": Vector3(8, 0, 7), "kind": &"oak", "scale": 0.95},
		{"pos": Vector3(-19, 0, -11), "kind": &"pine", "scale": 1.0},
		{"pos": Vector3(19, 0, -13), "kind": &"round", "scale": 1.1},
		{"pos": Vector3(-32, 0, 8), "kind": &"oak", "scale": 1.2},
		{"pos": Vector3(34, 0, -6), "kind": &"pine", "scale": 0.85},
		{"pos": Vector3(-14, 0, 30), "kind": &"round", "scale": 1.0},
		{"pos": Vector3(14, 0, 32), "kind": &"oak", "scale": 0.88},
		{"pos": Vector3(6, 0, -20), "kind": &"pine", "scale": 1.05},
		{"pos": Vector3(-6, 0, 20), "kind": &"round", "scale": 0.92},
		{"pos": Vector3(-22, 0, 12), "kind": &"oak", "scale": 1.0},
		{"pos": Vector3(22, 0, -8), "kind": &"pine", "scale": 1.1},
		{"pos": Vector3(8, 0, 22), "kind": &"round", "scale": 0.8},
		{"pos": Vector3(-30, 0, -20), "kind": &"oak", "scale": 1.15},
		{"pos": Vector3(12, 0, 8), "kind": &"pine", "scale": 0.75},
		{"pos": Vector3(-12, 0, -22), "kind": &"round", "scale": 1.05},
		{"pos": Vector3(26, 0, 6), "kind": &"oak", "scale": 0.9},
		{"pos": Vector3(-26, 0, 30), "kind": &"pine", "scale": 1.0},
	]
	for i in tree_specs.size():
		var s: Dictionary = tree_specs[i]
		_tree(trees, s["pos"], s["kind"], float(s["scale"]), i)

	var bushes := Node3D.new()
	bushes.name = "Bushes"
	root.add_child(bushes)
	var bush_spots := [
		Vector3(-5, 0, -11), Vector3(5, 0, 11), Vector3(-11, 0, 3), Vector3(11, 0, -4),
		Vector3(-20, 0, -20), Vector3(20, 0, 20), Vector3(18, 0, -26), Vector3(-18, 0, 26),
		Vector3(3, 0, -8), Vector3(-3, 0, 8), Vector3(32, 0, 8), Vector3(-32, 0, -4),
	]
	for i in bush_spots.size():
		_bush(bushes, bush_spots[i], i)

	var rocks := Node3D.new()
	rocks.name = "Rocks"
	root.add_child(rocks)
	for i in 10:
		var a := float(i) * 1.7
		var pos := Vector3(cos(a) * (12 + float(i)), 0.08, sin(a) * (9 + float(i % 4) * 2))
		var c := Color(0.5, 0.48, 0.45).darkened(0.05 * float(i % 3))
		StylizedMesh.add_box(rocks, Vector3(0.4 + float(i % 3) * 0.15, 0.2 + float(i % 2) * 0.1, 0.35), c, pos, "Rock_%d" % i, false, 0.9)

	## Fallen leaves clusters
	var leaves := Node3D.new()
	leaves.name = "FallenLeaves"
	root.add_child(leaves)
	for i in 12:
		var pos := Vector3(-6 + float(i % 4) * 4.0, 0.05, -5 + float(i / 4) * 5.0)
		var lc := Color(0.75, 0.45, 0.2) if i % 2 == 0 else Color(0.7, 0.55, 0.15)
		StylizedMesh.add_box(leaves, Vector3(0.5, 0.02, 0.35), lc, pos, "Leaf_%d" % i, false, 0.95)

	## Flower beds scattered
	_flower_bed(root, Vector3(-5, 0, -9))
	_flower_bed(root, Vector3(6, 0, 9))
	_flower_bed(root, Vector3(-9, 0, 5))


static func _tree(parent: Node3D, pos: Vector3, kind: StringName, scale_v: float, idx: int) -> void:
	var tree := Node3D.new()
	tree.name = "Tree_%d" % idx
	tree.position = pos
	tree.rotation_degrees.y = float(idx * 37 % 360)
	parent.add_child(tree)
	var trunk_c := Color(0.40, 0.26, 0.14) if kind != &"pine" else Color(0.35, 0.24, 0.14)
	StylizedMesh.add_cylinder(tree, 0.2 * scale_v, 1.7 * scale_v, trunk_c, Vector3(0, 0.85 * scale_v, 0), "Trunk", true, 12, 0.8)
	match kind:
		&"pine":
			var leaf := Color(0.18, 0.42, 0.24)
			StylizedMesh.add_cylinder(tree, 1.0 * scale_v, 1.4 * scale_v, leaf, Vector3(0, 2.0 * scale_v, 0), "Canopy1", false, 10, 0.85)
			StylizedMesh.add_cylinder(tree, 0.7 * scale_v, 1.1 * scale_v, leaf.lightened(0.05), Vector3(0, 2.9 * scale_v, 0), "Canopy2", false, 10, 0.85)
			StylizedMesh.add_cylinder(tree, 0.4 * scale_v, 0.8 * scale_v, leaf.lightened(0.1), Vector3(0, 3.6 * scale_v, 0), "Canopy3", false, 10, 0.85)
		&"oak":
			var leaf := Color(0.22, 0.52, 0.26) if idx % 2 == 0 else Color(0.26, 0.58, 0.30)
			StylizedMesh.add_sphere(tree, 1.2 * scale_v, leaf, Vector3(0, 2.4 * scale_v, 0), "Canopy", 14, 10, 0.85)
			StylizedMesh.add_sphere(tree, 0.85 * scale_v, leaf.lightened(0.06), Vector3(0.45 * scale_v, 2.7 * scale_v, 0.25), "Canopy2", 12, 8, 0.85)
			StylizedMesh.add_sphere(tree, 0.7 * scale_v, leaf.darkened(0.05), Vector3(-0.4 * scale_v, 2.5 * scale_v, -0.3), "Canopy3", 12, 8, 0.85)
		_:
			var leaf := Color(0.28, 0.60, 0.32)
			StylizedMesh.add_sphere(tree, 1.05 * scale_v, leaf, Vector3(0, 2.2 * scale_v, 0), "Canopy", 14, 10, 0.85)
			StylizedMesh.add_sphere(tree, 0.65 * scale_v, leaf.lightened(0.08), Vector3(0.35 * scale_v, 2.5 * scale_v, 0.15), "Canopy2", 12, 8, 0.85)


static func _bush(parent: Node3D, pos: Vector3, idx: int) -> void:
	var b := Node3D.new()
	b.name = "Bush_%d" % idx
	b.position = pos
	parent.add_child(b)
	var c := Color(0.18, 0.48, 0.22) if idx % 2 == 0 else Color(0.22, 0.52, 0.26)
	var s := 0.55 + float(idx % 3) * 0.12
	StylizedMesh.add_sphere(b, s, c, Vector3(0, s * 0.7, 0), "A", 10, 8, 0.88)
	StylizedMesh.add_sphere(b, s * 0.75, c.lightened(0.06), Vector3(s * 0.45, s * 0.55, 0.1), "B", 10, 8, 0.88)


static func _flower_bed(parent: Node3D, pos: Vector3) -> void:
	var bed := Node3D.new()
	bed.position = pos
	parent.add_child(bed)
	StylizedMesh.add_box(bed, Vector3(2.6, 0.22, 1.0), Color(0.38, 0.26, 0.16), Vector3(0, 0.15, 0), "Bed", true, 0.8)
	var colors := [Color(0.9, 0.35, 0.5), Color(0.95, 0.8, 0.2), Color(0.4, 0.55, 0.95), Color(0.85, 0.45, 0.85)]
	for i in 4:
		StylizedMesh.add_sphere(bed, 0.2, colors[i], Vector3(-0.9 + float(i) * 0.55, 0.42, 0.0), "Flower", 8, 6, 0.65)


# --- Street furniture / cars -------------------------------------------------

static func _add_street_furniture(root: Node3D) -> void:
	var decor := Node3D.new()
	decor.name = "Decor"
	root.add_child(decor)
	## Street lamps with real lights (capped for handheld).
	var lamp_spots := [
		Vector3(-12, 0, -12), Vector3(12, 0, -12), Vector3(-12, 0, 12), Vector3(12, 0, 12),
		Vector3(-18, 0, -18), Vector3(18, 0, 18), Vector3(0, 0, -18), Vector3(0, 0, 18),
	]
	for i in lamp_spots.size():
		_street_lamp(decor, lamp_spots[i], i < 6)  ## first 6 emit light

	_bench(decor, Vector3(-4, 0, 8), 0)
	_bench(decor, Vector3(4, 0, -8), 90)
	_bench(decor, Vector3(-8, 0, -3), 45)
	_bench(decor, Vector3(8, 0, 3), -45)

	for p in [Vector3(9, 0, -9), Vector3(-9, 0, 9), Vector3(11, 0, 11), Vector3(-11, 0, -11), Vector3(28, 0, 2)]:
		StylizedMesh.add_cylinder(decor, 0.28, 0.75, Color(0.32, 0.38, 0.32), p + Vector3(0, 0.4, 0), "Bin", true, 12, 0.7)
		StylizedMesh.add_cylinder(decor, 0.3, 0.08, Color(0.25, 0.28, 0.25), p + Vector3(0, 0.8, 0), "BinLid", false, 12, 0.55)

	## Utility poles
	for p in [Vector3(-16, 0, -8), Vector3(16, 0, 8), Vector3(-8, 0, 16)]:
		_utility_pole(decor, p)

	## Street signs
	_street_sign(decor, Vector3(-13, 0, -14), "PARK")
	_street_sign(decor, Vector3(14, 0, -13), "OAK ST")
	_street_sign(decor, Vector3(-14, 0, 13), "MAPLE")


static func _street_lamp(parent: Node3D, pos: Vector3, with_light: bool) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	parent.add_child(lamp)
	StylizedMesh.add_cylinder(lamp, 0.11, 3.4, Color(0.32, 0.32, 0.36), Vector3(0, 1.7, 0), "Pole", true, 12, 0.45)
	StylizedMesh.add_box(lamp, Vector3(0.9, 0.12, 0.28), Color(0.28, 0.28, 0.3), Vector3(0, 3.35, 0.15), "Arm", false, 0.45)
	var bulb := StylizedMesh.add_sphere(lamp, 0.2, Color(1.0, 0.95, 0.75), Vector3(0, 3.2, 0.4), "Bulb", 10, 8, 0.25)
	bulb.material_override = StylizedMesh.make_material(Color(1.0, 0.95, 0.7), 0.3, 0.0, 0.8)
	if with_light:
		var light := OmniLight3D.new()
		light.name = "LampLight"
		light.position = Vector3(0, 3.1, 0.4)
		light.light_color = Color(1.0, 0.92, 0.7)
		light.light_energy = 0.55
		light.omni_range = 8.0
		light.shadow_enabled = false
		lamp.add_child(light)


static func _bench(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var b := Node3D.new()
	b.position = pos
	b.rotation_degrees.y = yaw
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(1.9, 0.12, 0.52), Color(0.48, 0.30, 0.16), Vector3(0, 0.45, 0), "Seat", false, 0.72)
	StylizedMesh.add_box(b, Vector3(1.9, 0.55, 0.1), Color(0.48, 0.30, 0.16), Vector3(0, 0.72, -0.22), "Back", false, 0.72)
	StylizedMesh.add_box(b, Vector3(0.12, 0.45, 0.42), Color(0.28, 0.28, 0.3), Vector3(-0.75, 0.22, 0), "LegL", true, 0.5)
	StylizedMesh.add_box(b, Vector3(0.12, 0.45, 0.42), Color(0.28, 0.28, 0.3), Vector3(0.75, 0.22, 0), "LegR", true, 0.5)


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
		{"pos": Vector3(-18, 0, -16), "yaw": 90.0, "color": Color(0.75, 0.2, 0.18)},
		{"pos": Vector3(18, 0, -16), "yaw": -90.0, "color": Color(0.2, 0.35, 0.7)},
		{"pos": Vector3(-16, 0, 18), "yaw": 0.0, "color": Color(0.85, 0.85, 0.82)},
		{"pos": Vector3(20, 0, 12), "yaw": 180.0, "color": Color(0.2, 0.55, 0.35)},
		{"pos": Vector3(28, 0, -3), "yaw": 90.0, "color": Color(0.15, 0.15, 0.18)},
		{"pos": Vector3(-22, 0, 8), "yaw": 45.0, "color": Color(0.9, 0.7, 0.2)},
	]
	for i in specs.size():
		_car(cars, specs[i]["pos"], float(specs[i]["yaw"]), specs[i]["color"], i)


static func _car(parent: Node3D, pos: Vector3, yaw: float, color: Color, idx: int) -> void:
	var car := Node3D.new()
	car.name = "Car_%d" % idx
	car.position = pos
	car.rotation_degrees.y = yaw
	parent.add_child(car)
	StylizedMesh.add_box(car, Vector3(1.8, 0.55, 3.6), color, Vector3(0, 0.45, 0), "Body", true, 0.45)
	StylizedMesh.add_box(car, Vector3(1.6, 0.5, 1.8), color.lightened(0.08), Vector3(0, 0.95, -0.2), "Cabin", false, 0.45)
	## Windows
	var win := MeshInstance3D.new()
	win.name = "Windshield"
	var wm := BoxMesh.new()
	wm.size = Vector3(1.5, 0.4, 0.08)
	win.mesh = wm
	win.material_override = StylizedMesh.make_glass_material()
	win.position = Vector3(0, 0.95, 0.7)
	car.add_child(win)
	## Wheels
	for wp in [Vector3(-0.85, 0.28, 1.1), Vector3(0.85, 0.28, 1.1), Vector3(-0.85, 0.28, -1.1), Vector3(0.85, 0.28, -1.1)]:
		StylizedMesh.add_cylinder(car, 0.28, 0.18, Color(0.12, 0.12, 0.12), wp, "Wheel", false, 10, 0.7)
	StylizedMesh.add_box(car, Vector3(0.25, 0.12, 0.15), Color(0.95, 0.9, 0.6), Vector3(-0.6, 0.45, 1.8), "HeadL", false, 0.3)
	StylizedMesh.add_box(car, Vector3(0.25, 0.12, 0.15), Color(0.95, 0.9, 0.6), Vector3(0.6, 0.45, 1.8), "HeadR", false, 0.3)


# --- Gameplay props (contracts preserved) ------------------------------------

static func _add_chests(root: Node3D, result: Dictionary) -> void:
	var chests_root := Node3D.new()
	chests_root.name = "Chests"
	root.add_child(chests_root)
	var spots: Array[Vector3] = [
		Vector3(2.5, 0, -2.5),
		Vector3(-24, 0, -19),
		Vector3(28, 0, 10),
		Vector3(0, 0, 26),
		Vector3(30, 0, -4),
	]
	var idx := 0
	for spot in spots:
		result[&"chests"].append(_build_chest(chests_root, "Chest_%d" % idx, spot))
		idx += 1


static func _build_chest(parent: Node3D, chest_name: String, pos: Vector3) -> Area3D:
	var area := ChestInteractable.new()
	area.name = chest_name
	area.position = pos + Vector3(0, 0.4, 0)
	area.loot_item_id = &"hex_shard"
	area.loot_quantity = 1
	area.prompt_text = "Press E to open chest"
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.95, 0.55, 0.7)
	body.mesh = box
	body.material_override = StylizedMesh.make_material(Color(0.88, 0.68, 0.18), 0.5)
	area.add_child(body)
	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.98, 0.18, 0.72)
	lid.mesh = lid_mesh
	lid.material_override = StylizedMesh.make_material(Color(0.75, 0.5, 0.12), 0.5)
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
	StylizedMesh.add_box(pois, Vector3(3.5, 2.2, 1.0), Color(0.34, 0.36, 0.40), Vector3(34, 1.1, 6), "AlleyWall", true, 0.8)
	var secret := _build_chest(pois, "SecretAlleyChest", Vector3(34, 0, 8))
	(secret as ChestInteractable).loot_quantity = 3
	(secret as ChestInteractable).prompt_text = "Press E to open secret stash"
	result[&"chests"].append(secret)
	var bush := Node3D.new()
	bush.name = "MysteryBush"
	bush.position = Vector3(-9, 0, -3)
	pois.add_child(bush)
	StylizedMesh.add_sphere(bush, 0.9, Color(0.18, 0.48, 0.22), Vector3(0, 0.7, 0), "BushA", 12, 8, 0.85)
	StylizedMesh.add_sphere(bush, 0.7, Color(0.22, 0.52, 0.25), Vector3(0.5, 0.55, 0.2), "BushB", 12, 8, 0.85)
	var bush_chest := _build_chest(bush, "BushChest", Vector3(0, 0, 0))
	bush_chest.position = Vector3(0, 0.35, 0)
	(bush_chest as ChestInteractable).prompt_text = "Press E to search the bushes"
	result[&"chests"].append(bush_chest)
	var plaque := SignInteractable.new()
	plaque.name = "ParkPlaque"
	plaque.position = Vector3(3.5, 0.6, 1.5)
	plaque.message = "Pleasant Park — Where every path leads to a story."
	plaque.prompt_text = "Press E to read plaque"
	var pshape := CollisionShape3D.new()
	var pb := BoxShape3D.new()
	pb.size = Vector3(1.6, 1.4, 1.6)
	pshape.shape = pb
	plaque.add_child(pshape)
	StylizedMesh.add_box(plaque, Vector3(1.2, 0.8, 0.15), Color(0.52, 0.42, 0.28), Vector3(0, 0, 0), "PlaqueBoard", false, 0.7)
	pois.add_child(plaque)
	var field_chest := _build_chest(pois, "BleacherChest", Vector3(11, 0, 26))
	(field_chest as ChestInteractable).prompt_text = "Press E to check under the bleachers"
	result[&"chests"].append(field_chest)


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
	var readable := SignInteractable.new()
	readable.name = "WelcomeSignInteract"
	readable.position = Vector3(0, 1.2, 0.5)
	readable.message = "Welcome to Pleasant Park! Explore houses, chests, and quiet corners."
	readable.prompt_text = "Press E to read the sign"
	var rshape := CollisionShape3D.new()
	var rb := BoxShape3D.new()
	rb.size = Vector3(5.5, 2.5, 2.0)
	rshape.shape = rb
	readable.add_child(rshape)
	sign.add_child(readable)
