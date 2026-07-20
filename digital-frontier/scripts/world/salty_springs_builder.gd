class_name SaltySpringsBuilder
extends RefCounted
## Salty Springs — OG Athena hill neighborhood (original art, not franchise IP).
## Structure: 5 houses on steep hills + Pass-style gas station, compact streets.


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "SaltySprings"
	hub.position = origin
	root.add_child(hub)

	## Steep hilly bowl — OG Salty sits in rolling hills, not a flat plaza.
	StylizedMesh.add_box(hub, Vector3(95, 0.28, 85), WorldPalette.GRASS_DARK, Vector3(0, -0.12, 0), "Ground", true, 1.0, &"grass")
	StylizedMesh.add_box(hub, Vector3(36, 2.4, 22), WorldPalette.ROCK, Vector3(-22, 1.0, -18), "HillNW", true)
	StylizedMesh.add_box(hub, Vector3(28, 3.0, 26), WorldPalette.ROCK.darkened(0.06), Vector3(24, 1.3, -10), "HillNE", true)
	StylizedMesh.add_box(hub, Vector3(30, 1.8, 20), WorldPalette.ROCK.lightened(0.04), Vector3(-18, 0.7, 18), "HillSW", true)
	StylizedMesh.add_box(hub, Vector3(24, 2.2, 18), WorldPalette.ROCK, Vector3(20, 0.9, 16), "HillSE", true)
	StylizedMesh.add_box(hub, Vector3(18, 0.06, 16), WorldPalette.GRASS, Vector3(0, 0.04, 0), "StreetHollow", false, 1.0, &"grass")

	## Compact cross streets through the hollow.
	StylizedMesh.add_box(hub, Vector3(42, 0.08, 4.0), WorldPalette.ROAD, Vector3(0, 0.05, 0), "MainEW", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(4.0, 0.08, 36), WorldPalette.ROAD, Vector3(0, 0.05, 0), "MainNS", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(3.2, 0.06, 14), WorldPalette.PATH, Vector3(-10, 0.06, -8), "Alley", false, 1.0, &"dirt")

	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, 22), "SALTY SPRINGS", &"salty_springs_welcome")

	## Five OG-style houses (colors / roles match classic Salty read).
	## West blue house — enterable (basement legend → interior-ready).
	RegionPropKit.make_enterable_house(
		hub, "BlueHouse", Vector3(-16, 0.4, -6), Color(0.35, 0.55, 0.88), WorldPalette.ROOF, 90.0, result
	)
	## Small house across from blue.
	_salty_house(hub, "SmallHouse", Vector3(-6, 0.2, 8), Color(0.88, 0.84, 0.72), WorldPalette.ROOF_RED, 0.0, Vector3(4.2, 2.2, 3.8))
	## Northern brick house.
	_salty_house(hub, "BrickHouse", Vector3(2, 0.6, -16), WorldPalette.BRICK, WorldPalette.ROOF, 180.0, Vector3(5.8, 2.8, 5.0))
	## Southern house.
	_salty_house(hub, "SouthHouse", Vector3(4, 0.3, 14), Color(0.78, 0.62, 0.42), WorldPalette.ROOF, 0.0, Vector3(5.4, 2.5, 4.6))
	## Eastern red house (larger).
	_salty_house(hub, "RedHouse", Vector3(18, 0.5, 2), WorldPalette.ROOF_RED.lightened(0.15), WorldPalette.ROOF, -90.0, Vector3(6.2, 3.0, 5.2))

	## Gas station — NE corner of the hollow (OG Salty landmark).
	_gas_station(hub, Vector3(16, 0.2, -14))

	## Parked cars / street clutter.
	_car(hub, Vector3(-4, 0, -2), Color(0.75, 0.22, 0.2), 20.0)
	_car(hub, Vector3(8, 0, 4), Color(0.2, 0.4, 0.7), -15.0)

	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SaltyBlueBasementChest", Vector3(-18, 0.4, -10), ChestInteractable.Rarity.RARE, 0.0, "Search the blue house yard")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SaltyGasChest", Vector3(18, 0.2, -16), ChestInteractable.Rarity.NORMAL, 24.0, "Check the gas station")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SaltyRedAtticChest", Vector3(20, 0.5, 6), ChestInteractable.Rarity.RARE, 18.0, "Hunt the red house stash")
	)

	RegionPropKit.add_discoverable(hub, &"salty_springs", "Salty Springs", Vector3(0, 0.5, 18), 20, "A steep little neighborhood — five houses, one gas station, lots of attitude.")
	RegionPropKit.add_discoverable(hub, &"mineral_spring", "Hill Overlook", Vector3(-22, 1.2, -18), 15, "From the northwest hill you can see the whole hollow.")


static func _salty_house(parent: Node3D, house_name: String, pos: Vector3, wall: Color, roof: Color, yaw: float, size: Vector3) -> void:
	var h := Node3D.new()
	h.name = house_name
	h.position = pos
	h.rotation_degrees.y = yaw
	parent.add_child(h)
	StylizedMesh.add_box(h, size, wall, Vector3(0, size.y * 0.5, 0), "Body", true, 1.0, &"brick")
	StylizedMesh.add_box(h, Vector3(size.x + 0.6, 0.4, size.z + 0.6), roof, Vector3(0, size.y + 0.15, 0), "Roof", false, 1.0, &"wood")
	StylizedMesh.add_box(h, Vector3(1.0, 1.8, 0.1), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.0, size.z * 0.5 + 0.02), "Door", false, 1.0, &"wood")
	StylizedMesh.add_window_pane(h, Vector3(0.85, 0.75, 0.08), Vector3(-size.x * 0.28, 1.5, size.z * 0.5 + 0.02), "Win")
	StylizedMesh.add_box(h, Vector3(2.6, 1.8, 3.2), wall.darkened(0.05), Vector3(size.x * 0.55, 0.9, -0.2), "Garage", true, 1.0, &"brick")


static func _gas_station(parent: Node3D, pos: Vector3) -> void:
	var g := Node3D.new()
	g.name = "SaltyGasStation"
	g.position = pos
	parent.add_child(g)
	StylizedMesh.add_box(g, Vector3(12, 0.1, 10), WorldPalette.ROAD, Vector3(0, 0.06, 0), "Lot", true, 1.0, &"asphalt")
	StylizedMesh.add_box(g, Vector3(6.5, 3.0, 4.8), Color(0.86, 0.76, 0.28), Vector3(2.0, 1.5, 1.2), "Shop", true, 1.0, &"brick")
	StylizedMesh.add_box(g, Vector3(7.4, 0.3, 5.6), WorldPalette.ROOF_RED, Vector3(2.0, 3.15, 1.2), "ShopRoof", false, 1.0, &"wood")
	StylizedMesh.add_box(g, Vector3(8, 0.22, 4.5), WorldPalette.ROAD.darkened(0.1), Vector3(-1.5, 3.0, -1.5), "Canopy")
	StylizedMesh.add_box(g, Vector3(0.28, 2.9, 0.28), WorldPalette.METAL, Vector3(-4, 1.45, -1.5), "Post1", true)
	StylizedMesh.add_box(g, Vector3(0.28, 2.9, 0.28), WorldPalette.METAL, Vector3(1, 1.45, -1.5), "Post2", true)
	StylizedMesh.add_box(g, Vector3(0.7, 1.4, 0.55), WorldPalette.ROOF_RED, Vector3(-4, 0.8, -2.2), "Pump1", true)
	StylizedMesh.add_box(g, Vector3(0.7, 1.4, 0.55), WorldPalette.ROOF_RED, Vector3(0, 0.8, -2.2), "Pump2", true)
	StylizedMesh.add_window_pane(g, Vector3(1.4, 1.4, 0.08), Vector3(2.0, 1.7, 3.65), "ShopWin")
	RegionPropKit.add_discoverable(g, &"salty_gas", "Salty Gas Station", Vector3(0, 0.6, 3.5), 12, "Yellow shop, red canopy — fuel for the hills.")


static func _car(parent: Node3D, pos: Vector3, color: Color, yaw: float) -> void:
	var car := Node3D.new()
	car.position = pos
	car.rotation_degrees.y = yaw
	parent.add_child(car)
	StylizedMesh.add_box(car, Vector3(1.7, 0.5, 3.2), color, Vector3(0, 0.4, 0), "Body", true)
	StylizedMesh.add_box(car, Vector3(1.4, 0.4, 1.5), color.lightened(0.08), Vector3(0, 0.85, -0.2), "Cabin")
