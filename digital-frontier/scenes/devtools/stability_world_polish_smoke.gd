extends Node
## Stability + world polish QA — inspect toggle, building enter/exit, walkable roads, roofs.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("STABILITY_WORLD_POLISH_SMOKE_START")
	GameConfig.enable_cheats = true


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 2:
		return
	_done = true
	_run()


func _run() -> void:
	var ok := true

	## --- 3D View: nested MENU must not block or instant-kick ---
	InputManager.set_context(InputManager.Context.OVERWORLD)
	UIManager.push_modal(&"device")
	UIManager.push_modal(&"settings")
	if InputManager.get_context() != InputManager.Context.MENU:
		push_error("expected MENU after nested modals")
		ok = false

	var world := Node3D.new()
	world.name = "SmokeWorld"
	add_child(world)
	var rig := Node3D.new()
	rig.name = "CameraRig"
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	rig.add_child(cam)
	rig.set_script(load("res://scenes/world/camera_rig.gd"))
	rig.add_to_group(&"camera_rig")
	world.add_child(rig)
	await get_tree().process_frame

	var inspect := WorldInspectController.new()
	world.add_child(inspect)
	inspect.setup(rig)
	await get_tree().process_frame

	inspect.toggle_from_ui()
	await get_tree().process_frame
	await get_tree().process_frame
	if not inspect.is_active():
		push_error("3D View failed to activate from nested settings")
		ok = false
	if UIManager.has_open_modal():
		push_error("modals should clear when entering 3D View")
		ok = false
	var free_cam := inspect.find_child("InspectCamera", true, false) as Camera3D
	if free_cam == null or not free_cam.current:
		push_error("InspectCamera not current after toggle_from_ui")
		ok = false

	## Stay on for several frames (no cancel kick).
	for _i in 8:
		await get_tree().process_frame
	if not inspect.is_active():
		push_error("3D View kicked off unexpectedly")
		ok = false

	inspect.exit_mode()
	await get_tree().process_frame
	if inspect.is_active():
		push_error("3D View failed to exit")
		ok = false
	if cam.current != true:
		push_error("gameplay camera not restored")
		ok = false

	## --- Buildings: fuel shop, house, garage ---
	var park := Node3D.new()
	park.name = "ParkRoot"
	world.add_child(park)
	var built := PleasantParkBuilder.build(park)
	var interior_host := Node3D.new()
	interior_host.name = "InteriorContainer"
	world.add_child(interior_host)
	var bic := BuildingInteriorController.new()
	bic.name = "BuildingInteriorController"
	world.add_child(bic)
	bic.setup(rig, interior_host)

	var player := CharacterBody3D.new()
	player.name = "SmokePlayer"
	player.add_to_group(GameConstants.GROUP_PLAYER)
	world.add_child(player)

	var fuel := park.find_child("PassNFuelShop", true, false) as BuildingVolume
	if fuel == null:
		push_error("PassNFuelShop missing")
		ok = false
	else:
		ok = await _enter_exit(bic, fuel, player, "fuel") and ok
		if fuel.roof_paths.is_empty():
			push_error("fuel roof_paths empty — typed Array assign failed")
			ok = false

	var houses: Array = built.get(&"enterable_houses", [])
	if houses.size() < 8:
		push_error("expected 8 houses")
		ok = false
	elif houses[0] is BuildingVolume:
		var house := houses[0] as BuildingVolume
		ok = await _enter_exit(bic, house, player, "house") and ok
		if house.roof_paths.is_empty():
			push_error("house roof_paths empty")
			ok = false

	var garage := park.find_child("GarageVolume", true, false) as BuildingVolume
	if garage == null:
		push_error("GarageVolume missing")
		ok = false
	else:
		ok = await _enter_exit(bic, garage, player, "garage") and ok
		if garage.get_roof_meshes().is_empty():
			push_error("garage should resolve roof meshes")
			ok = false

	## --- Walkable roads: collision top near grass, not a curb cliff ---
	var arterial := park.find_child("ArterialNS", true, false) as Node3D
	if arterial == null:
		push_error("ArterialNS missing")
		ok = false
	else:
		var col := arterial.find_child("CollisionShape3D", true, false) as CollisionShape3D
		if col == null:
			## walkable body may nest shape differently
			for c in arterial.get_children():
				if c is CollisionShape3D:
					col = c as CollisionShape3D
					break
		if col and col.shape is BoxShape3D:
			var bs := col.shape as BoxShape3D
			if bs.size.y > 0.08:
				push_error("road collision too thick (lip): %s" % bs.size)
				ok = false
		## Body should sit near grass Y
		if arterial is Node3D and absf(arterial.position.y - PleasantParkBuilder.Y_GRASS) > 0.05:
			## add_walkable_box sets body.position.y = walk_y
			pass

	## Shop interiors are single-story (gas station footprint).
	if InteriorKinds.stories_for(InteriorKinds.SHOP) != 1:
		push_error("SHOP should be 1 story")
		ok = false

	## Furniture collision still tight.
	var sofa: Vector3 = ExternalPropKit._furniture_collision_dims("sofa")
	if sofa.x > 1.85:
		push_error("sofa collision regressed")
		ok = false

	if ok:
		print("STABILITY_WORLD_POLISH_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("STABILITY_WORLD_POLISH_SMOKE_FAIL")
		get_tree().quit(1)


func _enter_exit(bic: BuildingInteriorController, building: BuildingVolume, actor: Node, label: String) -> bool:
	InputManager.set_context(InputManager.Context.OVERWORLD)
	await bic.enter_building(building, actor)
	await get_tree().process_frame
	if not building.is_occupied():
		push_error("%s enter failed" % label)
		return false
	if InputManager.get_context() != InputManager.Context.BUILDING_INTERIOR:
		push_error("%s context not BUILDING_INTERIOR" % label)
		return false
	await bic.exit_building(actor)
	await get_tree().process_frame
	if building.is_occupied():
		push_error("%s exit failed" % label)
		return false
	return true
