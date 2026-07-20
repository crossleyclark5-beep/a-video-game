class_name MarketMileBuilder
extends RefCounted
## Market Mile — Digital Frontier retail strip hub.
## Inspired by classic “one long shopping street” Named Location roles (original art).


static func build_at(root: Node3D, origin: Vector3, result: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "MarketMile"
	hub.position = origin
	root.add_child(hub)

	StylizedMesh.add_box(hub, Vector3(90, 0.26, 130), WorldPalette.SIDEWALK.darkened(0.05), Vector3(0, -0.1, 0), "Pad", true, 1.0, &"asphalt")
	## Main N–S mile road.
	StylizedMesh.add_box(hub, Vector3(8.0, 0.08, 110), WorldPalette.ROAD, Vector3(0, 0.05, 0), "MileRoad", true, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(0.25, 0.03, 90), WorldPalette.ROAD_LINE, Vector3(0, 0.1, 0), "CenterLine")
	## Sidewalks.
	StylizedMesh.add_box(hub, Vector3(4.5, 0.06, 100), WorldPalette.SIDEWALK, Vector3(-8.5, 0.06, 0), "WalkW", false, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(4.5, 0.06, 100), WorldPalette.SIDEWALK, Vector3(8.5, 0.06, 0), "WalkE", false, 1.0, &"asphalt")

	RegionPropKit.add_welcome_sign(hub, Vector3(0, 0, 52), "MARKET MILE", &"market_mile_welcome")
	_mile_arch(hub, Vector3(0, 0, -48))

	## West shops (facing road).
	RegionPropKit.make_enterable_building(hub, "ToyEmporium", Vector3(-14, 0, -28), Color(0.92, 0.45, 0.35), Color(0.95, 0.85, 0.3), 90.0, result, InteriorKinds.SHOP, Vector3(9.0, 3.6, 7.0))
	RegionPropKit.make_enterable_building(hub, "BitGrocer", Vector3(-14, 0, -8), Color(0.35, 0.65, 0.4), Color(0.9, 0.9, 0.85), 90.0, result, InteriorKinds.SHOP, Vector3(9.0, 3.6, 7.0))
	RegionPropKit.make_enterable_building(hub, "PixelDiner", Vector3(-14, 0, 12), Color(0.85, 0.55, 0.25), Color(0.95, 0.75, 0.4), 90.0, result, InteriorKinds.RESTAURANT, Vector3(9.0, 3.6, 7.0))
	## East shops.
	RegionPropKit.make_enterable_building(hub, "ClothLoop", Vector3(14, 0, -28), Color(0.45, 0.4, 0.7), Color(0.8, 0.75, 0.95), -90.0, result, InteriorKinds.SHOP, Vector3(9.0, 3.6, 7.0))
	RegionPropKit.make_enterable_building(hub, "HexHardware", Vector3(14, 0, -8), Color(0.55, 0.5, 0.45), Color(0.75, 0.7, 0.55), -90.0, result, InteriorKinds.SHOP, Vector3(9.0, 3.6, 7.0))
	## Playable shop counter at Bit Grocer doorway.
	_add_shop_counter(hub, Vector3(-9.5, 0.0, -4.0))
	## Anchor department store (enterable).
	_anchor_store(hub, result)

	## Parking bays + cars.
	for i in 5:
		var z := -30.0 + float(i) * 12.0
		StylizedMesh.add_box(hub, Vector3(3.2, 0.04, 5.5), WorldPalette.ROAD.lightened(0.08), Vector3(-20, 0.04, z), "BayW", false, 1.0, &"asphalt")
		StylizedMesh.add_box(hub, Vector3(3.2, 0.04, 5.5), WorldPalette.ROAD.lightened(0.08), Vector3(20, 0.04, z), "BayE", false, 1.0, &"asphalt")
	_car(hub, Vector3(-20, 0, -18), Color(0.2, 0.45, 0.75), 90.0)
	_car(hub, Vector3(20, 0, 6), Color(0.75, 0.25, 0.22), -90.0)
	_car(hub, Vector3(-20, 0, 20), Color(0.35, 0.35, 0.38), 90.0)

	## Loading alley / secret.
	StylizedMesh.add_box(hub, Vector3(3.0, 0.05, 40), WorldPalette.ROAD.darkened(0.1), Vector3(-24, 0.05, 0), "Alley", false, 1.0, &"asphalt")
	StylizedMesh.add_box(hub, Vector3(2.2, 1.4, 1.6), WorldPalette.METAL, Vector3(-24, 0.7, 8), "Dumpster", true)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "MileAlleyChest", Vector3(-24, 0.2, -10), ChestInteractable.Rarity.RARE, 0.0, "Poke behind the dumpster")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "MileDinerChest", Vector3(-14, 0.2, 14), ChestInteractable.Rarity.NORMAL, 24.0, "Tip jar? Or stash.")
	)
	result[&"chests"].append(
		RegionPropKit.build_chest(hub, "MileRoofChest", Vector3(16, 0.2, 28), ChestInteractable.Rarity.LEGENDARY, 0.0, "Climb the anchor roof ledge")
	)

	## Carts / props.
	for i in 4:
		StylizedMesh.add_box(hub, Vector3(0.7, 0.55, 0.9), WorldPalette.METAL.lightened(0.1), Vector3(-7.5, 0.35, -20 + float(i) * 10), "Cart", false, 1.0, &"brick")

	RegionPropKit.add_discoverable(hub, &"market_mile", "Market Mile", Vector3(0, 0.5, 46), 22, "One long street of shops — if you need it, the Mile probably sells it.")
	RegionPropKit.add_discoverable(hub, &"mile_anchor", "Anchor Department", Vector3(14, 0.6, 28), 14, "The big store at the end of the Mile. Escalators optional (none found).")


static func _mile_arch(parent: Node3D, pos: Vector3) -> void:
	var arch := Node3D.new()
	arch.name = "MileArch"
	arch.position = pos
	parent.add_child(arch)
	StylizedMesh.add_box(arch, Vector3(0.4, 5.5, 0.4), WorldPalette.METAL, Vector3(-6, 2.75, 0), "PostL", true)
	StylizedMesh.add_box(arch, Vector3(0.4, 5.5, 0.4), WorldPalette.METAL, Vector3(6, 2.75, 0), "PostR", true)
	StylizedMesh.add_box(arch, Vector3(13, 1.4, 0.5), WorldPalette.UI_ACCENT, Vector3(0, 5.5, 0), "SignBoard")
	var label := Label3D.new()
	label.text = "MILE"
	label.font_size = 96
	label.position = Vector3(0, 5.5, 0.3)
	label.modulate = WorldPalette.UI_PAPER
	arch.add_child(label)


static func _shop(parent: Node3D, shop_name: String, pos: Vector3, wall: Color, sign_text: String, awning: Color) -> void:
	var s := Node3D.new()
	s.name = shop_name
	s.position = pos
	parent.add_child(s)
	var face_sign := 1.0 if pos.x < 0.0 else -1.0
	StylizedMesh.add_box(s, Vector3(10, 4.2, 8), wall, Vector3(0, 2.1, 0), "Body", true, 1.0, &"brick")
	StylizedMesh.add_box(s, Vector3(10.6, 0.45, 8.6), wall.darkened(0.15), Vector3(0, 4.4, 0), "Roof", false, 1.0, &"roof")
	StylizedMesh.add_box(s, Vector3(9.5, 0.25, 1.4), awning, Vector3(face_sign * 0.2, 3.2, 4.2 * face_sign), "Awning")
	StylizedMesh.add_box(s, Vector3(2.0, 2.4, 0.12), WorldPalette.WOOD.darkened(0.2), Vector3(0, 1.3, 4.05 * face_sign), "Door", false, 1.0, &"wood")
	StylizedMesh.add_window_pane(s, Vector3(2.4, 1.8, 0.1), Vector3(-2.8, 2.0, 4.05 * face_sign), "WinL")
	StylizedMesh.add_window_pane(s, Vector3(2.4, 1.8, 0.1), Vector3(2.8, 2.0, 4.05 * face_sign), "WinR")
	var label := Label3D.new()
	label.text = sign_text
	label.font_size = 48
	label.position = Vector3(0, 3.7, 4.3 * face_sign)
	label.modulate = WorldPalette.UI_INK
	s.add_child(label)


static func _add_shop_counter(parent: Node3D, pos: Vector3) -> void:
	var counter := ShopInteractable.new()
	counter.name = "MileShopCounter"
	counter.position = pos
	counter.shop_id = ShopManager.SHOP_ID_MILE
	counter.shopkeeper_name = "Bit Grocer"
	counter.prompt_verb = "Browse shop"
	parent.add_child(counter)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 2.4)
	shape.shape = box
	shape.position = Vector3(0, 1.0, 0)
	counter.add_child(shape)
	StylizedMesh.add_box(counter, Vector3(1.6, 1.0, 0.9), WorldPalette.WOOD, Vector3(0, 0.55, 0), "Counter", true, 1.0, &"wood")
	StylizedMesh.add_box(counter, Vector3(0.7, 0.35, 0.5), WorldPalette.UI_ACCENT, Vector3(0, 1.2, 0), "Till")
	var tag := Label3D.new()
	tag.text = "OPEN"
	tag.font_size = 48
	tag.position = Vector3(0, 1.8, 0.6)
	tag.modulate = WorldPalette.UI_PAPER
	counter.add_child(tag)


static func _anchor_store(parent: Node3D, result: Dictionary) -> void:
	## Big end-of-mile store — enterable shell.
	var store := RegionPropKit.make_enterable_building(
		parent, "AnchorDepartment", Vector3(14, 0, 28), Color(0.72, 0.28, 0.32), WorldPalette.ROOF, -90.0, result, InteriorKinds.SHOP, Vector3(10.0, 4.0, 8.0)
	)
	## Extra wing / loading dock flavor on the enterable shell.
	StylizedMesh.add_box(store, Vector3(4.5, 3.5, 6.0), Color(0.65, 0.25, 0.28), Vector3(4.5, 1.75, 0), "Wing", true, 1.0, &"brick")
	StylizedMesh.add_box(store, Vector3(5.0, 0.4, 6.5), WorldPalette.ROOF.darkened(0.1), Vector3(4.5, 3.7, 0), "WingRoof", false, 1.0, &"roof")
	StylizedMesh.add_box(store, Vector3(3.2, 2.2, 0.15), WorldPalette.METAL, Vector3(4.5, 1.2, 3.1), "LoadingDoor")
	var label := Label3D.new()
	label.text = "ANCHOR"
	label.font_size = 56
	label.position = Vector3(0, 3.6, 2.6)
	label.modulate = WorldPalette.UI_PAPER
	store.add_child(label)


static func _car(parent: Node3D, pos: Vector3, color: Color, yaw: float) -> void:
	var car := Node3D.new()
	car.position = pos
	car.rotation_degrees.y = yaw
	parent.add_child(car)
	StylizedMesh.add_box(car, Vector3(1.8, 0.55, 3.4), color, Vector3(0, 0.4, 0), "Body", true)
	StylizedMesh.add_box(car, Vector3(1.5, 0.45, 1.6), color.lightened(0.08), Vector3(0, 0.9, -0.2), "Cabin")
