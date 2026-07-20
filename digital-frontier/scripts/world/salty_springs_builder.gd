class_name SaltySpringsBuilder
extends RefCounted
## Salty Springs — smaller hillside settlement NE of Pleasant Park.
## Different house layouts, surrounding hills, short exploration loops.


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "SaltySprings"
	hub.position = origin
	root.add_child(hub)

	## Terraced hillside ground.
	StylizedMesh.add_box(hub, Vector3(90, 0.28, 80), WorldPalette.GRASS_DARK, Vector3(0, -0.12, 0), "Ground", true, 1.0, &"grass")
	StylizedMesh.add_box(hub, Vector3(40, 1.4, 18), WorldPalette.ROCK, Vector3(-18, 0.5, -22), "HillW", true)
	StylizedMesh.add_box(hub, Vector3(22, 2.0, 28), WorldPalette.ROCK.darkened(0.05), Vector3(24, 0.8, -8), "HillE", true)
	StylizedMesh.add_box(hub, Vector3(28, 0.06, 28), WorldPalette.GRASS_LIGHT, Vector3(0, 0.04, 0), "Plaza", false, 1.0, &"grass")

	## Compact street loop (not a full ring like Pleasant Park).
	StylizedMesh.add_box(hub, Vector3(28, 0.07, 4.2), WorldPalette.ROAD, Vector3(0, 0.05, -8), "RoadN", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(28, 0.07, 4.2), WorldPalette.ROAD, Vector3(0, 0.05, 10), "RoadS", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(4.2, 0.07, 22), WorldPalette.ROAD, Vector3(-12, 0.05, 1), "RoadW", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(4.2, 0.07, 22), WorldPalette.ROAD, Vector3(12, 0.05, 1), "RoadE", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(3.0, 0.05, 18), WorldPalette.PATH, Vector3(0, 0.06, 1), "Lane", false, 1.0, &"dirt")

	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, 18), "SALTY SPRINGS", &"salty_springs_welcome")

	## Four unique hillside cottages — one enterable.
	RegionPropKit.make_enterable_house(
		hub, "SpringCottage", Vector3(-8, 0, -14), Color(0.82, 0.72, 0.55), WorldPalette.ROOF, 0.0, result
	)
	_simple_house(hub, "BlueBungalow", Vector3(10, 0, -12), Color(0.45, 0.62, 0.88), WorldPalette.ROOF_RED, 20.0)
	_simple_house(hub, "Saltbox", Vector3(-14, 0, 8), Color(0.9, 0.88, 0.8), WorldPalette.ROOF, -15.0)
	_simple_house(hub, "CliffHouse", Vector3(16, 0, 6), Color(0.62, 0.48, 0.38), Color(0.35, 0.28, 0.22), -90.0)

	## Spring pool landmark (namesake).
	var spring := Node3D.new()
	spring.name = "MineralSpring"
	spring.position = Vector3(0, 0, -2)
	hub.add_child(spring)
	StylizedMesh.add_box(spring, Vector3(5.5, 0.35, 5.5), WorldPalette.ROCK, Vector3(0, 0.15, 0), "Rim", true)
	var pool := MeshInstance3D.new()
	pool.name = "Pool"
	var pm := BoxMesh.new()
	pm.size = Vector3(4.2, 0.12, 4.2)
	pool.mesh = pm
	pool.material_override = StylizedMesh.make_water_material(WorldPalette.WATER.lightened(0.1))
	pool.position = Vector3(0, 0.28, 0)
	spring.add_child(pool)
	StylizedMesh.add_box(spring, Vector3(0.5, 0.8, 0.5), WorldPalette.METAL, Vector3(0, 0.7, 0), "Spout")
	RegionPropKit.add_discoverable(spring, &"mineral_spring", "Mineral Spring", Vector3(0, 0.6, 2.5), 15, "Warm mineral mist — the springs that named the town.")

	## Pine ring + short trail loop.
	for i in 10:
		var a := float(i) / 10.0 * TAU
		var p := Vector3(cos(a) * 28.0, 0, sin(a) * 24.0)
		StylizedMesh.add_box(hub, Vector3(0.35, 1.8, 0.35), WorldPalette.TRUNK, p + Vector3(0, 0.9, 0), "PineTrunk", false, 1.0, &"wood")
		StylizedMesh.add_box(hub, Vector3(1.4, 1.2, 1.4), WorldPalette.LEAF_DARK, p + Vector3(0, 2.2, 0), "PineTop", false, 1.0, &"grass")
		StylizedMesh.add_box(hub, Vector3(1.0, 0.9, 1.0), WorldPalette.LEAF, p + Vector3(0, 3.0, 0), "PineTip", false, 1.0, &"grass")

	## Hidden yard chest behind CliffHouse.
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SaltyYardChest", Vector3(20, 0, 2), ChestInteractable.Rarity.RARE, 24.0, "Check the hillside yard")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SaltySpringChest", Vector3(-6, 0, -4), ChestInteractable.Rarity.NORMAL, 18.0)
	)
	RegionPropKit.add_discoverable(hub, &"salty_springs", "Salty Springs", Vector3(0, 0.5, 12), 20, "A quieter neighborhood tucked into the hills.")


static func _simple_house(parent: Node3D, house_name: String, pos: Vector3, wall: Color, roof: Color, yaw: float) -> void:
	var h := Node3D.new()
	h.name = house_name
	h.position = pos
	h.rotation_degrees.y = yaw
	parent.add_child(h)
	StylizedMesh.add_box(h, Vector3(5.5, 2.6, 4.8), wall, Vector3(0, 1.3, 0), "Body", true, 1.0, &"brick")
	StylizedMesh.add_box(h, Vector3(6.2, 0.4, 5.4), roof, Vector3(0, 2.8, 0), "Roof", false, 1.0, &"wood")
	StylizedMesh.add_box(h, Vector3(1.0, 1.8, 0.1), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.0, 2.45), "Door", false, 1.0, &"wood")
	StylizedMesh.add_window_pane(h, Vector3(0.85, 0.75, 0.08), Vector3(-1.4, 1.6, 2.42), "Win")
