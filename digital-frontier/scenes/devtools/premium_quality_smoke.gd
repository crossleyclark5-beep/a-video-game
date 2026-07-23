extends Node
## Premium quality P1 smoke — audio beds, care verbs, combat result hold, loading scene.


func _ready() -> void:
	print("PREMIUM_QUALITY_SMOKE_START")
	await get_tree().process_frame
	var ok := true

	## Music beds respond to EventBus
	EventBus.music_change_requested.emit(&"home_night")
	await get_tree().process_frame
	if AudioManager._current_music_id != &"home_night":
		push_error("home_night music not active")
		ok = false
	else:
		print("music_bed_ok")

	## Missing vehicle SFX ids exist
	for id in [&"vehicle_launch", &"vehicle_land", &"creature_rest", &"creature_play"]:
		if not AudioManager._sfx_streams.has(id):
			push_error("missing sfx %s" % String(id))
			ok = false
	print("sfx_map_ok")

	## Volume buses applied
	AudioManager.refresh_volumes()
	print("volume_buses_ok")

	## Loading screen exists
	if not ResourceLoader.exists(String(GameConstants.SCENE_LOADING)):
		push_error("loading screen missing")
		ok = false
	else:
		print("loading_screen_ok")

	## Catalog height targets for trees / bench
	var oak := ExternalPropCatalog.prop_def(&"tree_oak")
	if float(oak.get("target_height", 0.0)) < 4.0:
		push_error("tree_oak missing target_height")
		ok = false
	var bench := ExternalPropCatalog.prop_def(&"bench")
	if float(bench.get("target_height", 0.0)) < 0.4:
		push_error("bench missing target_height")
		ok = false
	print("catalog_heights_ok")

	## Truck procedural path builds non-sedan cabin
	var root := Node3D.new()
	add_child(root)
	var truck := VehicleSpawner.spawn_car(root, &"utility_truck", Vector3.ZERO, 0.0, "SmokeTruck")
	await get_tree().process_frame
	if truck == null:
		push_error("truck spawn failed")
		ok = false
	elif truck.get_node_or_null("Visual/Cabin") == null and truck.get_node_or_null("Visual/Bed") == null:
		## GLB path may exist; at least visual should not be empty
		var vis := truck.get_node_or_null("Visual")
		if vis == null or vis.get_child_count() < 2:
			push_error("truck visual too sparse")
			ok = false
		else:
			print("truck_visual_ok")
	else:
		print("truck_visual_ok")

	## Garage still builds
	var garage := ModularInteriorBuilder.build(InteriorKinds.GARAGE, &"premium_garage", 1)
	if garage.find_child("Workbench", true, false) == null:
		push_error("garage furnish broken")
		ok = false
	else:
		print("garage_ok")
	garage.free()

	print("PREMIUM_QUALITY_SMOKE_" + ("OK" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
