extends Node
## World polish smoke — room-logic interiors, personality variation, vegetation guards.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("WORLD_POLISH_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 3:
		return
	_done = true
	var ok := true

	## Personality mapping from exterior styles
	if InteriorPersonality.from_style_name(&"brick") != InteriorPersonality.Style.WEALTHY:
		push_error("brick should be wealthy")
		ok = false
	if InteriorPersonality.from_style_name(&"cottage") != InteriorPersonality.Style.RUSTIC:
		push_error("cottage should be rustic")
		ok = false
	if InteriorPersonality.from_style_name(&"modern") != InteriorPersonality.Style.MODERN:
		push_error("modern should be modern")
		ok = false
	if InteriorPersonality.from_style_name(&"garden") != InteriorPersonality.Style.GARDEN:
		push_error("garden should be garden")
		ok = false

	## Modest home — living / kitchen / bedroom / bath zones
	var modest := ModularInteriorBuilder.build(InteriorKinds.HOUSE, &"smoke_modest", 1, InteriorPersonality.Style.MODEST)
	ok = _assert_named(modest, ["Couch", "Television", "CoffeeTable", "Refrigerator", "Stove", "DiningTable"]) and ok
	ok = _assert_named(modest, ["Bed", "Nightstand", "Closet", "Sink", "Toilet", "Bathtub"]) and ok
	## Kitchen must not contain bedroom props on floor 0 (bed is upstairs only).
	var f0 := modest.get_node_or_null("Floor_0")
	if f0 and f0.find_child("Bed", true, false) != null:
		push_error("bed incorrectly on ground floor")
		ok = false
	modest.free()

	## Wealthy vs abandoned tell different stories
	var wealthy := ModularInteriorBuilder.build(InteriorKinds.HOUSE, &"smoke_wealthy", 2, InteriorPersonality.Style.WEALTHY)
	ok = _assert_named(wealthy, ["ChinaCabinet", "Mixer", "FamilyPhoto"]) and ok
	wealthy.free()
	var abandoned := ModularInteriorBuilder.build(InteriorKinds.HOUSE, &"smoke_abandoned", 3, InteriorPersonality.Style.ABANDONED)
	ok = _assert_named(abandoned, ["BrokenCounter", "DustyFridge", "FallenBook"]) and ok
	if abandoned.find_child("Refrigerator", true, false) != null:
		push_error("abandoned should not have pristine fridge")
		ok = false
	abandoned.free()

	## Shop / office stay role-correct
	var shop := ModularInteriorBuilder.build(InteriorKinds.SHOP, &"smoke_shop", 4)
	ok = _assert_named(shop, ["Counter", "Till", "Shelf_0"]) and ok
	if shop.find_child("Bed", true, false) != null:
		push_error("shop should not have a bed")
		ok = false
	shop.free()
	var office := ModularInteriorBuilder.build(InteriorKinds.OFFICE, &"smoke_office", 5)
	ok = _assert_named(office, ["Desk", "Terminal", "Bookshelves"]) and ok
	office.free()

	## Garage interior — tools / shelves / workbench
	var garage := ModularInteriorBuilder.build(InteriorKinds.GARAGE, &"smoke_garage", 6)
	ok = _assert_named(garage, ["ShelfUnit", "Workbench", "Toolbox", "Pegboard"]) and ok
	garage.free()

	## Pleasant Park layout contracts — pond, frontage, enterable garage shell
	var park_root := Node3D.new()
	add_child(park_root)
	var built := PleasantParkBuilder.build(park_root)
	if park_root.find_child("ParkPond", true, false) == null:
		push_error("park pond missing")
		ok = false
	if park_root.find_child("FrontageN", true, false) == null or park_root.find_child("ArterialNS", true, false) == null:
		push_error("redesigned road network missing")
		ok = false
	if park_root.find_child("Drive_0", true, false) == null or park_root.find_child("JctF_22_22", true, false) == null:
		push_error("garage aprons / junction pads missing")
		ok = false
	## Gazebo must stay human-scale (roof deck ~4.6m, not the old 7m pavilion).
	var gazebo := park_root.find_child("Gazebo", true, false)
	if gazebo:
		var roof := gazebo.get_node_or_null("RoofDeck") as MeshInstance3D
		if roof and roof.mesh is BoxMesh:
			var rs: Vector3 = (roof.mesh as BoxMesh).size
			if rs.x > 5.2 or rs.z > 5.2:
				push_error("gazebo roof oversized: %s" % rs)
				ok = false
	else:
		push_error("gazebo missing")
		ok = false
	var gcount := 0
	for n in park_root.find_children("GarageVolume", "", true, false):
		gcount += 1
		if n.get_node_or_null("DoorInteractable") == null:
			push_error("garage missing door")
			ok = false
		if n.get_node_or_null("GarageDoor") == null:
			push_error("garage missing door mesh")
			ok = false
	if gcount < 8:
		push_error("expected 8 garages, got %d" % gcount)
		ok = false
	## Every enterable house needs a local Driveway that meets the street apron.
	var drive_count := 0
	for n in park_root.find_children("Driveway", "", true, false):
		drive_count += 1
	if drive_count < 8:
		push_error("expected 8 house driveways, got %d" % drive_count)
		ok = false
	if (built.get(&"enterable_houses", []) as Array).size() < 8:
		push_error("enterable houses missing")
		ok = false
	## Furniture collision proxies stay tight (sofa footprint, not a shared 1.4×0.85 slab).
	var sofa_dims: Vector3 = ExternalPropKit._furniture_collision_dims("sofa")
	if sofa_dims.x > 1.85 or sofa_dims.z > 0.85:
		push_error("sofa collision too large: %s" % sofa_dims)
		ok = false
	var chair_dims: Vector3 = ExternalPropKit._furniture_collision_dims("chair")
	if chair_dims.x > 0.5 or chair_dims.z > 0.5:
		push_error("chair collision too large: %s" % chair_dims)
		ok = false
	## Corridor spokes leave the hub at arterial tips (not floating mid-lawn).
	var salty0: Vector3 = GrasslandLayout.path_park_to_salty()[0]
	if absf(salty0.z - 41.0) > 0.5:
		push_error("salty path should start at RoadApproach tip, got %s" % salty0)
		ok = false
	park_root.queue_free()

	## Placement guards reject road / hub centers
	var hub: Vector3 = GrasslandLayout.hub_exclusion_zones()[0]["pos"]
	if RegionVegetationBuilder.placement_allowed(hub, true):
		push_error("trees should be blocked at hub center")
		ok = false
	var road_pt: Vector3 = GrasslandLayout.path_park_to_salty()[0]
	if RegionVegetationBuilder.placement_allowed(road_pt, true):
		push_error("trees should be blocked on road polyline")
		ok = false
	## Far wilderness should allow growth
	if not RegionVegetationBuilder.placement_allowed(Vector3(120, 0, 180), true):
		push_error("wilderness anchor should allow trees")
		ok = false

	if ok:
		print("WORLD_POLISH_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("WORLD_POLISH_SMOKE_FAIL")
		get_tree().quit(1)


func _assert_named(root: Node, names: Array) -> bool:
	var ok := true
	for n in names:
		if root.find_child(String(n), true, false) == null:
			push_error("missing interior prop: %s" % String(n))
			ok = false
	return ok
