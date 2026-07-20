class_name RiskyReelsBuilder
extends RefCounted
## Risky Reels — OG Athena drive-in theater (original art, not franchise IP).
## Structure: giant screen, dense car rows, ticket booth, snack stand, projection booth, fence.


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "RiskyReels"
	hub.position = origin
	root.add_child(hub)

	## Sandy / dirt theater grounds (OG drive-in feel).
	StylizedMesh.add_box(hub, Vector3(130, 0.26, 120), WorldPalette.SAND.darkened(0.08), Vector3(0, -0.12, 0), "Ground", true, 1.0, &"dirt")
	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, 48), "RISKY REELS", &"risky_reels_welcome")

	## Perimeter fence — rectangular lot.
	_fence_ring(hub, 55.0, 48.0)

	## Parking field facing north toward the screen (-Z).
	StylizedMesh.add_box(hub, Vector3(70, 0.08, 55), WorldPalette.DIRT.darkened(0.05), Vector3(0, 0.04, 8), "Lot", true, 1.0, &"dirt")

	## Dense car rows (signature Risky Reels silhouette).
	var car_colors := [
		Color(0.75, 0.2, 0.18), Color(0.2, 0.35, 0.7), Color(0.85, 0.85, 0.8),
		Color(0.2, 0.55, 0.35), Color(0.15, 0.15, 0.18), Color(0.9, 0.7, 0.2),
		Color(0.55, 0.25, 0.55), Color(0.3, 0.55, 0.75),
	]
	for row in 5:
		for col in 8:
			var pos := Vector3(-28.0 + float(col) * 8.0, 0.0, 28.0 - float(row) * 8.5)
			var yaw := 180.0 + float((row + col) % 3) * 4.0 - 4.0 ## mostly facing screen (-Z)
			_parked_car(hub, pos, car_colors[(row * 8 + col) % car_colors.size()], yaw)

	## Giant outdoor screen at north end, facing south into the lot.
	var screen := Node3D.new()
	screen.name = "DriveInScreen"
	screen.position = Vector3(0, 0, -32)
	hub.add_child(screen)
	StylizedMesh.add_box(screen, Vector3(2.2, 16.0, 1.8), WorldPalette.METAL, Vector3(-20, 8.0, 0), "PostL", true)
	StylizedMesh.add_box(screen, Vector3(2.2, 16.0, 1.8), WorldPalette.METAL, Vector3(20, 8.0, 0), "PostR", true)
	StylizedMesh.add_box(screen, Vector3(44, 20, 1.4), WorldPalette.UI_INK, Vector3(0, 11.0, 0), "ScreenFrame", true)
	StylizedMesh.add_box(screen, Vector3(40, 17, 0.45), Color(0.58, 0.74, 0.88), Vector3(0, 11.0, 0.55), "Screen")
	StylizedMesh.add_box(screen, Vector3(10, 0.7, 0.35), WorldPalette.UI_ACCENT, Vector3(0, 3.4, 0.7), "Marquee")
	var label := Label3D.new()
	label.text = "NOW SHOWING"
	label.font_size = 110
	label.position = Vector3(0, 11.0, 1.0)
	label.modulate = WorldPalette.UI_PAPER
	screen.add_child(label)
	## Scaffolding / walkway behind screen (OG loft loot).
	StylizedMesh.add_box(screen, Vector3(36, 0.25, 3.5), WorldPalette.METAL, Vector3(0, 8.0, -1.5), "Catwalk", true)
	RegionPropKit.add_discoverable(screen, &"drive_in_screen", "Drive-In Screen", Vector3(0, 1.0, 5), 18, "A silver cliff for stories — cars lined up for the show.")

	## Ticket booth at south entrance.
	RegionPropKit.make_enterable_building(hub, "TicketBooth", Vector3(-8, 0, 42), Color(0.55, 0.2, 0.18), WorldPalette.ROOF, 180.0, result, InteriorKinds.BOOTH, Vector3(4.2, 2.6, 3.0))
	## Snack / food stand east side.
	RegionPropKit.make_enterable_building(hub, "SnackShack", Vector3(28, 0, 10), Color(0.86, 0.55, 0.2), WorldPalette.ROOF_RED, -90.0, result, InteriorKinds.RESTAURANT, Vector3(6.5, 2.8, 4.5))
	RegionPropKit.add_discoverable(hub, &"snack_shack", "Snack Shack", Vector3(28, 0.5, 14), 12, "Popcorn ghosts and sticky counters.")

	## Projection booth west of screen.
	RegionPropKit.make_enterable_building(
		hub, "ProjectionBooth", Vector3(-28, 0, -18), Color(0.35, 0.36, 0.4), WorldPalette.ROOF, 90.0, result, InteriorKinds.BOOTH, Vector3(5.0, 2.8, 4.2)
	)

	## Speaker poles between car rows.
	for i in 6:
		var x := -24.0 + float(i) * 10.0
		StylizedMesh.add_box(hub, Vector3(0.15, 1.5, 0.15), WorldPalette.METAL, Vector3(x, 0.75, 12), "SpeakerPole", true)
		StylizedMesh.add_box(hub, Vector3(0.45, 0.32, 0.28), WorldPalette.UI_INK, Vector3(x, 1.45, 12), "Speaker")

	## Picnic tables + playground / toilets cluster (OG amenities).
	StylizedMesh.add_box(hub, Vector3(2.4, 0.12, 1.1), WorldPalette.WOOD, Vector3(-30, 0.55, 20), "Picnic", false, 1.0, &"wood")
	StylizedMesh.add_box(hub, Vector3(2.2, 0.1, 0.45), WorldPalette.WOOD, Vector3(-30, 0.35, 19), "Bench", false, 1.0, &"wood")
	StylizedMesh.add_box(hub, Vector3(3.5, 2.4, 2.8), WorldPalette.METAL, Vector3(32, 1.2, 28), "Restrooms", true)
	StylizedMesh.add_box(hub, Vector3(2.5, 0.15, 2.5), WorldPalette.SAND, Vector3(22, 0.08, 30), "PlaySand", false, 1.0, &"dirt")
	StylizedMesh.add_box(hub, Vector3(0.15, 1.4, 0.15), WorldPalette.UI_ACCENT, Vector3(21.2, 0.8, 30), "SwingPost", true)
	StylizedMesh.add_box(hub, Vector3(0.15, 1.4, 0.15), WorldPalette.UI_ACCENT, Vector3(22.8, 0.8, 30), "SwingPost2", true)

	## Film reels / prop clutter near booth.
	StylizedMesh.add_box(hub, Vector3(1.0, 0.25, 1.0), WorldPalette.METAL, Vector3(-24, 0.3, -12), "ReelA")
	StylizedMesh.add_box(hub, Vector3(0.85, 0.25, 0.85), WorldPalette.METAL.darkened(0.1), Vector3(-22.8, 0.3, -11.2), "ReelB")
	## Electrical shack behind screen.
	RegionPropKit.make_enterable_building(hub, "ElecShack", Vector3(0, 0, -42), Color(0.42, 0.4, 0.38), WorldPalette.ROOF, 0.0, result, InteriorKinds.WAREHOUSE, Vector3(4.2, 2.4, 3.2))

	## Entrance marquee arch.
	StylizedMesh.add_box(hub, Vector3(0.4, 5.0, 0.4), WorldPalette.METAL, Vector3(-6, 2.5, 46), "ArchL", true)
	StylizedMesh.add_box(hub, Vector3(0.4, 5.0, 0.4), WorldPalette.METAL, Vector3(6, 2.5, 46), "ArchR", true)
	StylizedMesh.add_box(hub, Vector3(13, 1.2, 0.35), WorldPalette.UI_INK, Vector3(0, 5.2, 46), "ArchSign")
	var mlabel := Label3D.new()
	mlabel.text = "RISKY REELS"
	mlabel.font_size = 64
	mlabel.position = Vector3(0, 5.2, 46.3)
	mlabel.modulate = WorldPalette.UI_ACCENT
	hub.add_child(mlabel)

	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "ProjectionChest", Vector3(-28, 0, -22), ChestInteractable.Rarity.RARE, 0.0, "Search the projection booth")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "SnackShackChest", Vector3(30, 0, 8), ChestInteractable.Rarity.NORMAL, 24.0, "Rummage the snack shack")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "ScreenScaffoldChest", Vector3(0, 0, -34), ChestInteractable.Rarity.LEGENDARY, 0.0, "Climb the screen scaffold")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "TicketBoothChest", Vector3(-8, 0, 40), ChestInteractable.Rarity.RARE, 18.0, "Check the ticket booth")
	)

	RegionPropKit.add_discoverable(hub, &"risky_reels", "Risky Reels", Vector3(0, 0.5, 40), 24, "Lights, lot, and a hundred cars waiting for the feature.")


static func _fence_ring(parent: Node3D, half_w: float, half_d: float) -> void:
	StylizedMesh.add_box(parent, Vector3(half_w * 2.0, 1.2, 0.15), WorldPalette.METAL, Vector3(0, 0.6, -half_d), "FenceN", true)
	StylizedMesh.add_box(parent, Vector3(half_w * 2.0, 1.2, 0.15), WorldPalette.METAL, Vector3(0, 0.6, half_d), "FenceS", true)
	StylizedMesh.add_box(parent, Vector3(0.15, 1.2, half_d * 2.0), WorldPalette.METAL, Vector3(-half_w, 0.6, 0), "FenceW", true)
	StylizedMesh.add_box(parent, Vector3(0.15, 1.2, half_d * 2.0), WorldPalette.METAL, Vector3(half_w, 0.6, 0), "FenceE", true)
	## Gate gap on south — leave visual opening with posts only.
	StylizedMesh.add_box(parent, Vector3(0.25, 2.0, 0.25), WorldPalette.METAL, Vector3(-8, 1.0, half_d), "GateL", true)
	StylizedMesh.add_box(parent, Vector3(0.25, 2.0, 0.25), WorldPalette.METAL, Vector3(8, 1.0, half_d), "GateR", true)


static func _parked_car(parent: Node3D, pos: Vector3, color: Color, yaw: float) -> void:
	var car := Node3D.new()
	car.position = pos
	car.rotation_degrees.y = yaw
	parent.add_child(car)
	StylizedMesh.add_box(car, Vector3(1.8, 0.55, 3.4), color, Vector3(0, 0.45, 0), "Body", true)
	StylizedMesh.add_box(car, Vector3(1.5, 0.45, 1.6), color.lightened(0.08), Vector3(0, 0.9, -0.2), "Cabin")
	for wp in [Vector3(-0.85, 0.28, 1.0), Vector3(0.85, 0.28, 1.0), Vector3(-0.85, 0.28, -1.0), Vector3(0.85, 0.28, -1.0)]:
		StylizedMesh.add_box(car, Vector3(0.22, 0.42, 0.42), Color(0.12, 0.12, 0.12), wp, "Wheel")
