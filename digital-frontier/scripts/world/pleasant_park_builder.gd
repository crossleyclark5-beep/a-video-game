class_name PleasantParkBuilder
extends RefCounted
## Pleasant Park — stylized suburban starter town for Digital Frontier.
## Modular builder: roads, sidewalks, grass variation, detailed houses, props.
## Preserves interact contracts: player_spawn, chests[], enterable_houses[] with DoorArea + roof_node.

const GROUND := Color(0.40, 0.68, 0.34)
const GRASS_A := Color(0.38, 0.72, 0.36)
const GRASS_B := Color(0.45, 0.74, 0.40)
const GRASS_C := Color(0.34, 0.64, 0.32)
const PARK_GREEN := Color(0.32, 0.76, 0.42)
const ROAD := Color(0.30, 0.30, 0.33)
const SIDEWALK := Color(0.72, 0.72, 0.70)
const CURB := Color(0.55, 0.55, 0.52)


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
	_add_trees(root)
	_add_decor(root)
	_add_chests(root, result)
	_add_sign(root, Vector3(0.0, 0.0, 16.0), "PLEASANT PARK")
	return result


static func _add_terrain(root: Node3D) -> void:
	var terrain := Node3D.new()
	terrain.name = "Terrain"
	root.add_child(terrain)
	StylizedMesh.add_box(terrain, Vector3(90, 0.3, 90), GROUND, Vector3(0, -0.15, 0), "BaseGround", true)
	# Grass variation patches
	var patches := [
		[Vector3(0, 0.02, 0), Vector3(24, 0.06, 24), PARK_GREEN],
		[Vector3(-20, 0.02, 8), Vector3(10, 0.05, 8), GRASS_A],
		[Vector3(18, 0.02, -10), Vector3(12, 0.05, 9), GRASS_B],
		[Vector3(-8, 0.02, 28), Vector3(14, 0.05, 10), GRASS_C],
		[Vector3(12, 0.02, 30), Vector3(10, 0.05, 8), GRASS_A],
		[Vector3(-28, 0.02, -12), Vector3(9, 0.05, 10), GRASS_B],
		[Vector3(30, 0.02, 18), Vector3(8, 0.05, 8), GRASS_C],
	]
	var i := 0
	for p in patches:
		StylizedMesh.add_box(terrain, p[1], p[2], p[0], "GrassPatch_%d" % i, false)
		i += 1


static func _add_road_network(root: Node3D) -> void:
	var roads := Node3D.new()
	roads.name = "Roads"
	root.add_child(roads)
	# Outer ring road
	_road_segment(roads, Vector3(0, 0.04, -15), Vector3(40, 0.08, 5.5), "RoadN")
	_road_segment(roads, Vector3(0, 0.04, 15), Vector3(40, 0.08, 5.5), "RoadS")
	_road_segment(roads, Vector3(-15, 0.04, 0), Vector3(5.5, 0.08, 35), "RoadW")
	_road_segment(roads, Vector3(15, 0.04, 0), Vector3(5.5, 0.08, 35), "RoadE")
	# Sidewalks inside ring
	_sidewalk_ring(roads)
	# Spur to fuel stop
	_road_segment(roads, Vector3(24, 0.04, 0), Vector3(12, 0.08, 4.5), "RoadFuel")
	# Center crosswalk marks
	StylizedMesh.add_box(roads, Vector3(0.4, 0.02, 3.5), Color(0.9, 0.9, 0.85), Vector3(0, 0.09, -15), "XingN1")
	StylizedMesh.add_box(roads, Vector3(0.4, 0.02, 3.5), Color(0.9, 0.9, 0.85), Vector3(1.2, 0.09, -15), "XingN2")


static func _road_segment(parent: Node3D, pos: Vector3, size: Vector3, node_name: String) -> void:
	StylizedMesh.add_box(parent, size, ROAD, pos, node_name, true)
	# Center dashed line (visual only)
	var along_x := size.x >= size.z
	if along_x:
		StylizedMesh.add_box(parent, Vector3(size.x * 0.7, 0.015, 0.18), Color(0.85, 0.8, 0.35), pos + Vector3(0, 0.05, 0), node_name + "Line")
	else:
		StylizedMesh.add_box(parent, Vector3(0.18, 0.015, size.z * 0.7), Color(0.85, 0.8, 0.35), pos + Vector3(0, 0.05, 0), node_name + "Line")


static func _sidewalk_ring(parent: Node3D) -> void:
	# Inner sidewalk facing park
	StylizedMesh.add_box(parent, Vector3(28, 0.07, 1.6), SIDEWALK, Vector3(0, 0.05, -11.2), "WalkN", true)
	StylizedMesh.add_box(parent, Vector3(28, 0.07, 1.6), SIDEWALK, Vector3(0, 0.05, 11.2), "WalkS", true)
	StylizedMesh.add_box(parent, Vector3(1.6, 0.07, 24), SIDEWALK, Vector3(-11.2, 0.05, 0), "WalkW", true)
	StylizedMesh.add_box(parent, Vector3(1.6, 0.07, 24), SIDEWALK, Vector3(11.2, 0.05, 0), "WalkE", true)
	# Outer sidewalk facing houses
	StylizedMesh.add_box(parent, Vector3(42, 0.07, 1.4), SIDEWALK, Vector3(0, 0.05, -18.5), "WalkOuterN", true)
	StylizedMesh.add_box(parent, Vector3(42, 0.07, 1.4), SIDEWALK, Vector3(0, 0.05, 18.5), "WalkOuterS", true)
	StylizedMesh.add_box(parent, Vector3(1.4, 0.07, 38), SIDEWALK, Vector3(-18.5, 0.05, 0), "WalkOuterW", true)
	StylizedMesh.add_box(parent, Vector3(1.4, 0.07, 38), SIDEWALK, Vector3(18.5, 0.05, 0), "WalkOuterE", true)


static func _add_central_park(root: Node3D) -> void:
	var park := Node3D.new()
	park.name = "CentralPark"
	root.add_child(park)
	StylizedMesh.add_box(park, Vector3(20, 0.08, 20), PARK_GREEN, Vector3(0, 0.05, 0), "Lawn", true)
	# Path through park
	StylizedMesh.add_box(park, Vector3(2.2, 0.04, 18), Color(0.78, 0.68, 0.48), Vector3(0, 0.08, 0), "PathNS")
	StylizedMesh.add_box(park, Vector3(18, 0.04, 2.2), Color(0.78, 0.68, 0.48), Vector3(0, 0.08, 0), "PathEW")
	# Gazebo
	var gazebo := Node3D.new()
	gazebo.name = "Gazebo"
	park.add_child(gazebo)
	for offset in [Vector3(-2.2, 1.3, -2.2), Vector3(2.2, 1.3, -2.2), Vector3(-2.2, 1.3, 2.2), Vector3(2.2, 1.3, 2.2)]:
		StylizedMesh.add_cylinder(gazebo, 0.16, 2.6, Color(0.78, 0.58, 0.32), offset, "Post", true)
	StylizedMesh.add_box(gazebo, Vector3(6.2, 0.2, 6.2), Color(0.72, 0.28, 0.24), Vector3(0, 2.7, 0), "RoofDeck")
	StylizedMesh.add_box(gazebo, Vector3(4.0, 0.55, 4.0), Color(0.65, 0.22, 0.2), Vector3(0, 3.1, 0), "RoofPeak")
	StylizedMesh.add_cylinder(gazebo, 2.4, 0.15, Color(0.7, 0.55, 0.35), Vector3(0, 0.15, 0), "Floor", true)
	# Picnic sets
	_picnic_set(park, Vector3(-6.5, 0, -5.5))
	_picnic_set(park, Vector3(6.5, 0, 5.5))
	# Fountain landmark
	var fountain := Node3D.new()
	fountain.name = "Fountain"
	fountain.position = Vector3(0, 0, 0)
	park.add_child(fountain)
	StylizedMesh.add_cylinder(fountain, 1.6, 0.35, Color(0.75, 0.75, 0.78), Vector3(0, 0.25, 0), "Basin", true)
	StylizedMesh.add_cylinder(fountain, 0.35, 1.2, Color(0.7, 0.7, 0.74), Vector3(0, 0.9, 0), "Spire", false)
	StylizedMesh.add_sphere(fountain, 0.45, Color(0.45, 0.7, 0.95), Vector3(0, 1.6, 0), "Water")


static func _picnic_set(parent: Node3D, pos: Vector3) -> void:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	StylizedMesh.add_box(p, Vector3(2.4, 0.12, 1.1), Color(0.55, 0.36, 0.2), Vector3(0, 0.55, 0), "Table")
	StylizedMesh.add_box(p, Vector3(0.15, 0.55, 0.15), Color(0.4, 0.25, 0.12), Vector3(-0.9, 0.28, -0.35), "Leg1")
	StylizedMesh.add_box(p, Vector3(0.15, 0.55, 0.15), Color(0.4, 0.25, 0.12), Vector3(0.9, 0.28, 0.35), "Leg2")
	StylizedMesh.add_box(p, Vector3(2.2, 0.1, 0.45), Color(0.5, 0.32, 0.18), Vector3(0, 0.35, -1.0), "BenchA")
	StylizedMesh.add_box(p, Vector3(2.2, 0.1, 0.45), Color(0.5, 0.32, 0.18), Vector3(0, 0.35, 1.0), "BenchB")


static func _add_sports_field(root: Node3D) -> void:
	var field := Node3D.new()
	field.name = "SportsField"
	field.position = Vector3(0, 0, 26)
	root.add_child(field)
	StylizedMesh.add_box(field, Vector3(18, 0.06, 12), Color(0.30, 0.60, 0.28), Vector3(0, 0.06, 0), "Pitch", true)
	StylizedMesh.add_box(field, Vector3(0.12, 0.02, 12), Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 0), "MidLine")
	StylizedMesh.add_cylinder(field, 1.2, 0.03, Color(0.95, 0.95, 0.9), Vector3(0, 0.1, 0), "CenterCircle")
	# Goals
	for z in [-6.0, 6.0]:
		var goal := Node3D.new()
		goal.position = Vector3(0, 0, z)
		field.add_child(goal)
		StylizedMesh.add_box(goal, Vector3(0.15, 2.0, 0.15), Color(0.92, 0.92, 0.95), Vector3(-2, 1.0, 0), "PostL", true)
		StylizedMesh.add_box(goal, Vector3(0.15, 2.0, 0.15), Color(0.92, 0.92, 0.95), Vector3(2, 1.0, 0), "PostR", true)
		StylizedMesh.add_box(goal, Vector3(4.15, 0.15, 0.15), Color(0.92, 0.92, 0.95), Vector3(0, 2.0, 0), "Crossbar", true)
	# Bleacher landmark
	StylizedMesh.add_box(field, Vector3(6, 0.4, 1.2), Color(0.55, 0.2, 0.18), Vector3(10, 0.4, 0), "Bleacher1", true)
	StylizedMesh.add_box(field, Vector3(6, 0.4, 1.2), Color(0.55, 0.2, 0.18), Vector3(10.3, 0.85, 0), "Bleacher2", true)


static func _add_fuel_stop(root: Node3D) -> void:
	var fuel := Node3D.new()
	fuel.name = "FuelStop"
	fuel.position = Vector3(30, 0, 0)
	root.add_child(fuel)
	StylizedMesh.add_box(fuel, Vector3(12, 0.12, 10), Color(0.26, 0.26, 0.28), Vector3(0, 0.08, 0), "Lot", true)
	StylizedMesh.add_box(fuel, Vector3(7.5, 3.4, 5.5), Color(0.88, 0.78, 0.32), Vector3(1.5, 1.7, 1.5), "Shop", true)
	StylizedMesh.add_box(fuel, Vector3(8.2, 0.35, 6.2), Color(0.75, 0.2, 0.18), Vector3(1.5, 3.55, 1.5), "ShopRoof")
	StylizedMesh.add_box(fuel, Vector3(1.4, 1.6, 0.12), Color(0.55, 0.85, 0.95), Vector3(1.5, 1.8, 4.3), "ShopWindow")
	StylizedMesh.add_box(fuel, Vector3(8, 0.25, 5), Color(0.22, 0.22, 0.24), Vector3(-1, 3.4, -2), "Canopy")
	StylizedMesh.add_cylinder(fuel, 0.18, 3.2, Color(0.45, 0.45, 0.48), Vector3(-3, 1.6, -2), "CanopyPost1", true)
	StylizedMesh.add_cylinder(fuel, 0.18, 3.2, Color(0.45, 0.45, 0.48), Vector3(1, 1.6, -2), "CanopyPost2", true)
	# Pumps
	StylizedMesh.add_box(fuel, Vector3(0.7, 1.4, 0.5), Color(0.85, 0.25, 0.2), Vector3(-3, 0.8, -2.8), "Pump1", true)
	StylizedMesh.add_box(fuel, Vector3(0.7, 1.4, 0.5), Color(0.85, 0.25, 0.2), Vector3(1, 0.8, -2.8), "Pump2", true)
	StylizedMesh.add_box(fuel, Vector3(2.5, 1.8, 0.3), Color(0.15, 0.45, 0.25), Vector3(1.5, 2.5, 4.4), "PriceSign")


static func _add_houses(root: Node3D, result: Dictionary) -> void:
	var specs := [
		{"name": "BrickHouse", "pos": Vector3(-24, 0, -24), "color": Color(0.70, 0.34, 0.28), "roof": Color(0.35, 0.22, 0.18), "enterable": true, "yaw": 45.0},
		{"name": "YellowHouse", "pos": Vector3(0, 0, -28), "color": Color(0.92, 0.80, 0.30), "roof": Color(0.45, 0.28, 0.15), "enterable": false, "yaw": 0.0},
		{"name": "WhiteHouse", "pos": Vector3(24, 0, -24), "color": Color(0.93, 0.93, 0.90), "roof": Color(0.35, 0.4, 0.5), "enterable": false, "yaw": -45.0},
		{"name": "GreenHouse", "pos": Vector3(-28, 0, 0), "color": Color(0.30, 0.62, 0.38), "roof": Color(0.25, 0.3, 0.22), "enterable": true, "yaw": 90.0},
		{"name": "ModernHouse", "pos": Vector3(28, 0, 14), "color": Color(0.38, 0.58, 0.88), "roof": Color(0.2, 0.25, 0.35), "enterable": false, "yaw": -90.0},
		{"name": "CoralHouse", "pos": Vector3(-24, 0, 24), "color": Color(0.90, 0.52, 0.45), "roof": Color(0.4, 0.25, 0.2), "enterable": false, "yaw": 135.0},
		{"name": "SkyHouse", "pos": Vector3(0, 0, 36), "color": Color(0.55, 0.78, 0.92), "roof": Color(0.3, 0.35, 0.4), "enterable": false, "yaw": 180.0},
		{"name": "LavenderHouse", "pos": Vector3(24, 0, 24), "color": Color(0.72, 0.58, 0.88), "roof": Color(0.35, 0.25, 0.4), "enterable": false, "yaw": -135.0},
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
	house.name = spec["name"]
	house.position = spec["pos"]
	house.rotation_degrees.y = spec["yaw"]
	parent.add_child(house)

	var wall: Color = spec["color"]
	var roof_c: Color = spec["roof"]
	var enterable: bool = spec["enterable"]

	# Yard pad
	StylizedMesh.add_box(house, Vector3(11, 0.05, 10), Color(0.42, 0.7, 0.38), Vector3(0, 0.03, 0), "Yard")
	# Main body
	StylizedMesh.add_box(house, Vector3(7.5, 3.4, 6.2), wall, Vector3(0, 1.7, 0), "Body", true)
	# Garage wing
	StylizedMesh.add_box(house, Vector3(3.2, 2.4, 4.5), wall.darkened(0.06), Vector3(5.0, 1.2, -0.5), "Garage", true)
	StylizedMesh.add_box(house, Vector3(2.6, 1.8, 0.12), Color(0.25, 0.28, 0.35), Vector3(5.0, 1.1, 1.8), "GarageDoor")
	# Porch
	StylizedMesh.add_box(house, Vector3(3.5, 0.2, 1.8), Color(0.65, 0.55, 0.4), Vector3(0, 0.2, 3.6), "Porch", true)
	StylizedMesh.add_cylinder(house, 0.1, 2.0, Color(0.85, 0.85, 0.8), Vector3(-1.3, 1.2, 4.2), "PorchPostL", true)
	StylizedMesh.add_cylinder(house, 0.1, 2.0, Color(0.85, 0.85, 0.8), Vector3(1.3, 1.2, 4.2), "PorchPostR", true)
	StylizedMesh.add_box(house, Vector3(3.6, 0.15, 2.0), roof_c, Vector3(0, 2.25, 3.6), "PorchRoof")
	# Roof with transparent-capable material for enterables
	var roof_mi := MeshInstance3D.new()
	roof_mi.name = "Roof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(8.4, 0.7, 7.2)
	roof_mi.mesh = roof_mesh
	if enterable:
		roof_mi.material_override = StylizedMesh.make_transparent_material(roof_c)
	else:
		roof_mi.material_override = StylizedMesh.make_material(roof_c)
	roof_mi.position = Vector3(0, 3.75, 0)
	house.add_child(roof_mi)
	StylizedMesh.add_box(house, Vector3(5.0, 0.9, 4.5), roof_c.darkened(0.1), Vector3(0, 4.3, 0), "RoofPeak")
	# Chimney
	StylizedMesh.add_box(house, Vector3(0.7, 1.4, 0.7), Color(0.45, 0.3, 0.25), Vector3(-2.5, 4.6, -1.5), "Chimney", true)
	# Door + windows
	StylizedMesh.add_box(house, Vector3(1.15, 2.1, 0.12), Color(0.32, 0.2, 0.12), Vector3(0, 1.15, 3.15), "Door")
	StylizedMesh.add_box(house, Vector3(1.3, 1.1, 0.1), Color(0.55, 0.82, 0.95), Vector3(-2.2, 2.0, 3.15), "WinL")
	StylizedMesh.add_box(house, Vector3(1.3, 1.1, 0.1), Color(0.55, 0.82, 0.95), Vector3(2.2, 2.0, 3.15), "WinR")
	StylizedMesh.add_box(house, Vector3(1.0, 0.9, 0.1), Color(0.55, 0.82, 0.95), Vector3(-2.0, 2.2, -3.15), "WinBack")
	# Mailbox
	StylizedMesh.add_box(house, Vector3(0.35, 0.9, 0.2), Color(0.2, 0.35, 0.65), Vector3(2.8, 0.55, 5.2), "Mailbox", true)

	if enterable:
		house.set_meta("roof_node", roof_mi)
		house.set_meta("enterable", true)
		var door_area := Area3D.new()
		door_area.name = "DoorArea"
		door_area.collision_layer = 16
		door_area.collision_mask = 4
		door_area.monitoring = true
		door_area.position = Vector3(0, 1.0, 4.2)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.8, 2.6, 2.4)
		shape.shape = box
		door_area.add_child(shape)
		house.add_child(door_area)
		# Interior (walkable hollow feel — floor + props, no solid fill)
		StylizedMesh.add_box(house, Vector3(6.6, 0.08, 5.4), Color(0.62, 0.48, 0.34), Vector3(0, 0.18, 0), "InteriorFloor")
		StylizedMesh.add_box(house, Vector3(1.6, 0.7, 0.8), Color(0.4, 0.25, 0.15), Vector3(-1.8, 0.55, -1.2), "Table")
		StylizedMesh.add_box(house, Vector3(1.0, 1.5, 0.45), Color(0.5, 0.35, 0.65), Vector3(2.2, 0.95, -1.5), "Shelf")
		StylizedMesh.add_box(house, Vector3(1.8, 0.45, 0.9), Color(0.55, 0.2, 0.2), Vector3(0, 0.45, -2.0), "Couch")
		# Disable collision on main body for enterables so player can walk inside
		var body_node := house.get_node_or_null("Body")
		if body_node is StaticBody3D:
			(body_node as StaticBody3D).collision_layer = 0

	return house


static func _add_fences(root: Node3D) -> void:
	var fences := Node3D.new()
	fences.name = "Fences"
	root.add_child(fences)
	# Park perimeter low fence
	_fence_line(fences, Vector3(-10, 0, -10), Vector3(10, 0, -10), 8)
	_fence_line(fences, Vector3(-10, 0, 10), Vector3(10, 0, 10), 8)
	_fence_line(fences, Vector3(-10, 0, -10), Vector3(-10, 0, 10), 8)
	_fence_line(fences, Vector3(10, 0, -10), Vector3(10, 0, 10), 8)
	# Sports field fence bits
	_fence_line(fences, Vector3(-9, 0, 20), Vector3(-9, 0, 32), 6)
	_fence_line(fences, Vector3(9, 0, 20), Vector3(9, 0, 32), 6)


static func _fence_line(parent: Node3D, a: Vector3, b: Vector3, posts: int) -> void:
	for i in range(posts):
		var t := float(i) / float(maxi(posts - 1, 1))
		var p := a.lerp(b, t)
		StylizedMesh.add_box(parent, Vector3(0.12, 0.9, 0.12), Color(0.75, 0.75, 0.72), p + Vector3(0, 0.45, 0), "FencePost", true)
	# Continuous top rail as one segment
	var mid := a.lerp(b, 0.5)
	var length := a.distance_to(b)
	var delta := b - a
	var rail_size := Vector3(length, 0.08, 0.08) if absf(delta.x) >= absf(delta.z) else Vector3(0.08, 0.08, length)
	StylizedMesh.add_box(parent, rail_size, Color(0.7, 0.7, 0.68), mid + Vector3(0, 0.7, 0), "FenceRail")
	StylizedMesh.add_box(parent, rail_size, Color(0.7, 0.7, 0.68), mid + Vector3(0, 0.4, 0), "FenceRailLow")


static func _add_trees(root: Node3D) -> void:
	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	var spots: Array[Vector3] = [
		Vector3(-7, 0, -7), Vector3(7, 0, -6), Vector3(-8, 0, 6), Vector3(8, 0, 7),
		Vector3(-19, 0, -11), Vector3(19, 0, -13), Vector3(-32, 0, 8), Vector3(34, 0, -6),
		Vector3(-14, 0, 30), Vector3(14, 0, 32), Vector3(6, 0, -20), Vector3(-6, 0, 20),
		Vector3(-22, 0, 12), Vector3(22, 0, -8), Vector3(8, 0, 22), Vector3(-30, 0, -20),
	]
	var i := 0
	for p in spots:
		_stylized_tree(trees, p, i)
		i += 1


static func _stylized_tree(parent: Node3D, pos: Vector3, idx: int) -> void:
	var tree := Node3D.new()
	tree.name = "Tree_%d" % idx
	tree.position = pos
	parent.add_child(tree)
	var scale_v := 0.85 + float(idx % 3) * 0.15
	StylizedMesh.add_cylinder(tree, 0.22 * scale_v, 1.8 * scale_v, Color(0.42, 0.28, 0.14), Vector3(0, 0.9 * scale_v, 0), "Trunk", true)
	var leaf := Color(0.22, 0.58, 0.28) if idx % 2 == 0 else Color(0.28, 0.65, 0.32)
	StylizedMesh.add_sphere(tree, 1.15 * scale_v, leaf, Vector3(0, 2.3 * scale_v, 0), "Canopy")
	StylizedMesh.add_sphere(tree, 0.85 * scale_v, leaf.lightened(0.08), Vector3(0.4 * scale_v, 2.6 * scale_v, 0.2), "Canopy2")


static func _add_decor(root: Node3D) -> void:
	var decor := Node3D.new()
	decor.name = "Decor"
	root.add_child(decor)
	# Street lamps on corners
	for p in [Vector3(-12, 0, -12), Vector3(12, 0, -12), Vector3(-12, 0, 12), Vector3(12, 0, 12)]:
		_street_lamp(decor, p)
	# Park benches
	_bench(decor, Vector3(-4, 0, 8))
	_bench(decor, Vector3(4, 0, -8))
	# Flower beds
	StylizedMesh.add_box(decor, Vector3(2.5, 0.25, 1.0), Color(0.4, 0.28, 0.18), Vector3(-5, 0.2, -9), "Bed1", true)
	StylizedMesh.add_sphere(decor, 0.25, Color(0.9, 0.35, 0.55), Vector3(-5.5, 0.5, -9), "Flower1")
	StylizedMesh.add_sphere(decor, 0.22, Color(0.95, 0.8, 0.2), Vector3(-4.5, 0.48, -9), "Flower2")
	StylizedMesh.add_sphere(decor, 0.24, Color(0.4, 0.55, 0.95), Vector3(-5, 0.5, -9.3), "Flower3")
	# Trash cans
	StylizedMesh.add_cylinder(decor, 0.28, 0.7, Color(0.35, 0.4, 0.35), Vector3(9, 0.4, -9), "Bin1", true)
	StylizedMesh.add_cylinder(decor, 0.28, 0.7, Color(0.35, 0.4, 0.35), Vector3(-9, 0.4, 9), "Bin2", true)


static func _street_lamp(parent: Node3D, pos: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	parent.add_child(lamp)
	StylizedMesh.add_cylinder(lamp, 0.12, 3.2, Color(0.35, 0.35, 0.38), Vector3(0, 1.6, 0), "Pole", true)
	StylizedMesh.add_box(lamp, Vector3(0.8, 0.15, 0.3), Color(0.3, 0.3, 0.32), Vector3(0, 3.2, 0), "Arm")
	StylizedMesh.add_sphere(lamp, 0.22, Color(1.0, 0.95, 0.7), Vector3(0, 3.05, 0.35), "Bulb")


static func _bench(parent: Node3D, pos: Vector3) -> void:
	var b := Node3D.new()
	b.position = pos
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(1.8, 0.12, 0.5), Color(0.5, 0.32, 0.18), Vector3(0, 0.45, 0), "Seat")
	StylizedMesh.add_box(b, Vector3(1.8, 0.5, 0.1), Color(0.5, 0.32, 0.18), Vector3(0, 0.7, -0.2), "Back")
	StylizedMesh.add_box(b, Vector3(0.12, 0.45, 0.4), Color(0.3, 0.3, 0.32), Vector3(-0.7, 0.22, 0), "LegL", true)
	StylizedMesh.add_box(b, Vector3(0.12, 0.45, 0.4), Color(0.3, 0.3, 0.32), Vector3(0.7, 0.22, 0), "LegR", true)


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
	var area := Area3D.new()
	area.name = chest_name
	area.position = pos + Vector3(0, 0.4, 0)
	area.collision_layer = 16
	area.collision_mask = 4
	area.monitoring = true
	area.set_meta("chest_id", StringName(chest_name.to_lower()))
	area.set_meta("loot_item", &"hex_shard")
	area.set_meta("loot_qty", 1)
	area.set_meta("opened", false)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.95, 0.55, 0.7)
	body.mesh = box
	body.material_override = StylizedMesh.make_material(Color(0.88, 0.68, 0.18), 0.55)
	area.add_child(body)
	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.98, 0.18, 0.72)
	lid.mesh = lid_mesh
	lid.material_override = StylizedMesh.make_material(Color(0.75, 0.5, 0.12), 0.55)
	lid.position = Vector3(0, 0.35, 0)
	area.add_child(lid)
	var band := MeshInstance3D.new()
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(1.0, 0.12, 0.12)
	band.mesh = band_mesh
	band.material_override = StylizedMesh.make_material(Color(0.85, 0.75, 0.3), 0.4)
	band.position = Vector3(0, 0.1, 0.36)
	area.add_child(band)
	var shape := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(1.5, 1.3, 1.5)
	shape.shape = s
	area.add_child(shape)
	parent.add_child(area)
	return area


static func _add_sign(root: Node3D, pos: Vector3, text: String) -> void:
	var sign := Node3D.new()
	sign.name = "WelcomeSign"
	sign.position = pos
	root.add_child(sign)
	StylizedMesh.add_cylinder(sign, 0.12, 2.4, Color(0.4, 0.28, 0.14), Vector3(-2.2, 1.2, 0), "PostL", true)
	StylizedMesh.add_cylinder(sign, 0.12, 2.4, Color(0.4, 0.28, 0.14), Vector3(2.2, 1.2, 0), "PostR", true)
	StylizedMesh.add_box(sign, Vector3(5.2, 1.4, 0.28), Color(0.18, 0.48, 0.28), Vector3(0, 2.1, 0), "Board", true)
	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.position = Vector3(0, 2.1, 0.2)
	label.modulate = Color(0.98, 0.96, 0.85)
	label.outline_modulate = Color(0.1, 0.2, 0.12)
	label.outline_size = 8
	sign.add_child(label)
