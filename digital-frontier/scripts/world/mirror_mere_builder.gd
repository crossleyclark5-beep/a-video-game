class_name MirrorMereBuilder
extends RefCounted
## Mirror Mere — Digital Frontier central lake hub.
## Inspired by classic “lake with an island” Named Location roles (original art).


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "MirrorMere"
	hub.position = origin
	root.add_child(hub)

	StylizedMesh.add_box(hub, Vector3(140, 0.24, 120), WorldPalette.GRASS_LIGHT, Vector3(0, -0.1, 0), "ShoreGround", true, 1.0, &"grass")
	## Lake bowl.
	StylizedMesh.add_box(hub, Vector3(70, 0.2, 58), WorldPalette.ROCK.darkened(0.1), Vector3(0, -0.05, 0), "LakeBed", true, 1.0, &"dirt")
	var water := MeshInstance3D.new()
	water.name = "MereWater"
	var wm := BoxMesh.new()
	wm.size = Vector3(64, 0.12, 52)
	water.mesh = wm
	water.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
	water.position = Vector3(0, 0.08, 0)
	hub.add_child(water)
	## Reed ring.
	for i in 12:
		var a := float(i) * TAU / 12.0
		var rp := Vector3(cos(a) * 34.0, 0.2, sin(a) * 28.0)
		StylizedMesh.add_box(hub, Vector3(0.12, 0.55, 0.12), WorldPalette.LEAF_DARK, rp, "Reed_%d" % i, false, 1.0, &"leaf")

	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, 42), "MIRROR MERE", &"mirror_mere_welcome")

	## Shore cottages.
	RegionPropKit.make_enterable_building(
		hub, "ShoreCabinNorth", Vector3(-8, 0, -38), Color(0.82, 0.78, 0.68), WorldPalette.ROOF, 180.0, result, InteriorKinds.CABIN
	)
	RegionPropKit.make_enterable_building(hub, "EastCottage", Vector3(38, 0, 4), Color(0.55, 0.62, 0.78), WorldPalette.ROOF_RED, -90.0, result, InteriorKinds.CABIN)
	RegionPropKit.make_enterable_building(hub, "WestCottage", Vector3(-40, 0, 6), Color(0.72, 0.55, 0.42), WorldPalette.ROOF, 90.0, result, InteriorKinds.CABIN)

	## Boathouse + pier.
	RegionPropKit.make_enterable_building(hub, "Boathouse", Vector3(22, 0, 28), WorldPalette.WOOD, WorldPalette.ROOF_RED.darkened(0.1), 0.0, result, InteriorKinds.WAREHOUSE, Vector3(6.0, 3.0, 5.0))
	_pier(hub, Vector3(0, 0, 22))

	## Island landmark.
	_island(hub, result)

	## Docked rowboats.
	_boat(hub, Vector3(8, 0.15, 18), 15.0)
	_boat(hub, Vector3(-10, 0.15, 20), -25.0)

	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "MerePierChest", Vector3(0, 0.3, 26), ChestInteractable.Rarity.NORMAL, 24.0, "Check under the pier")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "MereBoathouseChest", Vector3(24, 0.2, 28), ChestInteractable.Rarity.RARE, 18.0, "Search the boathouse")
	)

	RegionPropKit.add_discoverable(hub, &"mirror_mere", "Mirror Mere", Vector3(0, 0.5, 36), 22, "The mere holds a quiet island — reflections look almost like another map.")
	RegionPropKit.add_discoverable(hub, &"mere_island", "Mere Island", Vector3(0, 1.2, 0), 16, "A cabin on still water. Something digital hums beneath the floorboards.")


static func _shore_cottage(parent: Node3D, house_name: String, pos: Vector3, wall: Color, roof: Color, yaw: float) -> void:
	var h := Node3D.new()
	h.name = house_name
	h.position = pos
	h.rotation_degrees.y = yaw
	parent.add_child(h)
	StylizedMesh.add_box(h, Vector3(5.2, 2.6, 4.4), wall, Vector3(0, 1.3, 0), "Body", true, 1.0, &"wood")
	StylizedMesh.add_box(h, Vector3(5.8, 0.4, 5.0), roof, Vector3(0, 2.85, 0), "Roof", false, 1.0, &"roof")
	StylizedMesh.add_box(h, Vector3(1.0, 1.8, 0.1), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.0, 2.25), "Door", false, 1.0, &"wood")
	StylizedMesh.add_window_pane(h, Vector3(0.9, 0.8, 0.08), Vector3(-1.4, 1.6, 2.25), "Win")
	StylizedMesh.add_box(h, Vector3(1.4, 0.3, 0.5), WorldPalette.WOOD, Vector3(-1.4, 1.05, 2.4), "FlowerBox", false, 1.0, &"wood")
	StylizedMesh.add_box(h, Vector3(0.22, 0.22, 0.22), WorldPalette.FLOWER, Vector3(-1.4, 1.3, 2.45), "Flower")


static func _boathouse(parent: Node3D, pos: Vector3) -> void:
	var b := Node3D.new()
	b.name = "Boathouse"
	b.position = pos
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(6.5, 3.2, 5.0), WorldPalette.WOOD, Vector3(0, 1.6, 0), "Shed", true, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(7.2, 0.35, 5.6), WorldPalette.ROOF_RED.darkened(0.1), Vector3(0, 3.4, 0), "Roof", false, 1.0, &"roof")
	StylizedMesh.add_box(b, Vector3(2.4, 2.2, 0.12), WorldPalette.WOOD.darkened(0.25), Vector3(0, 1.2, 2.55), "Door", false, 1.0, &"wood")
	StylizedMesh.add_window_pane(b, Vector3(1.0, 0.9, 0.08), Vector3(-1.8, 1.8, 2.55), "Win")


static func _pier(parent: Node3D, pos: Vector3) -> void:
	var p := Node3D.new()
	p.name = "FishingPier"
	p.position = pos
	parent.add_child(p)
	StylizedMesh.add_box(p, Vector3(3.2, 0.22, 10.0), WorldPalette.WOOD, Vector3(0, 0.25, -3.0), "Deck", true, 1.0, &"wood")
	for i in 4:
		StylizedMesh.add_box(p, Vector3(0.18, 0.9, 0.18), WorldPalette.WOOD.darkened(0.1), Vector3(-1.3, 0.55, -6.0 + float(i) * 2.2), "PostL", true)
		StylizedMesh.add_box(p, Vector3(0.18, 0.9, 0.18), WorldPalette.WOOD.darkened(0.1), Vector3(1.3, 0.55, -6.0 + float(i) * 2.2), "PostR", true)
	StylizedMesh.add_box(p, Vector3(3.0, 0.08, 0.08), WorldPalette.WOOD, Vector3(0, 0.95, -6.5), "Rail")


static func _island(parent: Node3D, result: Dictionary) -> void:
	var island := Node3D.new()
	island.name = "MereIsland"
	island.position = Vector3(0, 0.15, -2)
	parent.add_child(island)
	StylizedMesh.add_box(island, Vector3(18, 1.4, 14), WorldPalette.DIRT.lightened(0.05), Vector3(0, 0.5, 0), "Isle", true, 1.0, &"dirt")
	StylizedMesh.add_box(island, Vector3(16, 0.2, 12), WorldPalette.GRASS, Vector3(0, 1.2, 0), "IsleGrass", false, 1.0, &"grass")
	## Enterable island cabin — the landmark heart.
	RegionPropKit.make_enterable_building(
		island, "IslandCabin", Vector3(0, 1.2, 0), Color(0.62, 0.42, 0.28), WorldPalette.ROOF, 0.0, result, InteriorKinds.LANDMARK
	)
	StylizedMesh.add_box(island, Vector3(0.35, 1.8, 0.35), WorldPalette.TRUNK, Vector3(-5, 2.1, 3), "Tree", false, 1.0, &"wood")
	var isle_canopy := StylizedMesh.add_box(island, Vector3(1.4, 1.1, 1.4), WorldPalette.LEAF, Vector3(-5, 3.2, 3), "Canopy", false, 1.0, &"leaf")
	OcclusionUtil.mark(isle_canopy)
	result[&"chests"].append(
		RegionPropKit.build_chest(island, "MereIslandChest", Vector3(4, 1.4, -3), ChestInteractable.Rarity.LEGENDARY, 0.0, "Pry the island crate")
	)


static func _boat(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var boat := Node3D.new()
	boat.position = pos
	boat.rotation_degrees.y = yaw
	parent.add_child(boat)
	StylizedMesh.add_box(boat, Vector3(1.2, 0.35, 2.8), WorldPalette.WOOD.darkened(0.15), Vector3(0, 0.2, 0), "Hull", false, 1.0, &"wood")
	StylizedMesh.add_box(boat, Vector3(0.08, 1.2, 0.08), WorldPalette.WOOD, Vector3(0, 0.85, 0.2), "Oar")
