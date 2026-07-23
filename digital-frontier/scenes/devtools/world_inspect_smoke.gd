extends Node
## World Inspection Mode smoke — free-cam toggle, overlays, placement scan.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("WORLD_INSPECT_SMOKE_START")
	GameConfig.enable_cheats = true


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 2:
		return
	_done = true
	var ok := true

	## Context enum present
	if InputManager.Context.WORLD_INSPECT < 0:
		push_error("WORLD_INSPECT context missing")
		ok = false

	## Inspect action registered
	if not InputMap.has_action(&"inspect_toggle"):
		push_error("inspect_toggle action missing")
		ok = false

	## Minimal world + camera rig (Camera3D must exist before CameraRig._ready).
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

	InputManager.set_context(InputManager.Context.OVERWORLD)

	var inspect := WorldInspectController.new()
	world.add_child(inspect)
	inspect.setup(rig)
	await get_tree().process_frame

	if not inspect.can_enter():
		push_error("can_enter should be true with cheats")
		ok = false

	inspect.enter_mode()
	await get_tree().process_frame
	if not inspect.is_active():
		push_error("inspect mode failed to activate")
		ok = false
	if InputManager.get_context() != InputManager.Context.WORLD_INSPECT:
		push_error("context should be WORLD_INSPECT")
		ok = false
	if InputManager.get_move_vector() != Vector2.ZERO:
		## No keys held — should be zero; also blocked in inspect
		pass

	## Free camera should be current + perspective
	var free_cam := inspect.get_node_or_null("InspectCamera") as Camera3D
	if free_cam == null or not free_cam.current:
		push_error("InspectCamera missing or not current")
		ok = false
	elif free_cam.projection != Camera3D.PROJECTION_PERSPECTIVE:
		push_error("inspect camera should be perspective")
		ok = false

	## Overlay toggles
	inspect.set_overlay(WorldInspectController.Overlay.GRID, true)
	if not inspect.is_overlay_on(WorldInspectController.Overlay.GRID):
		push_error("grid overlay failed")
		ok = false
	inspect.set_overlay(WorldInspectController.Overlay.HEIGHT, true)
	inspect.set_overlay(WorldInspectController.Overlay.SCALE, true)
	inspect.set_overlay(WorldInspectController.Overlay.OBJECT_INFO, true)
	## Collision overlay builds proxies (Viewport collision debug_draw removed in 4.7).
	var body := StaticBody3D.new()
	body.name = "SmokeCollider"
	body.position = Vector3(5, 0.5, 5)
	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(2, 1, 2)
	col.shape = col_shape
	body.add_child(col)
	world.add_child(body)
	await get_tree().process_frame
	inspect.set_overlay(WorldInspectController.Overlay.COLLISION, false)
	inspect.set_overlay(WorldInspectController.Overlay.COLLISION, true)
	await get_tree().process_frame
	var col_root := inspect.get_node_or_null("Overlays/InspectCollision")
	if col_root == null or col_root.get_child_count() < 1:
		push_error("collision overlay proxies missing")
		ok = false

	## Dummy mesh for placement / pick
	var prop := MeshInstance3D.new()
	prop.name = "FloatingProp"
	var box := BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	prop.mesh = box
	prop.position = Vector3(10, 8, 10) ## clearly floating vs ground ~0
	world.add_child(prop)
	free_cam.global_position = Vector3(10, 12, 20)
	var issues := inspect.run_placement_scan()
	print("WORLD_INSPECT_SMOKE_ISSUES=%d" % issues)
	if issues < 1:
		push_error("expected at least one placement issue for floating prop")
		ok = false

	## Exit restores gameplay camera + context
	inspect.exit_mode()
	await get_tree().process_frame
	if inspect.is_active():
		push_error("inspect still active after exit")
		ok = false
	if InputManager.get_context() != InputManager.Context.OVERWORLD:
		push_error("context not restored to OVERWORLD")
		ok = false
	if not cam.current:
		push_error("gameplay camera should be current after exit")
		ok = false

	## Cheats off blocks enter
	GameConfig.enable_cheats = false
	if inspect.can_enter():
		push_error("can_enter should be false when cheats disabled")
		ok = false
	GameConfig.enable_cheats = true

	world.queue_free()

	if ok:
		print("WORLD_INSPECT_SMOKE_OK")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(0)
	else:
		print("WORLD_INSPECT_SMOKE_FAIL")
		await get_tree().create_timer(0.05).timeout
		get_tree().quit(1)
