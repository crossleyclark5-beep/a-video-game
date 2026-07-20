class_name GreaseGroveBuilder
extends RefCounted
## Grease Grove — Digital Frontier fast-food suburb hub.
## Inspired by classic “greasy spoon plaza + houses” Named Location roles (original art).


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "GreaseGrove"
	hub.position = origin
	root.add_child(hub)

	StylizedMesh.add_box(hub, Vector3(110, 0.26, 100), WorldPalette.GRASS, Vector3(0, -0.1, 0), "Ground", true, 1.0, &"grass")
	## Plaza asphalt.
	StylizedMesh.add_box(hub, Vector3(42, 0.08, 36), WorldPalette.ROAD, Vector3(8, 0.05, 4), "Plaza", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(5.0, 0.07, 50), WorldPalette.ROAD, Vector3(0, 0.05, 0), "Approach", true, 1.0, &"asphalt")

	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, 38), "GREASE GROVE", &"grease_grove_welcome")

	## GigaBite drive-thru plaza (original brand).
	_gigabite(hub, result)
	_burger_statue(hub, Vector3(22, 0, -8))
	_playground(hub, Vector3(-18, 0, 12))

	## Suburban bungalows west of plaza.
	RegionPropKit.make_enterable_house(
		hub, "GroveBungalow", Vector3(-32, 0, -10), Color(0.88, 0.72, 0.55), WorldPalette.ROOF_RED, 90.0, result
	)
	_bungalow(hub, "YellowBungalow", Vector3(-34, 0, 12), Color(0.92, 0.85, 0.45), WorldPalette.ROOF, 90.0)
	_bungalow(hub, "TealBungalow", Vector3(-28, 0, -28), Color(0.45, 0.7, 0.72), WorldPalette.ROOF, 0.0)

	## Parking cars.
	_car(hub, Vector3(4, 0, 16), Color(0.85, 0.3, 0.25), 10.0)
	_car(hub, Vector3(14, 0, 18), Color(0.25, 0.35, 0.55), -5.0)
	_car(hub, Vector3(-6, 0, -20), Color(0.4, 0.55, 0.35), 40.0)

	## Picnic tables.
	for i in 3:
		StylizedMesh.add_box(hub, Vector3(2.2, 0.12, 1.0), WorldPalette.WOOD, Vector3(-8 + float(i) * 4, 0.55, 22), "Picnic", false, 1.0, &"wood")
		StylizedMesh.add_box(hub, Vector3(2.0, 0.45, 0.12), WorldPalette.WOOD, Vector3(-8 + float(i) * 4, 0.85, 21.4), "Bench", false, 1.0, &"wood")

	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "GrovePlaygroundChest", Vector3(-18, 0.2, 14), ChestInteractable.Rarity.NORMAL, 24.0, "Dig under the slide")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "GroveKitchenChest", Vector3(10, 0.2, 2), ChestInteractable.Rarity.RARE, 0.0, "Raid the GigaBite kitchen")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "GroveAtticChest", Vector3(-32, 0.2, -12), ChestInteractable.Rarity.RARE, 18.0, "Check the bungalow attic")
	)

	RegionPropKit.add_discoverable(hub, &"grease_grove", "Grease Grove", Vector3(0, 0.5, 32), 22, "GigaBite neon, warm asphalt, and the smell of imaginary fries.")
	RegionPropKit.add_discoverable(hub, &"gigabite", "GigaBite Plaza", Vector3(8, 0.6, 6), 14, "Drive-thru open 24 bits a day. Mascot never blinks.")


static func _gigabite(parent: Node3D, result: Dictionary) -> void:
	var g := Node3D.new()
	g.name = "GigaBite"
	g.position = Vector3(8, 0, 0)
	parent.add_child(g)
	## Restaurant building (enterable).
	RegionPropKit.make_enterable_house(
		g, "GigaBiteDining", Vector3(0, 0, 0), Color(0.9, 0.55, 0.2), WorldPalette.ROOF_RED, 0.0, result
	)
	## Drive-thru canopy wing.
	StylizedMesh.add_box(g, Vector3(10, 0.25, 5.5), WorldPalette.ROOF_RED, Vector3(8, 3.2, -2), "Canopy")
	StylizedMesh.add_box(g, Vector3(0.3, 3.0, 0.3), WorldPalette.METAL, Vector3(4, 1.5, -3.5), "Post1", true)
	StylizedMesh.add_box(g, Vector3(0.3, 3.0, 0.3), WorldPalette.METAL, Vector3(11, 1.5, -3.5), "Post2", true)
	StylizedMesh.add_box(g, Vector3(1.2, 1.6, 0.8), WorldPalette.UI_INK, Vector3(10, 1.0, -4.2), "MenuBoard", true)
	StylizedMesh.add_box(g, Vector3(0.9, 1.2, 0.08), WorldPalette.UI_PAPER, Vector3(10, 1.05, -3.75), "Menu")
	var label := Label3D.new()
	label.text = "GigaBite"
	label.font_size = 64
	label.position = Vector3(0, 4.0, 2.6)
	label.modulate = WorldPalette.UI_PAPER
	g.add_child(label)
	## Neon strip.
	var neon := StylizedMesh.add_box(g, Vector3(6.5, 0.2, 0.15), WorldPalette.UI_ACCENT, Vector3(0, 3.6, 2.5), "Neon")
	if neon is MeshInstance3D:
		(neon as MeshInstance3D).material_override = StylizedMesh.make_material(WorldPalette.UI_ACCENT, 1.0, 0.0, 0.45)


static func _burger_statue(parent: Node3D, pos: Vector3) -> void:
	var s := Node3D.new()
	s.name = "BurgerStatue"
	s.position = pos
	parent.add_child(s)
	StylizedMesh.add_box(s, Vector3(2.4, 0.35, 2.4), Color(0.85, 0.65, 0.3), Vector3(0, 1.4, 0), "BunBot")
	StylizedMesh.add_box(s, Vector3(2.2, 0.35, 2.2), Color(0.45, 0.25, 0.12), Vector3(0, 1.75, 0), "Patty")
	StylizedMesh.add_box(s, Vector3(2.15, 0.2, 2.15), Color(0.35, 0.7, 0.3), Vector3(0, 2.0, 0), "Lettuce")
	StylizedMesh.add_box(s, Vector3(2.4, 0.4, 2.4), Color(0.9, 0.7, 0.35), Vector3(0, 2.35, 0), "BunTop")
	StylizedMesh.add_box(s, Vector3(0.15, 0.15, 0.15), WorldPalette.FLOWER_Y, Vector3(0.5, 2.6, 0.4), "Seed")
	StylizedMesh.add_box(s, Vector3(0.15, 0.15, 0.15), WorldPalette.FLOWER_Y, Vector3(-0.4, 2.6, -0.3), "Seed2")
	StylizedMesh.add_box(s, Vector3(1.8, 1.2, 1.8), WorldPalette.METAL, Vector3(0, 0.5, 0), "Pedestal", true)


static func _playground(parent: Node3D, pos: Vector3) -> void:
	var p := Node3D.new()
	p.name = "Playground"
	p.position = pos
	parent.add_child(p)
	StylizedMesh.add_box(p, Vector3(12, 0.08, 10), WorldPalette.SAND, Vector3(0, 0.05, 0), "Sand", false, 1.0, &"dirt")
	StylizedMesh.add_box(p, Vector3(1.2, 2.2, 1.2), WorldPalette.UI_ACCENT, Vector3(-2, 1.1, 0), "Tower", true)
	StylizedMesh.add_box(p, Vector3(3.5, 0.2, 1.0), Color(0.35, 0.55, 0.9), Vector3(1.2, 1.4, 0), "Slide", false, 1.0, &"wood")
	## Tilted slide feel via ramp-ish second box.
	StylizedMesh.add_box(p, Vector3(2.8, 0.15, 0.9), Color(0.35, 0.55, 0.9), Vector3(2.5, 0.7, 0), "SlideLow")
	StylizedMesh.add_box(p, Vector3(0.15, 1.6, 2.4), WorldPalette.METAL, Vector3(4, 0.8, 0), "SwingFrame", true)
	StylizedMesh.add_box(p, Vector3(0.5, 0.12, 0.3), WorldPalette.WOOD, Vector3(4, 0.5, 0), "Seat", false, 1.0, &"wood")


static func _bungalow(parent: Node3D, house_name: String, pos: Vector3, wall: Color, roof: Color, yaw: float) -> void:
	var h := Node3D.new()
	h.name = house_name
	h.position = pos
	h.rotation_degrees.y = yaw
	parent.add_child(h)
	StylizedMesh.add_box(h, Vector3(6.0, 2.5, 5.0), wall, Vector3(0, 1.25, 0), "Body", true, 1.0, &"wood")
	StylizedMesh.add_box(h, Vector3(6.8, 0.4, 5.8), roof, Vector3(0, 2.75, 0), "Roof", false, 1.0, &"roof")
	StylizedMesh.add_box(h, Vector3(1.1, 1.9, 0.1), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.05, 2.55), "Door", false, 1.0, &"wood")
	StylizedMesh.add_window_pane(h, Vector3(1.0, 0.85, 0.08), Vector3(-1.6, 1.6, 2.55), "Win")
	StylizedMesh.add_box(h, Vector3(0.7, 0.5, 0.7), WorldPalette.BUSH, Vector3(-2.8, 0.3, 2.2), "Bush", false, 1.0, &"leaf")


static func _car(parent: Node3D, pos: Vector3, color: Color, yaw: float) -> void:
	var car := Node3D.new()
	car.position = pos
	car.rotation_degrees.y = yaw
	parent.add_child(car)
	StylizedMesh.add_box(car, Vector3(1.8, 0.55, 3.4), color, Vector3(0, 0.4, 0), "Body", true)
	StylizedMesh.add_box(car, Vector3(1.5, 0.45, 1.6), color.lightened(0.08), Vector3(0, 0.9, -0.2), "Cabin")
