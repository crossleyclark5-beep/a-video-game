class_name VehicleBase
extends CharacterBody3D
## Reusable vehicle body — mount, drive hooks, exit. Subclass for car/boat/air drive models.


signal mounted(player: Node3D)
signal dismounted(player: Node3D)

@export var vehicle_id: StringName = &""
@export var instance_id: StringName = &""
@export var data: VehicleData = null

var _driver: Node3D = null
var _enter_pad: VehicleEnterInteractable = null
var _visual: Node3D = null
var _mounting: bool = false
var _driver_saved_layer: int = 4
var _driver_saved_mask: int = 3


func _ready() -> void:
	add_to_group(GameConstants.GROUP_VEHICLES)
	collision_layer = 32  ## vehicles
	collision_mask = 1 | 2  ## world static + dynamic
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.35
	if instance_id == &"":
		instance_id = StringName("%s_%s" % [String(vehicle_id), str(get_instance_id())])
	if data == null and vehicle_id != &"":
		data = ResourceRegistry.get_vehicle(vehicle_id)
	_ensure_collision()
	_ensure_visual()
	_ensure_enter_pad()
	VehicleManager.register_world_vehicle(self)


func _exit_tree() -> void:
	VehicleManager.unregister_world_vehicle(self)


func is_occupied() -> bool:
	return _driver != null


func get_driver() -> Node3D:
	return _driver


func get_display_name() -> String:
	if data:
		return data.display_name
	return String(vehicle_id)


func can_mount(actor: Node) -> bool:
	if _mounting or is_occupied() or VehicleManager.is_traveling():
		return false
	if VehicleManager.is_driving() and VehicleManager.get_mounted_vehicle() != self:
		return false
	return actor != null and actor.is_in_group(GameConstants.GROUP_PLAYER)


func try_mount(actor: Node) -> bool:
	if not can_mount(actor):
		return false
	_mounting = true
	var player := actor as Node3D
	_play_enter_transition(player)
	_driver = player
	_hide_driver(player)
	VehicleManager.mount_vehicle(self, player)
	_set_camera_vehicle(true)
	mounted.emit(player)
	_mounting = false
	EventBus.ui_notification_requested.emit("Driving · B to exit", 2.0)
	return true


func try_dismount() -> bool:
	if _driver == null or _mounting:
		return false
	_mounting = true
	var player := _driver
	var exit_pos := _safe_exit_position()
	velocity = Vector3.ZERO
	_show_driver(player, exit_pos)
	_driver = null
	VehicleManager.dismount_vehicle()
	_set_camera_vehicle(false)
	dismounted.emit(player)
	_mounting = false
	EventBus.ui_notification_requested.emit("Left the %s" % get_display_name(), 1.6)
	return true


func _physics_process(delta: float) -> void:
	if not is_occupied():
		## Parked — settle on ground.
		if not is_on_floor():
			velocity.y -= 28.0 * delta
		else:
			velocity = Vector3.ZERO
		move_and_slide()
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		try_dismount()
		return
	_drive(delta)


## Override in subclasses (car / boat / aircraft drive models).
func _drive(delta: float) -> void:
	velocity = Vector3.ZERO
	move_and_slide()


func _play_enter_transition(player: Node3D) -> void:
	## Prototype: short hop toward door; door anims when meshes support them.
	if player == null:
		return
	var door := global_position + -global_transform.basis.x * 1.6
	door.y = player.global_position.y
	player.global_position = player.global_position.lerp(door, 0.55)


func _hide_driver(player: Node3D) -> void:
	if player is CollisionObject3D:
		var body := player as CollisionObject3D
		_driver_saved_layer = body.collision_layer
		_driver_saved_mask = body.collision_mask
		body.collision_layer = 0
		body.collision_mask = 0
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
		(player as CharacterBody3D).set_physics_process(false)
	player.visible = false
	var agent := player.get_node_or_null("InteractionAgent")
	if agent is Area3D:
		(agent as Area3D).monitoring = false
		(agent as Area3D).monitorable = false


func _show_driver(player: Node3D, exit_pos: Vector3) -> void:
	player.global_position = exit_pos
	player.visible = true
	if player is CollisionObject3D:
		var body := player as CollisionObject3D
		body.collision_layer = _driver_saved_layer
		body.collision_mask = _driver_saved_mask
	if player is CharacterBody3D:
		(player as CharacterBody3D).set_physics_process(true)
	var agent := player.get_node_or_null("InteractionAgent")
	if agent is Area3D:
		(agent as Area3D).monitoring = true
		(agent as Area3D).monitorable = true


func _safe_exit_position() -> Vector3:
	var offset := Vector3(2.2, 0.0, 0.4)
	if data:
		offset = data.exit_offset
	var candidates := [
		global_position + global_transform.basis * offset,
		global_position + global_transform.basis * Vector3(-offset.x, offset.y, offset.z),
		global_position + global_transform.basis * Vector3(0.0, 0.0, -2.4),
		global_position + Vector3(0, 0, 2.5),
	]
	var space := get_world_3d().direct_space_state
	for c in candidates:
		var from: Vector3 = c + Vector3(0, 2.5, 0)
		var to: Vector3 = c + Vector3(0, -4.0, 0)
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 1 | 2
		query.exclude = [get_rid()]
		var hit := space.intersect_ray(query)
		if hit:
			var p: Vector3 = hit.position + Vector3(0, 0.15, 0)
			## Prefer exits that aren't inside the car AABB.
			if p.distance_to(global_position) > 1.4:
				return p
		elif c.distance_to(global_position) > 1.4:
			return c + Vector3(0, 0.15, 0)
	return global_position + Vector3(2.4, 0.15, 0)


func _set_camera_vehicle(active: bool) -> void:
	var cams := get_tree().get_nodes_in_group(&"camera_rig")
	if cams.is_empty():
		## Fallback: find CameraRig by class script path.
		for n in get_tree().get_nodes_in_group(&"cameras"):
			cams.append(n)
	for cam in get_tree().root.get_children():
		pass
	var rig := _find_camera_rig()
	if rig == null:
		return
	if active:
		if rig.has_method("set_vehicle_mode"):
			rig.call("set_vehicle_mode", true, self, data)
		elif rig.has_method("set_target"):
			rig.call("set_target", self)
	else:
		if rig.has_method("set_vehicle_mode"):
			rig.call("set_vehicle_mode", false, null, null)
		var players := get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
		if not players.is_empty() and rig.has_method("set_target"):
			rig.call("set_target", players[0])


func _find_camera_rig() -> Node:
	var world := get_tree().get_first_node_in_group(&"game_world")
	if world:
		var rig := world.get_node_or_null("CameraRig")
		if rig:
			return rig
	## Search common path under current scene.
	var scene := get_tree().current_scene
	if scene:
		var r := scene.find_child("CameraRig", true, false)
		if r:
			return r
	return null


func _ensure_collision() -> void:
	if has_node("BodyCollision"):
		return
	var shape := CollisionShape3D.new()
	shape.name = "BodyCollision"
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.25, 4.4)
	shape.shape = box
	shape.position = Vector3(0, 0.7, 0)
	add_child(shape)


func _ensure_visual() -> void:
	if has_node("Visual"):
		_visual = $Visual
		return
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var prop_id := &""
	var color := Color(0.75, 0.25, 0.22)
	if data:
		prop_id = data.visual_prop_id
		color = data.body_color
	if prop_id != &"" and ExternalPropKit.is_available():
		var body_col := color
		ExternalPropKit.spawn(_visual, prop_id, Vector3.ZERO, 0.0, 1.0, "Mesh", body_col)
		## External props bring their own proxy collision — remove duplicate static bodies under visual.
		_strip_proxy_collision(_visual)
		_decorate_vehicle_accents(color)
	else:
		_build_procedural_car(color)


func _strip_proxy_collision(node: Node) -> void:
	for child in node.get_children():
		if child is StaticBody3D:
			child.queue_free()
		else:
			_strip_proxy_collision(child)


func _build_procedural_car(color: Color) -> void:
	## Compact sedan silhouette — windows, tires, lights, door seams (not a colored brick).
	var body_dark := color.darkened(0.12)
	var trim := Color(0.18, 0.18, 0.2)
	StylizedMesh.add_box(_visual, Vector3(1.85, 0.42, 3.7), color, Vector3(0, 0.42, 0), "Body", false)
	StylizedMesh.add_box(_visual, Vector3(1.75, 0.18, 3.55), body_dark, Vector3(0, 0.22, 0), "Rocker")
	StylizedMesh.add_box(_visual, Vector3(1.55, 0.55, 1.85), color.lightened(0.06), Vector3(0, 0.92, -0.15), "Cabin")
	## Hood / trunk shelves.
	StylizedMesh.add_box(_visual, Vector3(1.7, 0.12, 0.85), color.darkened(0.05), Vector3(0, 0.68, 1.15), "Hood")
	StylizedMesh.add_box(_visual, Vector3(1.65, 0.12, 0.7), color.darkened(0.08), Vector3(0, 0.68, -1.35), "Trunk")
	## Grille + bumper.
	StylizedMesh.add_box(_visual, Vector3(1.2, 0.28, 0.1), trim, Vector3(0, 0.42, 1.88), "Grille")
	StylizedMesh.add_box(_visual, Vector3(1.9, 0.16, 0.18), Color(0.28, 0.28, 0.3), Vector3(0, 0.28, 1.92), "BumperF")
	StylizedMesh.add_box(_visual, Vector3(1.9, 0.16, 0.18), Color(0.28, 0.28, 0.3), Vector3(0, 0.28, -1.92), "BumperR")
	## Door seam lines.
	StylizedMesh.add_box(_visual, Vector3(0.03, 0.35, 1.1), trim.lightened(0.15), Vector3(-0.93, 0.55, 0.15), "DoorSeamL")
	StylizedMesh.add_box(_visual, Vector3(0.03, 0.35, 1.1), trim.lightened(0.15), Vector3(0.93, 0.55, 0.15), "DoorSeamR")
	StylizedMesh.add_box(_visual, Vector3(0.08, 0.08, 0.08), WorldPalette.FLOWER_Y, Vector3(-0.95, 0.55, 0.55), "HandleL")
	StylizedMesh.add_box(_visual, Vector3(0.08, 0.08, 0.08), WorldPalette.FLOWER_Y, Vector3(0.95, 0.55, 0.55), "HandleR")
	## Glass — windshield, rear, sides.
	_add_car_glass(Vector3(1.4, 0.42, 0.06), Vector3(0, 0.98, 0.78), "Windshield")
	_add_car_glass(Vector3(1.35, 0.38, 0.06), Vector3(0, 0.98, -1.05), "RearGlass")
	_add_car_glass(Vector3(0.06, 0.36, 1.2), Vector3(-0.8, 0.95, -0.1), "SideGlassL")
	_add_car_glass(Vector3(0.06, 0.36, 1.2), Vector3(0.8, 0.95, -0.1), "SideGlassR")
	## Interior seats (read through glass).
	StylizedMesh.add_box(_visual, Vector3(0.55, 0.28, 0.45), Color(0.22, 0.22, 0.28), Vector3(-0.35, 0.72, 0.15), "SeatL")
	StylizedMesh.add_box(_visual, Vector3(0.55, 0.28, 0.45), Color(0.22, 0.22, 0.28), Vector3(0.35, 0.72, 0.15), "SeatR")
	StylizedMesh.add_box(_visual, Vector3(1.1, 0.08, 0.35), Color(0.15, 0.15, 0.18), Vector3(0, 0.7, 0.55), "Dash")
	## Tires + hubcaps.
	for wp in [Vector3(-0.92, 0.28, 1.15), Vector3(0.92, 0.28, 1.15), Vector3(-0.92, 0.28, -1.15), Vector3(0.92, 0.28, -1.15)]:
		StylizedMesh.add_box(_visual, Vector3(0.28, 0.48, 0.48), Color(0.08, 0.08, 0.08), wp, "Tire")
		StylizedMesh.add_box(_visual, Vector3(0.12, 0.22, 0.22), Color(0.55, 0.55, 0.58), wp + Vector3(0.1 if wp.x > 0.0 else -0.1, 0, 0), "Hub")
	## Lights.
	var head := WorldPalette.LAMP_GLOW
	var tail := Color(0.85, 0.15, 0.12)
	StylizedMesh.add_box(_visual, Vector3(0.28, 0.14, 0.12), head, Vector3(-0.65, 0.48, 1.88), "HeadL")
	StylizedMesh.add_box(_visual, Vector3(0.28, 0.14, 0.12), head, Vector3(0.65, 0.48, 1.88), "HeadR")
	StylizedMesh.add_box(_visual, Vector3(0.32, 0.12, 0.1), tail, Vector3(-0.65, 0.5, -1.88), "TailL")
	StylizedMesh.add_box(_visual, Vector3(0.32, 0.12, 0.1), tail, Vector3(0.65, 0.5, -1.88), "TailR")
	## Mirrors + plate.
	StylizedMesh.add_box(_visual, Vector3(0.18, 0.1, 0.22), trim, Vector3(-1.0, 0.85, 0.55), "MirrorL")
	StylizedMesh.add_box(_visual, Vector3(0.18, 0.1, 0.22), trim, Vector3(1.0, 0.85, 0.55), "MirrorR")
	StylizedMesh.add_box(_visual, Vector3(0.45, 0.14, 0.04), Color(0.9, 0.9, 0.88), Vector3(0, 0.38, -1.98), "Plate")


func _add_car_glass(size: Vector3, pos: Vector3, node_name: String) -> void:
	var win := MeshInstance3D.new()
	win.name = node_name
	var wm := BoxMesh.new()
	wm.size = size
	win.mesh = wm
	win.material_override = StylizedMesh.make_glass_material()
	win.position = pos
	_visual.add_child(win)


func _decorate_vehicle_accents(color: Color) -> void:
	## Light / plate overlays on GLB bodies so fleet cars aren't flat silhouettes.
	var accents := Node3D.new()
	accents.name = "DetailAccents"
	_visual.add_child(accents)
	StylizedMesh.add_box(accents, Vector3(0.22, 0.1, 0.08), WorldPalette.LAMP_GLOW, Vector3(-0.55, 0.45, 1.75), "HeadL")
	StylizedMesh.add_box(accents, Vector3(0.22, 0.1, 0.08), WorldPalette.LAMP_GLOW, Vector3(0.55, 0.45, 1.75), "HeadR")
	StylizedMesh.add_box(accents, Vector3(0.28, 0.1, 0.08), Color(0.85, 0.15, 0.12), Vector3(-0.55, 0.48, -1.75), "TailL")
	StylizedMesh.add_box(accents, Vector3(0.28, 0.1, 0.08), Color(0.85, 0.15, 0.12), Vector3(0.55, 0.48, -1.75), "TailR")
	StylizedMesh.add_box(accents, Vector3(0.4, 0.12, 0.04), Color(0.92, 0.92, 0.9), Vector3(0, 0.35, -1.85), "Plate")
	## Subtle body stripe for variety without fighting GLB materials.
	StylizedMesh.add_box(accents, Vector3(1.7, 0.06, 0.04), color.lightened(0.2), Vector3(0, 0.55, 0.2), "Stripe")


func _ensure_enter_pad() -> void:
	if has_node("EnterPad"):
		_enter_pad = $EnterPad as VehicleEnterInteractable
		return
	_enter_pad = VehicleEnterInteractable.new()
	_enter_pad.name = "EnterPad"
	_enter_pad.position = Vector3(0, 0.6, 0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 2.0, 4.6)
	shape.shape = box
	_enter_pad.add_child(shape)
	add_child(_enter_pad)
	_enter_pad.bind_vehicle(self)
