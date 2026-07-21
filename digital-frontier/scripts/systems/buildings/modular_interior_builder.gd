class_name ModularInteriorBuilder
extends RefCounted
## Builds themed, furnished interiors at runtime — reusable for any building type.
## Handcrafted PackedScenes still override via BuildingVolume.interior_scene.


const FLOOR_RISE := 3.2
const ROOM := Vector3(7.0, 0.12, 6.0)


static func build(kind: StringName, building_id: StringName, seed_extra: int = 0, personality: int = -1) -> Node3D:
	var root := Node3D.new()
	root.name = "ModularInterior_%s" % String(kind)
	var stories := InteriorKinds.stories_for(kind)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(building_id)) * 7919 + seed_extra * 97 + hash(String(kind))
	if personality < 0:
		personality = InteriorPersonality.from_building_id(building_id, kind)
	var floors: Array[BuildingFloor] = []
	for i in stories:
		var fl := _make_floor(i, InteriorKinds.floor_name(kind, i))
		fl.position = Vector3(0, float(i) * FLOOR_RISE, 0)
		root.add_child(fl)
		floors.append(fl)
		_shell_walls(fl, kind, i == stories - 1, personality)
		_furnish_floor(fl, kind, i, rng, building_id, personality)
		if i > 0:
			_link_stairs(floors[i - 1], fl, i - 1, i)
	## Always leave at least one curiosity reward on the top story.
	if not floors.is_empty():
		_ensure_secret(floors[floors.size() - 1], building_id, kind, rng)
	return root


static func _make_floor(index: int, fname: String) -> BuildingFloor:
	var fl := BuildingFloor.new()
	fl.name = "Floor_%d" % index
	fl.floor_index = index
	fl.floor_name = fname
	fl.floor_height = FLOOR_RISE
	var spawn := Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 0.15, 1.4 if index == 0 else 0.0)
	fl.add_child(spawn)
	fl.spawn_marker = spawn
	return fl


static func _shell_walls(fl: BuildingFloor, kind: StringName, is_top: bool, personality: int = InteriorPersonality.Style.MODEST) -> void:
	var wall_c := InteriorPersonality.wall_tint(personality, _wall_color(kind))
	var floor_c := InteriorPersonality.floor_tint(personality, _floor_color(kind))
	StylizedMesh.add_box(fl, ROOM, floor_c, Vector3(0, 0.06, 0), "Floor", true, 1.0, &"wood")
	var wall_h := 1.7 if is_top and kind != InteriorKinds.TOWER else 2.8
	StylizedMesh.add_box(fl, Vector3(ROOM.x, wall_h, 0.2), wall_c, Vector3(0, wall_h * 0.5, -ROOM.z * 0.5), "WallBack", true)
	StylizedMesh.add_box(fl, Vector3(0.2, wall_h, ROOM.z), wall_c, Vector3(-ROOM.x * 0.5, wall_h * 0.5, 0), "WallL", true)
	StylizedMesh.add_box(fl, Vector3(0.2, wall_h, ROOM.z), wall_c, Vector3(ROOM.x * 0.5, wall_h * 0.5, 0), "WallR", true)
	## Front doorway gap — keep center clear for walking.
	StylizedMesh.add_box(fl, Vector3(2.4, wall_h, 0.2), wall_c, Vector3(-2.2, wall_h * 0.5, ROOM.z * 0.5), "WallF1", true)
	StylizedMesh.add_box(fl, Vector3(2.4, wall_h, 0.2), wall_c, Vector3(2.2, wall_h * 0.5, ROOM.z * 0.5), "WallF2", true)


static func _furnish_floor(
	fl: BuildingFloor,
	kind: StringName,
	index: int,
	rng: RandomNumberGenerator,
	building_id: StringName,
	personality: int = InteriorPersonality.Style.MODEST,
) -> void:
	match kind:
		InteriorKinds.SHOP:
			_furnish_shop(fl, index, rng)
		InteriorKinds.RESTAURANT:
			_furnish_restaurant(fl, index, rng)
		InteriorKinds.OFFICE:
			_furnish_office(fl, index, rng)
		InteriorKinds.WAREHOUSE, InteriorKinds.BARN:
			_furnish_warehouse(fl, kind, rng)
		InteriorKinds.BOOTH:
			_furnish_booth(fl, rng)
		InteriorKinds.APARTMENT, InteriorKinds.TOWER:
			_furnish_apartment(fl, index, rng, personality)
		InteriorKinds.LANDMARK:
			_furnish_landmark(fl, index, rng)
		InteriorKinds.CABIN, InteriorKinds.FARMHOUSE:
			_furnish_house(fl, index, rng, personality)
		_:
			_furnish_house(fl, index, rng, personality)
	## Chest against a wall — never mid-path near door (z > 0 toward door).
	if index == 0 and rng.randf() < 0.55:
		_add_chest(fl, Vector3(rng.randf_range(-2.6, -2.0), 0.4, rng.randf_range(-2.4, -1.8)), building_id, index, ChestInteractable.Rarity.NORMAL)


static func _furnish_house(fl: BuildingFloor, index: int, rng: RandomNumberGenerator, personality: int) -> void:
	## One open floor, zoned like a real home. Door at +Z — keep a clear walk lane down the center.
	if index == 0:
		_furnish_living_zone(fl, personality, rng)
		_furnish_kitchen_zone(fl, personality, rng)
		_furnish_dining_zone(fl, personality, rng)
		## Entry mat near door — not furniture blocking the doorway.
		StylizedMesh.add_box(fl, Vector3(1.2, 0.03, 0.7), Color(0.45, 0.35, 0.28), Vector3(0, 0.13, 2.2), "EntryMat")
	else:
		_furnish_bedroom_zone(fl, personality, rng)
		_furnish_bath_zone(fl, personality, rng)


static func _furnish_living_zone(fl: BuildingFloor, personality: int, rng: RandomNumberGenerator) -> void:
	## Left / back — couch faces the room, coffee table, TV on back wall.
	var couch_c := Color(0.45, 0.22, 0.2)
	match personality:
		InteriorPersonality.Style.WEALTHY:
			couch_c = Color(0.35, 0.28, 0.42)
		InteriorPersonality.Style.MODERN:
			couch_c = Color(0.55, 0.55, 0.58)
		InteriorPersonality.Style.RUSTIC:
			couch_c = Color(0.5, 0.32, 0.2)
		InteriorPersonality.Style.GARDEN:
			couch_c = Color(0.4, 0.5, 0.35)
		InteriorPersonality.Style.ABANDONED:
			couch_c = Color(0.4, 0.38, 0.32)
	if not _try_external(fl, &"sofa", Vector3(-1.8, 0, -1.8), 180.0, 1.05, "Couch"):
		StylizedMesh.add_box(fl, Vector3(2.2, 0.55, 0.85), couch_c, Vector3(-1.8, 0.4, -1.8), "Couch")
	StylizedMesh.add_box(fl, Vector3(0.55, 0.55, 0.55), couch_c.darkened(0.08), Vector3(-0.5, 0.4, -1.9), "Armchair")
	if not _try_external(fl, &"coffee_table", Vector3(-1.5, 0, -0.85), 0.0, 1.0, "CoffeeTable"):
		StylizedMesh.add_box(fl, Vector3(1.0, 0.28, 0.55), WorldPalette.WOOD, Vector3(-1.5, 0.28, -0.85), "CoffeeTable", false, 1.0, &"wood")
	## TV / entertainment against back wall — not kitchen appliances.
	if not _try_external(fl, &"television", Vector3(-1.6, 0, -2.55), 0.0, 1.0, "Television"):
		StylizedMesh.add_box(fl, Vector3(1.3, 0.75, 0.2), Color(0.15, 0.15, 0.18), Vector3(-1.6, 1.15, -2.75), "Television")
		StylizedMesh.add_box(fl, Vector3(1.5, 0.45, 0.4), WorldPalette.WOOD.darkened(0.1), Vector3(-1.6, 0.45, -2.55), "TVStand", false, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(1.8, 0.04, 1.2), Color(0.55, 0.2, 0.25) if personality != InteriorPersonality.Style.MODERN else Color(0.35, 0.4, 0.45), Vector3(-1.4, 0.14, -1.2), "LivingRug")
	if personality == InteriorPersonality.Style.WEALTHY or personality == InteriorPersonality.Style.MODEST:
		StylizedMesh.add_box(fl, Vector3(0.7, 0.7, 0.12), Color(0.85, 0.8, 0.7), Vector3(-2.8, 1.4, -2.5), "FamilyPhoto")
	if personality == InteriorPersonality.Style.GARDEN or rng.randf() < 0.6:
		if not _try_external(fl, &"potted_plant", Vector3(-2.7, 0, -0.6), 0.0, 1.1, "LivingPlant"):
			StylizedMesh.add_box(fl, Vector3(0.35, 0.9, 0.35), WorldPalette.BUSH, Vector3(-2.7, 0.55, -0.6), "LivingPlant")
	if personality == InteriorPersonality.Style.ABANDONED:
		StylizedMesh.add_box(fl, Vector3(0.4, 0.25, 0.5), Color(0.5, 0.45, 0.35), Vector3(-0.8, 0.25, -1.0), "FallenBook")
	if personality != InteriorPersonality.Style.ABANDONED and rng.randf() < 0.5:
		_try_external(fl, &"floor_lamp", Vector3(-2.6, 0, -1.2), 0.0, 1.0, "FloorLamp")


static func _furnish_kitchen_zone(fl: BuildingFloor, personality: int, _rng: RandomNumberGenerator) -> void:
	## Right / back — counters, fridge, stove. Never beds or couches here.
	if personality == InteriorPersonality.Style.ABANDONED:
		StylizedMesh.add_box(fl, Vector3(1.4, 0.7, 0.55), Color(0.55, 0.5, 0.42), Vector3(2.0, 0.5, -2.0), "BrokenCounter")
		StylizedMesh.add_box(fl, Vector3(0.7, 1.4, 0.6), Color(0.5, 0.5, 0.48), Vector3(2.7, 0.85, -0.8), "DustyFridge")
		return
	StylizedMesh.add_box(fl, Vector3(2.2, 0.7, 0.55), Color(0.75, 0.75, 0.78), Vector3(1.9, 0.5, -2.2), "KitchenCounter")
	StylizedMesh.add_box(fl, Vector3(2.0, 0.08, 0.5), Color(0.85, 0.85, 0.88), Vector3(1.9, 0.88, -2.2), "CounterTop")
	if not _try_external(fl, &"fridge", Vector3(2.7, 0, -0.9), 90.0, 1.0, "Refrigerator"):
		StylizedMesh.add_box(fl, Vector3(0.7, 1.5, 0.65), Color(0.7, 0.72, 0.75), Vector3(2.7, 0.9, -0.9), "Refrigerator")
	if not _try_external(fl, &"stove", Vector3(1.1, 0, -2.2), 0.0, 1.0, "Stove"):
		StylizedMesh.add_box(fl, Vector3(0.7, 0.55, 0.55), Color(0.35, 0.35, 0.38), Vector3(1.1, 0.45, -2.2), "Stove")
		StylizedMesh.add_box(fl, Vector3(0.55, 0.08, 0.45), Color(0.2, 0.2, 0.22), Vector3(1.1, 0.78, -2.2), "Burners")
	StylizedMesh.add_box(fl, Vector3(0.9, 1.2, 0.4), WorldPalette.WOOD, Vector3(2.7, 1.5, -2.3), "Cabinets", false, 1.0, &"wood")
	if personality == InteriorPersonality.Style.WEALTHY:
		StylizedMesh.add_box(fl, Vector3(0.45, 0.35, 0.45), Color(0.9, 0.9, 0.92), Vector3(2.0, 1.1, -2.15), "Mixer")
	if personality == InteriorPersonality.Style.RUSTIC:
		StylizedMesh.add_box(fl, Vector3(0.5, 0.4, 0.4), Color(0.55, 0.35, 0.2), Vector3(1.5, 1.15, -2.0), "BreadBox", false, 1.0, &"wood")


static func _furnish_dining_zone(fl: BuildingFloor, personality: int, rng: RandomNumberGenerator) -> void:
	## Center-right — table + chairs, clear of the entry lane (x≈0).
	var table_c := WorldPalette.WOOD
	if personality == InteriorPersonality.Style.MODERN:
		table_c = Color(0.55, 0.55, 0.58)
	StylizedMesh.add_box(fl, Vector3(1.3, 0.5, 0.9), table_c, Vector3(1.3, 0.4, 0.5), "DiningTable", false, 1.0, &"wood")
	if not _try_external(fl, &"chair", Vector3(0.55, 0, 0.5), 90.0, 1.0, "ChairL"):
		StylizedMesh.add_box(fl, Vector3(0.4, 0.55, 0.4), table_c.darkened(0.1), Vector3(0.55, 0.35, 0.5), "ChairL")
	if not _try_external(fl, &"chair", Vector3(2.05, 0, 0.5), -90.0, 1.0, "ChairR"):
		StylizedMesh.add_box(fl, Vector3(0.4, 0.55, 0.4), table_c.darkened(0.1), Vector3(2.05, 0.35, 0.5), "ChairR")
	if personality != InteriorPersonality.Style.ABANDONED and rng.randf() < 0.7:
		StylizedMesh.add_box(fl, Vector3(0.35, 0.12, 0.35), Color(0.9, 0.85, 0.7), Vector3(1.3, 0.72, 0.5), "PlaceSetting")
	if personality == InteriorPersonality.Style.WEALTHY:
		StylizedMesh.add_box(fl, Vector3(0.9, 1.5, 0.35), Color(0.4, 0.3, 0.45), Vector3(2.7, 0.95, 1.6), "ChinaCabinet", false, 1.0, &"wood")


static func _furnish_bedroom_zone(fl: BuildingFloor, personality: int, rng: RandomNumberGenerator) -> void:
	## Bed against back/left — nightstand, dresser, closet. No kitchen gear upstairs.
	var bed_c := Color(0.35, 0.45, 0.7)
	match personality:
		InteriorPersonality.Style.WEALTHY:
			bed_c = Color(0.45, 0.35, 0.55)
		InteriorPersonality.Style.RUSTIC:
			bed_c = Color(0.55, 0.4, 0.28)
		InteriorPersonality.Style.MODERN:
			bed_c = Color(0.5, 0.55, 0.6)
		InteriorPersonality.Style.ABANDONED:
			bed_c = Color(0.4, 0.4, 0.38)
	if not _try_external(fl, &"bed", Vector3(-1.7, 0, -0.4), 90.0, 1.0, "Bed"):
		StylizedMesh.add_box(fl, Vector3(2.0, 0.4, 1.4), bed_c, Vector3(-1.7, 0.35, -0.4), "Bed")
		StylizedMesh.add_box(fl, Vector3(1.8, 0.18, 0.5), Color(0.9, 0.9, 0.92), Vector3(-1.7, 0.65, -0.85), "Pillow")
	StylizedMesh.add_box(fl, Vector3(0.5, 0.45, 0.45), WorldPalette.WOOD, Vector3(-0.35, 0.35, -1.6), "Nightstand", false, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(0.2, 0.35, 0.2), Color(0.95, 0.9, 0.7), Vector3(-0.35, 0.75, -1.6), "Lamp")
	if not _try_external(fl, &"bookcase", Vector3(1.8, 0, -1.8), 0.0, 1.0, "Dresser"):
		StylizedMesh.add_box(fl, Vector3(1.0, 1.15, 0.45), WorldPalette.WOOD, Vector3(1.8, 0.7, -1.8), "Dresser", false, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(0.9, 1.7, 0.4), Color(0.55, 0.45, 0.35), Vector3(2.5, 1.0, 0.8), "Closet", false, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(0.7, 0.7, 0.12), Color(0.85, 0.8, 0.7), Vector3(-2.6, 1.35, -2.4), "WallArt")
	if personality == InteriorPersonality.Style.WEALTHY:
		if not _try_external(fl, &"desk", Vector3(0.8, 0, 1.5), 180.0, 0.85, "Vanity"):
			StylizedMesh.add_box(fl, Vector3(0.55, 0.9, 0.4), Color(0.6, 0.45, 0.3), Vector3(0.8, 0.55, 1.5), "Vanity", false, 1.0, &"wood")
	if personality == InteriorPersonality.Style.GARDEN:
		if not _try_external(fl, &"potted_plant", Vector3(2.5, 0, -0.5), 0.0, 1.0, "RoomPlant"):
			StylizedMesh.add_box(fl, Vector3(0.3, 0.7, 0.3), WorldPalette.BUSH, Vector3(2.5, 0.45, -0.5), "RoomPlant")
	if rng.randf() < 0.45 and personality != InteriorPersonality.Style.ABANDONED:
		StylizedMesh.add_box(fl, Vector3(0.45, 0.35, 0.55), Color(0.55, 0.4, 0.28), Vector3(-2.5, 0.3, 1.2), "ToyChest", false, 1.0, &"wood")


static func _furnish_bath_zone(fl: BuildingFloor, personality: int, _rng: RandomNumberGenerator) -> void:
	## Compact bath corner — sink, toilet, tub. Only upstairs.
	if personality == InteriorPersonality.Style.ABANDONED:
		StylizedMesh.add_box(fl, Vector3(0.7, 0.55, 0.45), Color(0.65, 0.65, 0.6), Vector3(1.2, 0.4, 2.0), "CrackedSink")
		return
	if not _try_external(fl, &"sink", Vector3(0.9, 0, 2.0), 180.0, 0.85, "Sink"):
		StylizedMesh.add_box(fl, Vector3(0.7, 0.55, 0.45), Color(0.9, 0.9, 0.92), Vector3(0.9, 0.4, 2.0), "Sink")
	if not _try_external(fl, &"toilet", Vector3(1.8, 0, 2.0), 180.0, 1.0, "Toilet"):
		StylizedMesh.add_box(fl, Vector3(0.45, 0.45, 0.55), Color(0.88, 0.88, 0.9), Vector3(1.8, 0.35, 2.0), "Toilet")
	StylizedMesh.add_box(fl, Vector3(1.3, 0.55, 0.7), Color(0.85, 0.88, 0.92), Vector3(-0.5, 0.4, 2.0), "Bathtub")
	StylizedMesh.add_box(fl, Vector3(0.5, 0.7, 0.12), Color(0.7, 0.75, 0.8), Vector3(0.9, 1.15, 2.35), "Mirror")


static func _try_external(
	parent: Node3D,
	prop_id: StringName,
	pos: Vector3,
	yaw_deg: float,
	scale_mul: float,
	node_name: String,
) -> bool:
	## Prefer curated GLB furniture when the kit is imported; keep box fallbacks otherwise.
	if not ExternalPropKit.is_available():
		return false
	return ExternalPropKit.spawn(parent, prop_id, pos, yaw_deg, scale_mul, node_name) != null


static func _furnish_shop(fl: BuildingFloor, index: int, rng: RandomNumberGenerator) -> void:
	## Sales floor vs stock room — aisle clear from door (+Z) to counter (−Z).
	if index == 0:
		StylizedMesh.add_box(fl, Vector3(5.5, 0.9, 0.7), WorldPalette.WOOD, Vector3(0, 0.55, -2.0), "Counter", true, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(0.6, 0.35, 0.45), WorldPalette.UI_ACCENT, Vector3(1.5, 1.15, -2.0), "Till")
		for i in 4:
			var x := -2.4 + float(i) * 1.5
			StylizedMesh.add_box(fl, Vector3(1.1, 1.8, 0.35), Color(0.55, 0.4, 0.3), Vector3(x, 1.0, 2.2), "Shelf_%d" % i, false, 1.0, &"wood")
			StylizedMesh.add_box(fl, Vector3(0.9, 0.15, 0.25), Color(0.85, 0.55, 0.35), Vector3(x, 1.35, 2.15), "Goods_%d" % i)
		StylizedMesh.add_box(fl, Vector3(1.2, 0.8, 0.8), Color(0.7, 0.65, 0.5), Vector3(2.3, 0.5, 0.2), "Crate", false, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(0.9, 1.1, 0.08), Color(0.9, 0.55, 0.25), Vector3(-2.6, 1.4, -1.0), "SaleSign")
		if rng.randf() < 0.7:
			StylizedMesh.add_box(fl, Vector3(0.8, 1.4, 0.4), Color(0.4, 0.5, 0.65), Vector3(-2.5, 0.85, -0.5), "Mannequin")
	else:
		StylizedMesh.add_box(fl, Vector3(2.5, 0.9, 1.2), WorldPalette.WOOD, Vector3(-1.2, 0.55, -1.0), "StockTable", false, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(1.5, 1.2, 0.8), Color(0.5, 0.4, 0.3), Vector3(1.8, 0.7, 1.0), "Cartons", false, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(1.0, 0.7, 0.7), Color(0.45, 0.4, 0.35), Vector3(2.2, 0.45, -1.8), "SpareCrate", false, 1.0, &"wood")


static func _furnish_restaurant(fl: BuildingFloor, index: int, _rng: RandomNumberGenerator) -> void:
	if index == 0:
		StylizedMesh.add_box(fl, Vector3(4.0, 0.85, 0.7), WorldPalette.WOOD.darkened(0.1), Vector3(0, 0.5, -2.1), "Bar", true, 1.0, &"wood")
		for i in 3:
			var z := -0.6 + float(i) * 1.5
			StylizedMesh.add_box(fl, Vector3(1.1, 0.45, 1.1), Color(0.55, 0.35, 0.22), Vector3(-2.0, 0.35, z), "Table_%d" % i, false, 1.0, &"wood")
			StylizedMesh.add_box(fl, Vector3(0.4, 0.55, 0.4), Color(0.4, 0.25, 0.18), Vector3(-2.7, 0.35, z), "ChairA_%d" % i)
			StylizedMesh.add_box(fl, Vector3(0.4, 0.55, 0.4), Color(0.4, 0.25, 0.18), Vector3(-1.3, 0.35, z), "ChairB_%d" % i)
		## Kitchen pass is against the right wall — not mixed into seating.
		StylizedMesh.add_box(fl, Vector3(1.4, 1.5, 0.5), Color(0.7, 0.7, 0.75), Vector3(2.4, 0.9, -2.0), "KitchenPass")
		StylizedMesh.add_box(fl, Vector3(0.8, 0.9, 0.6), Color(0.55, 0.55, 0.58), Vector3(2.5, 0.55, -0.6), "PrepFridge")
		StylizedMesh.add_box(fl, Vector3(0.5, 0.08, 0.5), Color(0.95, 0.85, 0.4), Vector3(0, 1.05, -2.1), "Lamp")
	else:
		StylizedMesh.add_box(fl, Vector3(2.0, 0.5, 1.0), Color(0.5, 0.3, 0.25), Vector3(0, 0.4, 0), "PrivateTable", false, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(1.2, 1.4, 0.4), Color(0.45, 0.35, 0.3), Vector3(2.2, 0.85, -1.8), "WineShelf", false, 1.0, &"wood")


static func _furnish_office(fl: BuildingFloor, index: int, _rng: RandomNumberGenerator) -> void:
	## Desk + terminal face the room; filing and shelves along walls — clear center aisle.
	StylizedMesh.add_box(fl, Vector3(1.6, 0.7, 0.9), WorldPalette.WOOD, Vector3(-1.5, 0.45, -1.2), "Desk", true, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(0.5, 0.7, 0.5), Color(0.25, 0.25, 0.28), Vector3(-1.5, 0.45, -0.3), "OfficeChair")
	StylizedMesh.add_box(fl, Vector3(0.7, 0.08, 0.5), Color(0.2, 0.45, 0.7), Vector3(-1.5, 0.9, -1.2), "Terminal")
	StylizedMesh.add_box(fl, Vector3(0.35, 0.08, 0.25), Color(0.9, 0.9, 0.85), Vector3(-1.1, 0.85, -0.95), "Papers")
	StylizedMesh.add_box(fl, Vector3(2.2, 1.8, 0.3), Color(0.55, 0.5, 0.45), Vector3(2.4, 1.0, -2.2), "FileCabinet", false, 1.0, &"brick")
	StylizedMesh.add_box(fl, Vector3(1.4, 1.5, 0.35), Color(0.5, 0.45, 0.4), Vector3(2.5, 0.9, 0.5), "Bookshelves", false, 1.0, &"wood")
	if index > 0:
		StylizedMesh.add_box(fl, Vector3(2.5, 0.9, 1.4), Color(0.4, 0.45, 0.55), Vector3(0, 0.55, 1.0), "MeetingTable", false, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(0.9, 1.2, 0.08), Color(0.85, 0.88, 0.9), Vector3(-2.6, 1.3, -2.4), "Whiteboard")


static func _furnish_warehouse(fl: BuildingFloor, kind: StringName, rng: RandomNumberGenerator) -> void:
	## Crates along the back wall — keep a forklift lane down the middle.
	for i in 5:
		var x := -2.5 + float(i) * 1.2
		var h := 1.0 + rng.randf() * 0.8
		StylizedMesh.add_box(fl, Vector3(0.9, h, 0.9), Color(0.55, 0.4, 0.28), Vector3(x, h * 0.5, -1.8), "Crate_%d" % i, true, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(2.5, 0.15, 4.0), Color(0.35, 0.35, 0.38), Vector3(1.5, 0.12, 0.5), "Pallet")
	StylizedMesh.add_box(fl, Vector3(0.8, 1.6, 0.5), Color(0.4, 0.4, 0.42), Vector3(2.6, 0.95, 1.8), "Rack")
	if kind == InteriorKinds.BARN:
		StylizedMesh.add_box(fl, Vector3(1.5, 1.2, 2.0), Color(0.45, 0.35, 0.22), Vector3(-2.0, 0.7, 1.5), "Hay", false, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(0.8, 1.0, 0.6), Color(0.5, 0.45, 0.35), Vector3(2.2, 0.6, 1.8), "Trough")


static func _furnish_booth(fl: BuildingFloor, _rng: RandomNumberGenerator) -> void:
	StylizedMesh.add_box(fl, Vector3(3.5, 0.9, 0.6), WorldPalette.WOOD, Vector3(0, 0.55, -1.5), "BoothCounter", true, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(1.2, 0.8, 0.8), Color(0.85, 0.55, 0.25), Vector3(-2.0, 0.5, 1.0), "Popcorn")
	StylizedMesh.add_box(fl, Vector3(0.8, 1.1, 0.5), Color(0.3, 0.35, 0.55), Vector3(2.0, 0.7, 1.2), "Projector")
	StylizedMesh.add_box(fl, Vector3(1.0, 0.15, 0.7), Color(0.9, 0.85, 0.5), Vector3(0, 1.1, -1.5), "TicketLamp")
	StylizedMesh.add_box(fl, Vector3(0.9, 0.7, 0.08), Color(0.9, 0.3, 0.35), Vector3(-2.5, 1.3, -1.5), "NowShowing")


static func _furnish_apartment(fl: BuildingFloor, index: int, rng: RandomNumberGenerator, personality: int) -> void:
	if index == 0:
		StylizedMesh.add_box(fl, Vector3(1.4, 0.9, 0.5), WorldPalette.WOOD, Vector3(-2.0, 0.55, -2.0), "Mailboxes", false, 1.0, &"wood")
		StylizedMesh.add_box(fl, Vector3(1.0, 1.8, 0.15), Color(0.6, 0.6, 0.65), Vector3(2.5, 1.0, 0), "LobbyArt")
		StylizedMesh.add_box(fl, Vector3(1.5, 0.45, 1.5), Color(0.45, 0.35, 0.3), Vector3(0, 0.35, 0.5), "LobbyCouch")
		StylizedMesh.add_box(fl, Vector3(0.8, 0.9, 0.4), Color(0.5, 0.45, 0.4), Vector3(2.2, 0.55, -1.8), "Directory")
	else:
		_furnish_house(fl, 1, rng, personality)


static func _furnish_landmark(fl: BuildingFloor, index: int, rng: RandomNumberGenerator) -> void:
	StylizedMesh.add_box(fl, Vector3(2.2, 1.2, 1.0), Color(0.55, 0.45, 0.35), Vector3(0, 0.7, -1.8), "Exhibit", false, 1.0, &"wood")
	StylizedMesh.add_box(fl, Vector3(0.15, 1.4, 0.8), Color(0.9, 0.88, 0.8), Vector3(-2.4, 1.0, 0.5), "Plaque")
	if index == 0:
		StylizedMesh.add_box(fl, Vector3(1.5, 0.5, 1.5), Color(0.4, 0.5, 0.65), Vector3(1.8, 0.4, 1.2), "Bench")
		StylizedMesh.add_box(fl, Vector3(0.6, 0.9, 0.08), Color(0.85, 0.8, 0.65), Vector3(2.5, 1.2, -2.0), "TourPoster")
	else:
		_furnish_office(fl, index, rng)


static func _link_stairs(lower: BuildingFloor, upper: BuildingFloor, from_i: int, to_i: int) -> void:
	## Visual steps on lower floor.
	for s in 4:
		StylizedMesh.add_box(
			lower,
			Vector3(1.4, 0.22, 0.45),
			Color(0.55, 0.4, 0.25),
			Vector3(2.2, 0.25 + float(s) * 0.35, -2.0 - float(s) * 0.25),
			"Step%d" % s,
			false,
			1.0,
			&"wood",
		)
	var up := FloorTransition.new()
	up.name = "StairsUp"
	up.position = Vector3(2.2, 1.0, -2.0)
	up.target_floor_index = to_i
	up.going_up = true
	up.prompt_verb = "Go upstairs"
	var up_shape := CollisionShape3D.new()
	var up_box := BoxShape3D.new()
	up_box.size = Vector3(1.8, 2.0, 1.8)
	up_shape.shape = up_box
	up.add_child(up_shape)
	var up_spawn := Marker3D.new()
	up_spawn.name = "DestSpawn"
	## Land near upstairs spawn, offset from stairs.
	up_spawn.position = Vector3(0, FLOOR_RISE - 0.85, 0.8)
	up.add_child(up_spawn)
	up.target_spawn = up_spawn
	lower.add_child(up)

	var down := FloorTransition.new()
	down.name = "StairsDown"
	down.position = Vector3(2.2, 1.0, -2.0)
	down.target_floor_index = from_i
	down.going_up = false
	down.prompt_verb = "Go downstairs"
	var down_shape := CollisionShape3D.new()
	var down_box := BoxShape3D.new()
	down_box.size = Vector3(1.8, 2.0, 1.8)
	down_shape.shape = down_box
	down.add_child(down_shape)
	var down_spawn := Marker3D.new()
	down_spawn.name = "DestSpawn"
	down_spawn.position = Vector3(0, -(FLOOR_RISE - 0.85), 0.8)
	down.add_child(down_spawn)
	down.target_spawn = down_spawn
	upper.add_child(down)


static func _ensure_secret(fl: BuildingFloor, building_id: StringName, kind: StringName, rng: RandomNumberGenerator) -> void:
	var rarity := ChestInteractable.Rarity.NORMAL
	if kind in [InteriorKinds.LANDMARK, InteriorKinds.TOWER, InteriorKinds.WAREHOUSE]:
		rarity = ChestInteractable.Rarity.RARE
	elif rng.randf() < 0.25:
		rarity = ChestInteractable.Rarity.RARE
	_add_chest(fl, Vector3(-2.4, 0.4, -2.1), building_id, fl.floor_index, rarity)
	## Lore / curiosity plaque.
	var lore := DiscoverableInteractable.new()
	lore.name = "InteriorLore"
	lore.position = Vector3(2.5, 0.9, -2.5)
	lore.location_id = StringName("%s_lore" % String(building_id))
	lore.location_name = "%s note" % String(building_id).capitalize().replace("_", " ")
	lore.discover_message = _lore_line(kind, rng)
	lore.bits_reward = 6 + rng.randi_range(0, 8)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 1.6, 1.4)
	shape.shape = box
	lore.add_child(shape)
	StylizedMesh.add_box(lore, Vector3(0.5, 0.7, 0.08), WorldPalette.UI_PAPER, Vector3(0, 0, 0), "Note")
	fl.add_child(lore)


static func _add_chest(parent: Node3D, pos: Vector3, building_id: StringName, floor_i: int, rarity: ChestInteractable.Rarity) -> void:
	var chest_name := "%s_f%d_chest" % [String(building_id), floor_i]
	RegionPropKit.build_chest(parent, chest_name, pos - Vector3(0, 0.4, 0), rarity, 0.0, "Search")


static func _lore_line(kind: StringName, rng: RandomNumberGenerator) -> String:
	var lines := {
		InteriorKinds.SHOP: ["Inventory scratched in the margin: 'hex shards move fast.'", "A sticky note: 'Restock aisle 3 before noon.'"],
		InteriorKinds.RESTAURANT: ["Today's special is circled twice.", "Someone tipped with a shiny bit."],
		InteriorKinds.HOUSE: ["A postcard from Mirror Mere.", "Kid's drawing of a orange dino taped to the wall."],
		InteriorKinds.CABIN: ["Tide chart penciled on scrap wood.", "Boots still muddy from the shore path."],
		InteriorKinds.WAREHOUSE: ["Shipping label: Grease Grove → Market Mile.", "Manifest lists 'spare sprocket ×12'."],
		InteriorKinds.BARN: ["Feed schedule for the week.", "A horseshoe hung for luck."],
		InteriorKinds.BOOTH: ["Reel change checklist half done.", "Popcorn oil invoice from last Friday."],
		InteriorKinds.OFFICE: ["Meeting notes: 'expand north pass trail'.", "Badge lanyard left on the desk."],
		InteriorKinds.TOWER: ["Observation log: storm front SE.", "Elevator out of order — use stairs."],
		InteriorKinds.LANDMARK: ["A plaque about the first settlers.", "Tour pamphlet folded into a paper bird."],
	}
	var key := kind if lines.has(kind) else InteriorKinds.HOUSE
	var arr: Array = lines[key]
	return arr[rng.randi_range(0, arr.size() - 1)]


static func _wall_color(kind: StringName) -> Color:
	match kind:
		InteriorKinds.SHOP:
			return Color(0.88, 0.84, 0.76)
		InteriorKinds.RESTAURANT:
			return Color(0.82, 0.72, 0.62)
		InteriorKinds.WAREHOUSE, InteriorKinds.BARN:
			return Color(0.7, 0.62, 0.5)
		InteriorKinds.OFFICE, InteriorKinds.TOWER:
			return Color(0.78, 0.8, 0.84)
		InteriorKinds.BOOTH:
			return Color(0.55, 0.35, 0.4)
		_:
			return Color(0.85, 0.82, 0.75)


static func _floor_color(kind: StringName) -> Color:
	match kind:
		InteriorKinds.WAREHOUSE, InteriorKinds.BARN:
			return Color(0.45, 0.4, 0.35)
		InteriorKinds.SHOP, InteriorKinds.RESTAURANT:
			return Color(0.55, 0.42, 0.32)
		_:
			return Color(0.62, 0.48, 0.34)
