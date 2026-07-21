extends Node
## Prototype assets + Field Skiff travel smoke.


func _ready() -> void:
	print("PROTOTYPE_ASSETS_SMOKE_START")
	await get_tree().process_frame
	var ok := true

	if not ExternalPropKit.is_available():
		push_error("ExternalPropKit unavailable")
		ok = false

	for id in [&"craft_speeder", &"hangar_small", &"treasure_chest", &"supply_crate", &"park_car", &"adventure_suv"]:
		if not ExternalPropCatalog.has_prop(id):
			push_error("catalog missing %s" % String(id))
			ok = false
		elif not ResourceLoader.exists(ExternalPropCatalog.prop_path(id)):
			push_error("glb missing %s" % String(id))
			ok = false

	var skiff: VehicleData = ResourceRegistry.get_vehicle(&"field_skiff")
	if skiff == null:
		push_error("field_skiff vehicle data missing")
		ok = false
	elif skiff.vehicle_class != VehicleData.VehicleClass.AIR:
		push_error("field_skiff should be AIR class")
		ok = false
	else:
		print("field_skiff_ok")

	VehicleManager.reset_state()
	VehicleManager.unlock(&"field_skiff", false)
	if not VehicleManager.is_unlocked(&"field_skiff"):
		push_error("unlock failed")
		ok = false

	var root := Node3D.new()
	add_child(root)
	var player := CharacterBody3D.new()
	player.name = "SmokePlayer"
	player.position = Vector3(0, 0.2, 0)
	root.add_child(player)

	var dests := AircraftTravelCatalog.destinations()
	if dests.size() < 5:
		push_error("too few air destinations")
		ok = false

	AircraftPadInteractable.build_pad(root, Vector3(10, 0, 0), 0.0, "SmokeHangar")
	await get_tree().process_frame
	if root.find_child("BoardPad", true, false) == null:
		push_error("hangar pad missing")
		ok = false
	else:
		print("hangar_pad_ok")

	## Chest uses treasure mesh when available.
	var chest := RegionPropKit.build_chest(root, "SmokeChest", Vector3(4, 0, 0), ChestInteractable.Rarity.RARE)
	await get_tree().process_frame
	if chest == null:
		push_error("chest build failed")
		ok = false
	elif chest.find_child("ChestMesh", true, false) == null and chest.find_child("Lid", true, false) == null:
		push_error("chest visual missing")
		ok = false
	else:
		print("chest_visual_ok")

	## Short hop — wait for travel to finish.
	var target: Vector3 = dests[1]["pos"]
	VehicleManager.fly_to(player, player.global_position + Vector3(20, 0, 0), &"field_skiff")
	var waited := 0.0
	while VehicleManager.is_traveling() and waited < 6.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if VehicleManager.is_traveling():
		push_error("travel did not finish")
		ok = false
	else:
		print("air_hop_ok")

	## Partners must remain custom — no external partner folder.
	if ResourceLoader.exists("res://assets/models/external/partners/"):
		push_error("partner GLB folder must not exist")
		ok = false

	root.queue_free()
	VehicleManager.reset_state()

	if ok:
		print("PROTOTYPE_ASSETS_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("PROTOTYPE_ASSETS_SMOKE_FAIL")
		get_tree().quit(1)
