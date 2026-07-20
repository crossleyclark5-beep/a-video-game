class_name PleasantParkBuilder
extends RefCounted
## Builds Pleasant Park — original Digital Frontier suburban starter town.
## Inspired by classic suburban POI structure (central park, house ring, field, fuel stop).
## Does not copy any franchise assets or exact layouts.

const GROUND_SIZE := Vector3(80.0, 0.25, 80.0)
const PARK_SIZE := Vector3(22.0, 0.08, 22.0)
const ROAD_COLOR := Color(0.28, 0.28, 0.3)
const GRASS_COLOR := Color(0.42, 0.7, 0.36)
const PARK_GRASS := Color(0.35, 0.78, 0.4)
const FIELD_COLOR := Color(0.32, 0.62, 0.3)


static func build(root: Node3D) -> Dictionary:
	var result := {
		&"player_spawn": Vector3(0.0, 0.15, 8.0),
		&"chests": [],
		&"enterable_houses": [],
	}
	_add_ground(root)
	_add_road_ring(root)
	_add_central_park(root)
	_add_sports_field(root)
	_add_fuel_stop(root)
	_add_houses(root, result)
	_add_trees(root)
	_add_chests(root, result)
	_add_sign(root, Vector3(0.0, 0.1, 14.0), "PLEASANT PARK")
	return result


static func _mesh_box(parent: Node3D, size: Vector3, color: Color, pos: Vector3, node_name: String = "Box") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _static_box(parent: Node3D, size: Vector3, color: Color, pos: Vector3, node_name: String = "Static") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


static func _add_ground(root: Node3D) -> void:
	_static_box(root, GROUND_SIZE, GRASS_COLOR, Vector3(0.0, -0.125, 0.0), "Ground")


static func _add_road_ring(root: Node3D) -> void:
	var roads := Node3D.new()
	roads.name = "Roads"
	root.add_child(roads)
	_static_box(roads, Vector3(36.0, 0.06, 4.0), ROAD_COLOR, Vector3(0.0, 0.03, -14.0), "RoadNorth")
	_static_box(roads, Vector3(36.0, 0.06, 4.0), ROAD_COLOR, Vector3(0.0, 0.03, 14.0), "RoadSouth")
	_static_box(roads, Vector3(4.0, 0.06, 32.0), ROAD_COLOR, Vector3(-14.0, 0.03, 0.0), "RoadWest")
	_static_box(roads, Vector3(4.0, 0.06, 32.0), ROAD_COLOR, Vector3(14.0, 0.03, 0.0), "RoadEast")


static func _add_central_park(root: Node3D) -> void:
	var park := Node3D.new()
	park.name = "CentralPark"
	root.add_child(park)
	_static_box(park, PARK_SIZE, PARK_GRASS, Vector3(0.0, 0.04, 0.0), "ParkLawn")
	var gazebo := Node3D.new()
	gazebo.name = "Gazebo"
	park.add_child(gazebo)
	for offset in [Vector3(-2, 1.2, -2), Vector3(2, 1.2, -2), Vector3(-2, 1.2, 2), Vector3(2, 1.2, 2)]:
		_static_box(gazebo, Vector3(0.25, 2.4, 0.25), Color(0.75, 0.55, 0.3), offset, "Post")
	_static_box(gazebo, Vector3(5.5, 0.25, 5.5), Color(0.7, 0.25, 0.22), Vector3(0.0, 2.5, 0.0), "Roof")
	_static_box(park, Vector3(2.2, 0.15, 1.0), Color(0.55, 0.35, 0.2), Vector3(-6.0, 0.4, -5.0), "Picnic1")
	_static_box(park, Vector3(2.2, 0.15, 1.0), Color(0.55, 0.35, 0.2), Vector3(6.0, 0.4, 5.0), "Picnic2")


static func _add_sports_field(root: Node3D) -> void:
	var field := Node3D.new()
	field.name = "SportsField"
	field.position = Vector3(0.0, 0.0, 24.0)
	root.add_child(field)
	_static_box(field, Vector3(16.0, 0.05, 10.0), FIELD_COLOR, Vector3(0.0, 0.05, 0.0), "Pitch")
	_static_box(field, Vector3(3.0, 1.6, 0.2), Color(0.9, 0.9, 0.95), Vector3(0.0, 0.9, -5.0), "GoalNorth")
	_static_box(field, Vector3(3.0, 1.6, 0.2), Color(0.9, 0.9, 0.95), Vector3(0.0, 0.9, 5.0), "GoalSouth")
	_mesh_box(field, Vector3(0.15, 0.02, 10.0), Color(0.95, 0.95, 0.9), Vector3(0.0, 0.08, 0.0), "CenterLine")


static func _add_fuel_stop(root: Node3D) -> void:
	var fuel := Node3D.new()
	fuel.name = "FuelStop"
	fuel.position = Vector3(28.0, 0.0, 0.0)
	root.add_child(fuel)
	_static_box(fuel, Vector3(8.0, 3.0, 6.0), Color(0.85, 0.75, 0.35), Vector3(0.0, 1.5, 0.0), "Shop")
	_static_box(fuel, Vector3(10.0, 0.2, 8.0), Color(0.25, 0.25, 0.27), Vector3(0.0, 0.1, 0.0), "Forecourt")
	_static_box(fuel, Vector3(6.0, 0.3, 4.0), Color(0.2, 0.2, 0.22), Vector3(0.0, 3.3, 0.0), "Canopy")
	_static_box(fuel, Vector3(0.3, 3.0, 0.3), Color(0.4, 0.4, 0.45), Vector3(-2.5, 1.6, -1.5), "PumpPost1")
	_static_box(fuel, Vector3(0.3, 3.0, 0.3), Color(0.4, 0.4, 0.45), Vector3(2.5, 1.6, -1.5), "PumpPost2")


static func _add_houses(root: Node3D, result: Dictionary) -> void:
	var houses := [
		{"name": "BrickHouse", "pos": Vector3(-22.0, 0.0, -22.0), "color": Color(0.72, 0.32, 0.28), "enterable": true},
		{"name": "YellowHouse", "pos": Vector3(0.0, 0.0, -26.0), "color": Color(0.92, 0.78, 0.28), "enterable": false},
		{"name": "WhiteHouse", "pos": Vector3(22.0, 0.0, -22.0), "color": Color(0.92, 0.92, 0.9), "enterable": false},
		{"name": "GreenHouse", "pos": Vector3(-26.0, 0.0, 0.0), "color": Color(0.28, 0.62, 0.35), "enterable": true},
		{"name": "ModernHouse", "pos": Vector3(26.0, 0.0, 14.0), "color": Color(0.35, 0.55, 0.85), "enterable": false},
		{"name": "CoralHouse", "pos": Vector3(-22.0, 0.0, 22.0), "color": Color(0.9, 0.5, 0.45), "enterable": false},
		{"name": "SkyHouse", "pos": Vector3(0.0, 0.0, 34.0), "color": Color(0.55, 0.75, 0.9), "enterable": false},
		{"name": "LavenderHouse", "pos": Vector3(22.0, 0.0, 22.0), "color": Color(0.7, 0.55, 0.85), "enterable": false},
	]
	var houses_root := Node3D.new()
	houses_root.name = "Houses"
	root.add_child(houses_root)
	for spec in houses:
		var house := _build_house(houses_root, spec["name"], spec["pos"], spec["color"], spec["enterable"])
		if spec["enterable"]:
			result[&"enterable_houses"].append(house)


static func _build_house(parent: Node3D, house_name: String, pos: Vector3, color: Color, enterable: bool) -> Node3D:
	var house := Node3D.new()
	house.name = house_name
	house.position = pos
	parent.add_child(house)
	_static_box(house, Vector3(7.0, 3.2, 6.0), color, Vector3(0.0, 1.6, 0.0), "Body")
	var roof := _mesh_box(house, Vector3(7.8, 0.6, 6.8), Color(color.r * 0.55, color.g * 0.55, color.b * 0.55), Vector3(0.0, 3.5, 0.0), "Roof")
	_mesh_box(house, Vector3(1.2, 2.0, 0.15), Color(0.35, 0.22, 0.12), Vector3(0.0, 1.0, 3.05), "Door")
	_mesh_box(house, Vector3(1.2, 1.0, 0.1), Color(0.6, 0.85, 0.95), Vector3(-2.0, 1.8, 3.05), "WindowL")
	_mesh_box(house, Vector3(1.2, 1.0, 0.1), Color(0.6, 0.85, 0.95), Vector3(2.0, 1.8, 3.05), "WindowR")
	if enterable:
		house.set_meta("roof_node", roof)
		house.set_meta("enterable", true)
		var door_area := Area3D.new()
		door_area.name = "DoorArea"
		door_area.collision_layer = 16
		door_area.collision_mask = 4
		door_area.monitoring = true
		door_area.position = Vector3(0.0, 1.0, 3.5)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.5, 2.5, 2.0)
		shape.shape = box
		door_area.add_child(shape)
		house.add_child(door_area)
		_mesh_box(house, Vector3(6.2, 0.08, 5.2), Color(0.65, 0.5, 0.35), Vector3(0.0, 0.2, 0.0), "InteriorFloor")
		_mesh_box(house, Vector3(1.5, 0.8, 0.8), Color(0.4, 0.25, 0.15), Vector3(-1.5, 0.6, -1.0), "Table")
		_mesh_box(house, Vector3(1.2, 1.4, 0.5), Color(0.55, 0.35, 0.7), Vector3(2.0, 0.9, -1.5), "Shelf")
	return house


static func _add_trees(root: Node3D) -> void:
	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	var positions: Array[Vector3] = [
		Vector3(-8, 0, -8), Vector3(8, 0, -7), Vector3(-9, 0, 7), Vector3(9, 0, 8),
		Vector3(-18, 0, -10), Vector3(18, 0, -12), Vector3(-30, 0, 8), Vector3(32, 0, -8),
		Vector3(-12, 0, 28), Vector3(12, 0, 30), Vector3(5, 0, -18), Vector3(-5, 0, 18),
	]
	var i := 0
	for p in positions:
		var tree := Node3D.new()
		tree.name = "Tree_%d" % i
		tree.position = p
		trees.add_child(tree)
		_static_box(tree, Vector3(0.4, 1.6, 0.4), Color(0.4, 0.25, 0.12), Vector3(0.0, 0.8, 0.0), "Trunk")
		_static_box(tree, Vector3(2.2, 2.2, 2.2), Color(0.2, 0.55, 0.25), Vector3(0.0, 2.4, 0.0), "Canopy")
		i += 1


static func _add_chests(root: Node3D, result: Dictionary) -> void:
	var chests_root := Node3D.new()
	chests_root.name = "Chests"
	root.add_child(chests_root)
	var spots: Array[Vector3] = [
		Vector3(0.0, 0.0, -3.0),
		Vector3(-22.0, 0.0, -18.0),
		Vector3(26.0, 0.0, 10.0),
		Vector3(0.0, 0.0, 24.0),
		Vector3(28.0, 0.0, -4.0),
	]
	var idx := 0
	for spot in spots:
		var chest := _build_chest(chests_root, "Chest_%d" % idx, spot)
		result[&"chests"].append(chest)
		idx += 1


static func _build_chest(parent: Node3D, chest_name: String, pos: Vector3) -> Area3D:
	var area := Area3D.new()
	area.name = chest_name
	area.position = pos + Vector3(0.0, 0.5, 0.0)
	area.collision_layer = 16
	area.collision_mask = 4
	area.monitoring = true
	area.set_meta("chest_id", StringName(chest_name.to_lower()))
	area.set_meta("loot_item", &"hex_shard")
	area.set_meta("loot_qty", 1)
	area.set_meta("opened", false)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.6, 0.7)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.65, 0.15)
	mi.material_override = mat
	area.add_child(mi)
	var shape := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(1.4, 1.2, 1.4)
	shape.shape = s
	area.add_child(shape)
	parent.add_child(area)
	return area


static func _add_sign(root: Node3D, pos: Vector3, text: String) -> void:
	var sign := Node3D.new()
	sign.name = "WelcomeSign"
	sign.position = pos
	root.add_child(sign)
	_static_box(sign, Vector3(0.2, 2.2, 0.2), Color(0.4, 0.25, 0.12), Vector3(-2.0, 1.1, 0.0), "PostL")
	_static_box(sign, Vector3(0.2, 2.2, 0.2), Color(0.4, 0.25, 0.12), Vector3(2.0, 1.1, 0.0), "PostR")
	_static_box(sign, Vector3(5.0, 1.2, 0.25), Color(0.2, 0.45, 0.25), Vector3(0.0, 2.0, 0.0), "Board")
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.position = Vector3(0.0, 2.0, 0.2)
	label.modulate = Color(0.95, 0.95, 0.85)
	sign.add_child(label)
