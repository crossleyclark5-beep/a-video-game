extends Node
## Vehicle system smoke — spawn car, mount, drive tick, dismount, ownership save.


func _ready() -> void:
	print("VEHICLE_SYSTEM_SMOKE_START")
	await get_tree().process_frame
	var ok := true

	var cruiser: VehicleData = ResourceRegistry.get_vehicle(&"park_cruiser")
	var suv: VehicleData = ResourceRegistry.get_vehicle(&"adventure_suv")
	var truck: VehicleData = ResourceRegistry.get_vehicle(&"utility_truck")
	if cruiser == null or suv == null or truck == null:
		push_error("ground vehicle data missing")
		ok = false
	elif cruiser.vehicle_class != VehicleData.VehicleClass.GROUND:
		push_error("park_cruiser should be GROUND")
		ok = false
	else:
		print("vehicle_data_ok")

	VehicleManager.reset_state()
	var root := Node3D.new()
	root.name = "VehicleSmokeRoot"
	add_child(root)

	## Fake floor so CharacterBody can settle.
	var floor := StaticBody3D.new()
	floor.name = "Floor"
	var fshape := CollisionShape3D.new()
	var fbox := BoxShape3D.new()
	fbox.size = Vector3(80, 1, 80)
	fshape.shape = fbox
	fshape.position = Vector3(0, -0.5, 0)
	floor.add_child(fshape)
	root.add_child(floor)

	var player := CharacterBody3D.new()
	player.name = "SmokePlayer"
	player.add_to_group(GameConstants.GROUP_PLAYER)
	player.position = Vector3(3, 0.2, 0)
	var pshape := CollisionShape3D.new()
	var pbox := BoxShape3D.new()
	pbox.size = Vector3(0.6, 1.6, 0.6)
	pshape.shape = pbox
	pshape.position = Vector3(0, 0.8, 0)
	player.add_child(pshape)
	root.add_child(player)

	var car := VehicleSpawner.spawn_car(root, &"park_cruiser", Vector3(0, 0.1, 0), 0.0, "SmokeCar")
	await get_tree().process_frame
	await get_tree().physics_frame
	if car == null or not car.is_in_group(GameConstants.GROUP_VEHICLES):
		push_error("car spawn/group failed")
		ok = false
	if car.get_node_or_null("EnterPad") == null:
		push_error("enter pad missing")
		ok = false
	else:
		print("car_spawn_ok")

	if not car.try_mount(player):
		push_error("mount failed")
		ok = false
	elif not VehicleManager.is_driving():
		push_error("manager not driving")
		ok = false
	elif player.visible:
		push_error("player should be hidden while driving")
		ok = false
	else:
		print("mount_ok")

	## Simulate a few drive frames with forward input context.
	InputManager.set_context(InputManager.Context.VEHICLE)
	for i in 8:
		car._drive(0.05)
		await get_tree().physics_frame
	if not car.is_occupied():
		push_error("lost driver mid-drive")
		ok = false
	else:
		print("drive_tick_ok")

	if not car.try_dismount():
		push_error("dismount failed")
		ok = false
	elif VehicleManager.is_driving():
		push_error("still marked driving")
		ok = false
	elif not player.visible:
		push_error("player should be visible after exit")
		ok = false
	else:
		print("dismount_ok")

	## Ownership / garage foundation
	VehicleManager.own_vehicle(&"park_cruiser", false)
	VehicleManager.own_vehicle(&"adventure_suv", false)
	var state := VehicleManager.export_state()
	if not state.has(&"owned") or not (state[&"owned"] as Dictionary).has(&"park_cruiser"):
		push_error("owned garage missing in export")
		ok = false
	VehicleManager.reset_state()
	VehicleManager.import_state(state)
	if not VehicleManager.is_owned(&"park_cruiser"):
		push_error("owned import failed")
		ok = false
	else:
		print("ownership_ok")

	## Framework still supports air class
	var skiff: VehicleData = ResourceRegistry.get_vehicle(&"field_skiff")
	if skiff == null or skiff.vehicle_class != VehicleData.VehicleClass.AIR:
		push_error("field_skiff AIR class broken")
		ok = false

	root.queue_free()
	VehicleManager.reset_state()

	if ok:
		print("VEHICLE_SYSTEM_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("VEHICLE_SYSTEM_SMOKE_FAIL")
		get_tree().quit(1)
