class_name FatalFieldsBuilder
extends RefCounted
## Fatal Fields — OG Athena farm (original art, not franchise IP).
## Structure: white farmhouse center, red barn, stables, silos, cornfields, sheds, creek.


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "FatalFields"
	hub.position = origin
	root.add_child(hub)

	StylizedMesh.add_box(hub, Vector3(180, 0.26, 160), WorldPalette.GRASS, Vector3(0, -0.12, 0), "Ground", true, 1.0, &"grass")
	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, -58), "FATAL FIELDS", &"fatal_fields_welcome")

	## Dirt spines — farm lanes, not a suburban grid.
	StylizedMesh.add_box(hub, Vector3(110, 0.07, 4.2), WorldPalette.DIRT, Vector3(0, 0.05, 0), "LaneEW", true, 1.0, &"dirt")
	StylizedMesh.add_box(hub, Vector3(4.2, 0.07, 100), WorldPalette.DIRT, Vector3(0, 0.05, 0), "LaneNS", true, 1.0, &"dirt")
	StylizedMesh.add_box(hub, Vector3(3.5, 0.06, 36), WorldPalette.DIRT.darkened(0.05), Vector3(28, 0.05, -18), "LaneBarn", true, 1.0, &"dirt")

	## Corn fields (OG read = tall golden corn patches, not mixed produce quilt).
	var corn := Color(0.78, 0.68, 0.22)
	var corn_dark := Color(0.62, 0.52, 0.16)
	var fields := [
		Vector3(-40, 0, -35), Vector3(-40, 0, 30), Vector3(40, 0, -35), Vector3(42, 0, 28),
		Vector3(-55, 0, 0), Vector3(55, 0, -5),
	]
	for i in fields.size():
		var p: Vector3 = fields[i]
		StylizedMesh.add_box(hub, Vector3(22, 1.1, 18), corn if i % 2 == 0 else corn_dark, p + Vector3(0, 0.55, 0), "Corn_%d" % i, false, 1.0, &"leaf")
		for r in 4:
			StylizedMesh.add_box(
				hub,
				Vector3(20, 0.12, 0.2),
				WorldPalette.DIRT,
				p + Vector3(0, 0.15, -6.0 + float(r) * 4.0),
				"Furrow",
				false,
				1.0,
				&"dirt",
			)

	## White farmhouse — CENTER of the farm (OG identity).
	RegionPropKit.make_enterable_building(
		hub, "WhiteFarmhouse", Vector3(-6, 0, 6), Color(0.92, 0.92, 0.88), WorldPalette.ROOF_RED, 180.0, result, InteriorKinds.FARMHOUSE
	)
	StylizedMesh.add_box(hub, Vector3(2.8, 0.2, 2.0), WorldPalette.WOOD, Vector3(-6, 0.2, 10), "PorchExtra", false, 1.0, &"wood")

	## Big red barn east of house.
	RegionPropKit.make_enterable_building(hub, "RedBarn", Vector3(22, 0, -6), WorldPalette.ROOF_RED, WorldPalette.ROOF, 0.0, result, InteriorKinds.BARN, Vector3(11.0, 5.5, 8.0))
	## Stables north of barn.
	RegionPropKit.make_enterable_building(hub, "Stables", Vector3(24, 0, -28), Color(0.62, 0.48, 0.32), WorldPalette.ROOF, 0.0, result, InteriorKinds.BARN, Vector3(12.0, 3.0, 5.5))
	## Smaller gray/white barn north-west.
	RegionPropKit.make_enterable_building(hub, "GrayBarn", Vector3(-28, 0, -18), Color(0.72, 0.72, 0.68), WorldPalette.ROOF, 90.0, result, InteriorKinds.BARN, Vector3(7.5, 4.0, 5.5))
	## Tiny barn / hay shed south.
	RegionPropKit.make_enterable_building(hub, "HayShed", Vector3(-20, 0, 28), WorldPalette.ROOF_RED.lightened(0.05), WorldPalette.ROOF, 0.0, result, InteriorKinds.WAREHOUSE, Vector3(5.0, 3.0, 4.0))

	## Twin metal silos (OG chest-in-silo legend).
	StylizedMesh.add_box(hub, Vector3(3.4, 9.0, 3.4), WorldPalette.METAL, Vector3(12, 4.5, 18), "SiloA", true)
	StylizedMesh.add_box(hub, Vector3(3.8, 0.35, 3.8), WorldPalette.ROOF_RED, Vector3(12, 9.2, 18), "SiloACap")
	StylizedMesh.add_box(hub, Vector3(3.4, 9.0, 3.4), WorldPalette.METAL.darkened(0.05), Vector3(18, 4.5, 18), "SiloB", true)
	StylizedMesh.add_box(hub, Vector3(3.8, 0.35, 3.8), WorldPalette.ROOF_RED, Vector3(18, 9.2, 18), "SiloBCap")

	## Field sheds + hay.
	RegionPropKit.make_enterable_building(hub, "FieldShedWest", Vector3(-48, 0, -20), Color(0.88, 0.86, 0.8), WorldPalette.ROOF, 0.0, result, InteriorKinds.WAREHOUSE, Vector3(5.0, 2.8, 4.0))
	RegionPropKit.make_enterable_building(hub, "FieldShedEast", Vector3(48, 0, 10), Color(0.45, 0.55, 0.35), WorldPalette.ROOF, 180.0, result, InteriorKinds.WAREHOUSE, Vector3(5.0, 2.8, 4.0))
	RegionPropKit.make_enterable_building(hub, "FieldShedSouth", Vector3(-50, 0, 25), Color(0.78, 0.7, 0.35), WorldPalette.ROOF, 90.0, result, InteriorKinds.WAREHOUSE, Vector3(5.0, 2.8, 4.0))
	for i in 6:
		StylizedMesh.add_box(
			hub,
			Vector3(1.6, 1.15, 1.0),
			corn,
			Vector3(-12.0 + float(i) * 2.3, 0.55, -12),
			"Hay",
			false,
			1.0,
			&"dirt",
		)

	## Tractor near barn.
	_tractor(hub, Vector3(10, 0, -18))

	## Creek / stream along north edge (OG stream alcove).
	var creek := Node3D.new()
	creek.name = "FarmCreek"
	creek.position = Vector3(-10, 0, -48)
	hub.add_child(creek)
	StylizedMesh.add_box(creek, Vector3(50, 0.2, 6), WorldPalette.ROCK, Vector3(0, -0.05, 0), "Bed", true, 1.0, &"dirt")
	var water := MeshInstance3D.new()
	water.name = "Water"
	var wm := BoxMesh.new()
	wm.size = Vector3(46, 0.1, 4.2)
	water.mesh = wm
	water.material_override = StylizedMesh.make_water_material(WorldPalette.WATER)
	water.position = Vector3(0, 0.05, 0)
	creek.add_child(water)
	## Creek bank detail — rocks + reeds.
	for i in 5:
		StylizedMesh.add_box(creek, Vector3(0.45, 0.3, 0.35), WorldPalette.ROCK.darkened(0.05 * float(i % 3)), Vector3(-16 + float(i) * 7, 0.15, 2.2), "BankRock", false, 1.0, &"dirt")
		StylizedMesh.add_box(creek, Vector3(0.1, 0.45, 0.1), WorldPalette.LEAF_DARK, Vector3(-14 + float(i) * 7, 0.25, -2.0), "Reed", false, 1.0, &"leaf")
	StylizedMesh.add_box(creek, Vector3(3.5, 1.6, 2.5), WorldPalette.ROCK.darkened(0.1), Vector3(18, 0.6, 0), "Alcove", true, 1.0, &"dirt")
	RegionPropKit.add_discoverable(creek, &"farm_creek", "Farm Creek", Vector3(18, 0.8, 2), 14, "A cool alcove where the stream ducks underground.")

	## Animal pen / stables yard.
	_fence_rect(hub, Vector3(36, 0, -28), 18, 14)
	StylizedMesh.add_box(hub, Vector3(1.2, 0.9, 2.0), Color(0.92, 0.9, 0.85), Vector3(34, 0.5, -28), "SheepA")
	StylizedMesh.add_box(hub, Vector3(1.1, 0.85, 1.8), Color(0.88, 0.86, 0.8), Vector3(38, 0.45, -26), "SheepB")
	RegionPropKit.add_discoverable(hub, &"animal_pen", "Stables Yard", Vector3(36, 0.6, -22), 12, "Soft bleats beside the long stables.")

	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SiloStashChest", Vector3(12, 0, 20), ChestInteractable.Rarity.RARE, 0.0, "Crack the silo stash")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "RedBarnLoftChest", Vector3(22, 0, -12), ChestInteractable.Rarity.LEGENDARY, 0.0, "Climb the red barn loft")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "CornMazeChest", Vector3(-40, 0, -35), ChestInteractable.Rarity.NORMAL, 24.0, "Search the corn rows")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "CreekAlcoveChest", Vector3(8, 0, -48), ChestInteractable.Rarity.RARE, 18.0, "Check the creek alcove")
	)

	RegionPropKit.add_discoverable(hub, &"fatal_fields", "Fatal Fields", Vector3(0, 0.5, -50), 22, "White farmhouse, red barn, corn to the horizon.")
	RegionPropKit.add_discoverable(hub, &"red_barn", "Red Barn", Vector3(22, 0.5, -6), 14, "Paint peeled by seasons — still standing proud.")


static func _red_barn(parent: Node3D, pos: Vector3) -> void:
	var b := Node3D.new()
	b.position = pos
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(12, 6.5, 9), WorldPalette.ROOF_RED, Vector3(0, 3.25, 0), "BarnBody", true, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(13.2, 1.4, 10.2), WorldPalette.ROOF_RED.darkened(0.15), Vector3(0, 7.0, 0), "BarnRoof", false, 1.0, &"roof")
	StylizedMesh.add_box(b, Vector3(4.0, 4.2, 0.15), WorldPalette.WOOD.darkened(0.25), Vector3(0, 2.2, 4.55), "BarnDoor", false, 1.0, &"wood")
	StylizedMesh.add_window_pane(b, Vector3(1.4, 1.4, 0.1), Vector3(0, 5.2, 4.55), "LoftWin")


static func _stables(parent: Node3D, pos: Vector3) -> void:
	var s := Node3D.new()
	s.position = pos
	parent.add_child(s)
	StylizedMesh.add_box(s, Vector3(14, 3.2, 6), Color(0.62, 0.48, 0.32), Vector3(0, 1.6, 0), "StableBody", true, 1.0, &"wood")
	StylizedMesh.add_box(s, Vector3(15, 0.35, 7), WorldPalette.WOOD.darkened(0.1), Vector3(0, 3.4, 0), "StableRoof", false, 1.0, &"roof")
	for i in 4:
		StylizedMesh.add_box(s, Vector3(0.12, 2.2, 2.8), WorldPalette.WOOD, Vector3(-5.0 + float(i) * 3.2, 1.2, 0), "Stall", false, 1.0, &"wood")


static func _small_barn(parent: Node3D, pos: Vector3, color: Color) -> void:
	var b := Node3D.new()
	b.position = pos
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(8, 4.2, 6), color, Vector3(0, 2.1, 0), "Body", true, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(9, 0.9, 7), color.darkened(0.12), Vector3(0, 4.5, 0), "Roof", false, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(2.8, 2.8, 0.12), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.5, 3.05), "Door", false, 1.0, &"wood")


static func _tiny_barn(parent: Node3D, pos: Vector3) -> void:
	var b := Node3D.new()
	b.position = pos
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(5, 3.0, 4), WorldPalette.ROOF_RED.lightened(0.05), Vector3(0, 1.5, 0), "Body", true, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(5.6, 0.5, 4.6), WorldPalette.WOOD, Vector3(0, 3.2, 0), "Roof", false, 1.0, &"wood")


static func _field_shed(parent: Node3D, pos: Vector3, color: Color) -> void:
	var s := Node3D.new()
	s.position = pos
	parent.add_child(s)
	StylizedMesh.add_box(s, Vector3(4.5, 2.4, 3.5), color, Vector3(0, 1.2, 0), "Shed", true, 1.0, &"wood")
	StylizedMesh.add_box(s, Vector3(5.0, 0.25, 4.0), WorldPalette.WOOD.darkened(0.15), Vector3(0, 2.5, 0), "Roof", false, 1.0, &"wood")


static func _tractor(parent: Node3D, pos: Vector3) -> void:
	var t := Node3D.new()
	t.position = pos
	parent.add_child(t)
	StylizedMesh.add_box(t, Vector3(2.4, 1.2, 3.6), Color(0.25, 0.55, 0.28), Vector3(0, 0.9, 0), "Body", true)
	StylizedMesh.add_box(t, Vector3(1.6, 1.0, 1.4), Color(0.2, 0.45, 0.22), Vector3(0, 1.7, -0.6), "Cabin")
	StylizedMesh.add_box(t, Vector3(0.5, 1.4, 1.4), WorldPalette.UI_INK, Vector3(-1.3, 0.7, 1.0), "WheelL")
	StylizedMesh.add_box(t, Vector3(0.5, 1.4, 1.4), WorldPalette.UI_INK, Vector3(1.3, 0.7, 1.0), "WheelR")


static func _fence_rect(parent: Node3D, center: Vector3, width: float, depth: float) -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var posts := 5
	for i in posts:
		var t := float(i) / float(posts - 1)
		var x := -hw + width * t
		StylizedMesh.add_box(parent, Vector3(0.12, 1.0, 0.12), WorldPalette.WOOD, center + Vector3(x, 0.5, -hd), "FP", false, 1.0, &"wood")
		StylizedMesh.add_box(parent, Vector3(0.12, 1.0, 0.12), WorldPalette.WOOD, center + Vector3(x, 0.5, hd), "FP", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(width, 0.08, 0.08), WorldPalette.WOOD, center + Vector3(0, 0.75, -hd), "Rail", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(width, 0.08, 0.08), WorldPalette.WOOD, center + Vector3(0, 0.75, hd), "Rail", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(0.08, 0.08, depth), WorldPalette.WOOD, center + Vector3(-hw, 0.75, 0), "Rail", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(0.08, 0.08, depth), WorldPalette.WOOD, center + Vector3(hw, 0.75, 0), "Rail", false, 1.0, &"wood")
