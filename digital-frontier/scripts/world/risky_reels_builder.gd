class_name RiskyReelsBuilder
extends RefCounted
## Risky Reels — outdoor movie theater destination SE of Pleasant Park.
## Screen, parking, abandoned booths, props, collectibles.


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "RiskyReels"
	hub.position = origin
	root.add_child(hub)

	StylizedMesh.add_box(hub, Vector3(120, 0.26, 110), WorldPalette.GRASS_DARK, Vector3(0, -0.12, 0), "Ground", true, 1.0, &"grass")
	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, 42), "RISKY REELS", &"risky_reels_welcome")

	## Parking lot.
	StylizedMesh.add_box(hub, Vector3(55, 0.08, 35), WorldPalette.ROAD, Vector3(0, 0.04, 18), "Lot", true, 1.0, &"asphalt")
	for i in 6:
		StylizedMesh.add_box(hub, Vector3(0.1, 0.02, 4.5), Color(0.9, 0.9, 0.85), Vector3(-20 + float(i) * 8.0, 0.1, 22), "Stall")
	_parked_car(hub, Vector3(-12, 0, 16), Color(0.75, 0.22, 0.2), 15.0)
	_parked_car(hub, Vector3(4, 0, 18), Color(0.2, 0.35, 0.7), -10.0)
	_parked_car(hub, Vector3(18, 0, 14), Color(0.85, 0.85, 0.8), 5.0)

	## Giant outdoor screen facing south (+Z parking).
	var screen := Node3D.new()
	screen.name = "DriveInScreen"
	screen.position = Vector3(0, 0, -28)
	hub.add_child(screen)
	StylizedMesh.add_box(screen, Vector3(2.0, 14.0, 1.5), WorldPalette.METAL, Vector3(-18, 7.0, 0), "PostL", true)
	StylizedMesh.add_box(screen, Vector3(2.0, 14.0, 1.5), WorldPalette.METAL, Vector3(18, 7.0, 0), "PostR", true)
	StylizedMesh.add_box(screen, Vector3(40, 18, 1.2), WorldPalette.UI_INK, Vector3(0, 10.0, 0), "ScreenFrame", true)
	StylizedMesh.add_box(screen, Vector3(36, 15, 0.4), Color(0.55, 0.72, 0.85), Vector3(0, 10.0, 0.5), "Screen")
	StylizedMesh.add_box(screen, Vector3(8, 0.6, 0.3), WorldPalette.UI_ACCENT, Vector3(0, 3.2, 0.6), "Marquee")
	var label := Label3D.new()
	label.text = "FEATURE PRESENTATION"
	label.font_size = 96
	label.position = Vector3(0, 10.0, 0.9)
	label.modulate = WorldPalette.UI_PAPER
	screen.add_child(label)
	RegionPropKit.add_discoverable(screen, &"drive_in_screen", "Drive-In Screen", Vector3(0, 1.0, 4), 18, "A silver cliff for stories — still waiting for an audience.")

	## Projection booth (enterable abandoned building).
	RegionPropKit.make_enterable_house(
		hub, "ProjectionBooth", Vector3(-22, 0, -8), Color(0.35, 0.36, 0.4), WorldPalette.ROOF, 90.0, result
	)
	StylizedMesh.add_box(hub, Vector3(4.5, 2.2, 3.5), WorldPalette.METAL.darkened(0.1), Vector3(22, 1.1, -6), "SnackShack", true)
	StylizedMesh.add_box(hub, Vector3(5.0, 0.3, 4.0), WorldPalette.ROOF_RED, Vector3(22, 2.35, -6), "SnackRoof", false, 1.0, &"wood")
	StylizedMesh.add_box(hub, Vector3(2.0, 1.2, 0.1), WorldPalette.WINDOW, Vector3(22, 1.3, -4.2), "SnackWindow")

	## Speaker poles + movie props scattered in the lot.
	for i in 8:
		var x := -24.0 + float(i) * 7.0
		StylizedMesh.add_box(hub, Vector3(0.15, 1.6, 0.15), WorldPalette.METAL, Vector3(x, 0.8, 6), "SpeakerPole", true)
		StylizedMesh.add_box(hub, Vector3(0.45, 0.35, 0.3), WorldPalette.UI_INK, Vector3(x, 1.55, 6), "Speaker")

	## Prop pile: cardboard rocket, ticket booth ruin, film reels.
	StylizedMesh.add_box(hub, Vector3(2.0, 4.5, 2.0), Color(0.85, 0.35, 0.25), Vector3(30, 2.2, 8), "PropRocket", true)
	StylizedMesh.add_box(hub, Vector3(2.6, 0.4, 2.6), WorldPalette.METAL, Vector3(30, 4.6, 8), "RocketFins")
	StylizedMesh.add_box(hub, Vector3(3.5, 2.8, 3.0), Color(0.55, 0.2, 0.18), Vector3(-28, 1.4, 12), "TicketRuin", true, 1.0, &"wood")
	StylizedMesh.add_box(hub, Vector3(1.0, 0.25, 1.0), WorldPalette.METAL, Vector3(12, 0.3, -4), "ReelA")
	StylizedMesh.add_box(hub, Vector3(0.85, 0.25, 0.85), WorldPalette.METAL.darkened(0.1), Vector3(13.2, 0.3, -3.2), "ReelB")

	## Abandoned office behind screen.
	StylizedMesh.add_box(hub, Vector3(8, 3.5, 6), Color(0.42, 0.4, 0.38), Vector3(0, 1.75, -38), "BackOffice", true, 1.0, &"brick")
	StylizedMesh.add_box(hub, Vector3(9, 0.35, 7), WorldPalette.ROOF, Vector3(0, 3.7, -38), "OfficeRoof", false, 1.0, &"wood")

	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "ProjectionChest", Vector3(-22, 0, -12), ChestInteractable.Rarity.RARE, 0.0, "Search the booth")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SnackShackChest", Vector3(24, 0, -8), ChestInteractable.Rarity.NORMAL, 24.0, "Rummage the snack shack")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "ReelPropChest", Vector3(30, 0, 5), ChestInteractable.Rarity.LEGENDARY, 0.0, "Check under the rocket prop")
	)

	RegionPropKit.add_discoverable(hub, &"risky_reels", "Risky Reels", Vector3(0, 0.5, 35), 24, "Lights, lot, and lingering stories under the open sky.")
	RegionPropKit.add_discoverable(hub, &"snack_shack", "Snack Shack", Vector3(22, 0.5, -4), 12, "Popcorn ghosts and sticky counters.")


static func _parked_car(parent: Node3D, pos: Vector3, color: Color, yaw: float) -> void:
	var car := Node3D.new()
	car.position = pos
	car.rotation_degrees.y = yaw
	parent.add_child(car)
	StylizedMesh.add_box(car, Vector3(1.8, 0.55, 3.4), color, Vector3(0, 0.45, 0), "Body", true)
	StylizedMesh.add_box(car, Vector3(1.5, 0.45, 1.6), color.lightened(0.08), Vector3(0, 0.9, -0.2), "Cabin")
	for wp in [Vector3(-0.85, 0.28, 1.0), Vector3(0.85, 0.28, 1.0), Vector3(-0.85, 0.28, -1.0), Vector3(0.85, 0.28, -1.0)]:
		StylizedMesh.add_box(car, Vector3(0.22, 0.42, 0.42), Color(0.12, 0.12, 0.12), wp, "Wheel")
