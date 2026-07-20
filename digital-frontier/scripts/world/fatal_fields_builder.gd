class_name FatalFieldsBuilder
extends RefCounted
## Fatal Fields — wide farming frontier west of Pleasant Park.
## Crop grids, barns, dirt roads, fences, animal pens, hidden corners.


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "FatalFields"
	hub.position = origin
	root.add_child(hub)

	StylizedMesh.add_box(hub, Vector3(160, 0.26, 140), WorldPalette.GRASS, Vector3(0, -0.12, 0), "Ground", true, 1.0, &"grass")
	RegionPropKit.add_welcome_sign(hub, Vector3(55, 0, 0), "FATAL FIELDS", &"fatal_fields_welcome")

	## Main dirt spine + cross lanes.
	StylizedMesh.add_box(hub, Vector3(120, 0.07, 4.5), WorldPalette.DIRT, Vector3(0, 0.05, 0), "DirtEW", true, 1.0, &"dirt")
	StylizedMesh.add_box(hub, Vector3(4.5, 0.07, 90), WorldPalette.DIRT, Vector3(0, 0.05, 0), "DirtNS", true, 1.0, &"dirt")
	StylizedMesh.add_box(hub, Vector3(4.0, 0.06, 40), WorldPalette.DIRT.darkened(0.05), Vector3(30, 0.05, -20), "LaneA", true, 1.0, &"dirt")
	StylizedMesh.add_box(hub, Vector3(40, 0.06, 4.0), WorldPalette.DIRT.darkened(0.05), Vector3(-25, 0.05, 25), "LaneB", true, 1.0, &"dirt")

	## Crop field grid (golden / green quilt).
	var crop_colors := [
		Color(0.72, 0.62, 0.22),
		Color(0.55, 0.72, 0.28),
		Color(0.78, 0.68, 0.30),
		Color(0.42, 0.62, 0.28),
	]
	var idx := 0
	for z in [-40, -20, 20, 40]:
		for x in [-45, -25, 25, 45]:
			var c: Color = crop_colors[idx % crop_colors.size()]
			StylizedMesh.add_box(hub, Vector3(14, 0.35, 12), c, Vector3(float(x), 0.2, float(z)), "Crop_%d" % idx, false, 1.0, &"grass")
			## Row furrows
			for r in 3:
				StylizedMesh.add_box(
					hub,
					Vector3(13, 0.08, 0.25),
					c.darkened(0.12),
					Vector3(float(x), 0.4, float(z) - 4.0 + float(r) * 4.0),
					"Furrow",
					false,
					1.0,
					&"dirt",
				)
			idx += 1

	## Fence rings around crop blocks.
	_fence_rect(hub, Vector3(-35, 0, -30), 50, 36)
	_fence_rect(hub, Vector3(35, 0, 30), 50, 36)

	## Farmhouse (enterable) + big barn.
	RegionPropKit.make_enterable_house(
		hub, "FieldFarmhouse", Vector3(-8, 0, 12), Color(0.86, 0.78, 0.62), WorldPalette.ROOF_RED, 180.0, result
	)
	_barn(hub, Vector3(18, 0, -8))
	_barn(hub, Vector3(-30, 0, 8), 0.85)

	## Silo + tractor + hay.
	StylizedMesh.add_box(hub, Vector3(3.2, 8.0, 3.2), WorldPalette.METAL, Vector3(28, 4.0, 8), "Silo", true)
	StylizedMesh.add_box(hub, Vector3(3.6, 0.4, 3.6), WorldPalette.ROOF_RED, Vector3(28, 8.2, 8), "SiloCap")
	_tractor(hub, Vector3(8, 0, 22))
	for i in 5:
		StylizedMesh.add_box(
			hub,
			Vector3(1.6, 1.2, 1.0),
			Color(0.78, 0.62, 0.22),
			Vector3(-18.0 + float(i) * 2.2, 0.6, -18),
			"Hay",
			false,
			1.0,
			&"dirt",
		)

	## Animal pen.
	var pen := Node3D.new()
	pen.name = "AnimalPen"
	pen.position = Vector3(35, 0, -25)
	hub.add_child(pen)
	_fence_rect(pen, Vector3.ZERO, 16, 12)
	StylizedMesh.add_box(pen, Vector3(14, 0.05, 10), WorldPalette.DIRT, Vector3(0, 0.04, 0), "PenDirt", false, 1.0, &"dirt")
	StylizedMesh.add_box(pen, Vector3(1.2, 0.9, 2.0), Color(0.92, 0.9, 0.85), Vector3(-2, 0.5, 0), "SheepA")
	StylizedMesh.add_box(pen, Vector3(1.1, 0.85, 1.8), Color(0.88, 0.86, 0.8), Vector3(2, 0.45, 1), "SheepB")
	StylizedMesh.add_box(pen, Vector3(0.35, 0.35, 0.35), Color(0.2, 0.2, 0.22), Vector3(-2, 0.95, 0.7), "HeadA")
	RegionPropKit.add_discoverable(pen, &"animal_pen", "Animal Pen", Vector3(0, 0.6, 6), 12, "Soft bleats and straw — the farm's quiet heart.")

	## Hidden silo stash + crop maze chest.
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SiloStashChest", Vector3(28, 0, 11), ChestInteractable.Rarity.RARE, 0.0, "Check behind the silo")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "CropMazeChest", Vector3(-45, 0, -40), ChestInteractable.Rarity.NORMAL, 24.0, "Search the crop rows")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "BarnLoftChest", Vector3(18, 0, -14), ChestInteractable.Rarity.LEGENDARY, 0.0, "Climb into the loft stash")
	)

	RegionPropKit.add_discoverable(hub, &"fatal_fields", "Fatal Fields", Vector3(40, 0.5, 0), 22, "Wide sky. Longer rows. Secrets between the furrows.")
	RegionPropKit.add_discoverable(hub, &"red_barn", "Red Barn", Vector3(18, 0.5, -8), 14, "Paint peeled by seasons — still standing proud.")


static func _barn(parent: Node3D, pos: Vector3, scale_v: float = 1.0) -> void:
	var b := Node3D.new()
	b.position = pos
	b.scale = Vector3(scale_v, scale_v, scale_v)
	parent.add_child(b)
	StylizedMesh.add_box(b, Vector3(10, 5.5, 8), WorldPalette.ROOF_RED, Vector3(0, 2.75, 0), "BarnBody", true, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(11, 1.2, 9), WorldPalette.ROOF_RED.darkened(0.15), Vector3(0, 5.8, 0), "BarnRoof", false, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(3.5, 3.8, 0.15), WorldPalette.WOOD.darkened(0.25), Vector3(0, 2.0, 4.05), "BarnDoor", false, 1.0, &"wood")
	StylizedMesh.add_box(b, Vector3(1.2, 1.2, 0.1), WorldPalette.WINDOW, Vector3(0, 4.2, 4.05), "LoftWin")


static func _tractor(parent: Node3D, pos: Vector3) -> void:
	var t := Node3D.new()
	t.position = pos
	parent.add_child(t)
	StylizedMesh.add_box(t, Vector3(2.4, 1.2, 3.6), Color(0.25, 0.55, 0.28), Vector3(0, 0.9, 0), "Body", true)
	StylizedMesh.add_box(t, Vector3(1.6, 1.0, 1.4), Color(0.2, 0.45, 0.22), Vector3(0, 1.7, -0.6), "Cabin")
	StylizedMesh.add_box(t, Vector3(0.5, 1.4, 1.4), WorldPalette.UI_INK, Vector3(-1.3, 0.7, 1.0), "WheelL")
	StylizedMesh.add_box(t, Vector3(0.5, 1.4, 1.4), WorldPalette.UI_INK, Vector3(1.3, 0.7, 1.0), "WheelR")
	StylizedMesh.add_box(t, Vector3(0.4, 0.8, 0.8), WorldPalette.UI_INK, Vector3(-1.1, 0.45, -1.2), "WheelFL")
	StylizedMesh.add_box(t, Vector3(0.4, 0.8, 0.8), WorldPalette.UI_INK, Vector3(1.1, 0.45, -1.2), "WheelFR")


static func _fence_rect(parent: Node3D, center: Vector3, width: float, depth: float) -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var posts := 6
	for i in posts:
		var t := float(i) / float(posts - 1)
		var x := -hw + width * t
		StylizedMesh.add_box(parent, Vector3(0.12, 1.0, 0.12), WorldPalette.WOOD, center + Vector3(x, 0.5, -hd), "FP", false, 1.0, &"wood")
		StylizedMesh.add_box(parent, Vector3(0.12, 1.0, 0.12), WorldPalette.WOOD, center + Vector3(x, 0.5, hd), "FP", false, 1.0, &"wood")
	for i in posts:
		var t := float(i) / float(posts - 1)
		var z := -hd + depth * t
		StylizedMesh.add_box(parent, Vector3(0.12, 1.0, 0.12), WorldPalette.WOOD, center + Vector3(-hw, 0.5, z), "FP", false, 1.0, &"wood")
		StylizedMesh.add_box(parent, Vector3(0.12, 1.0, 0.12), WorldPalette.WOOD, center + Vector3(hw, 0.5, z), "FP", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(width, 0.08, 0.08), WorldPalette.WOOD, center + Vector3(0, 0.75, -hd), "Rail", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(width, 0.08, 0.08), WorldPalette.WOOD, center + Vector3(0, 0.75, hd), "Rail", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(0.08, 0.08, depth), WorldPalette.WOOD, center + Vector3(-hw, 0.75, 0), "Rail", false, 1.0, &"wood")
	StylizedMesh.add_box(parent, Vector3(0.08, 0.08, depth), WorldPalette.WOOD, center + Vector3(hw, 0.75, 0), "Rail", false, 1.0, &"wood")
