extends BaseManager
## Vehicle ownership, mounting, and Field Skiff air hops.


var _unlocked: Dictionary = {}  ## vehicle_id -> true
var _active_vehicle_id: StringName = &""
var _traveling: bool = false


func _initialize_manager() -> void:
	_log("VehicleManager initialized")


func is_unlocked(vehicle_id: StringName) -> bool:
	return _unlocked.has(vehicle_id)


func unlock(vehicle_id: StringName, announce: bool = true) -> void:
	if _unlocked.has(vehicle_id):
		return
	_unlocked[vehicle_id] = true
	if announce:
		var data: VehicleData = ResourceRegistry.get_vehicle(vehicle_id)
		var label := data.display_name if data else String(vehicle_id)
		EventBus.ui_notification_requested.emit("Unlocked: %s" % label, 2.6)


func get_active_vehicle_id() -> StringName:
	return _active_vehicle_id


func is_traveling() -> bool:
	return _traveling


func enter_vehicle(vehicle_id: StringName) -> void:
	if not is_unlocked(vehicle_id):
		unlock(vehicle_id, false)
	_active_vehicle_id = vehicle_id
	InputManager.push_context(InputManager.Context.VEHICLE)
	EventBus.vehicle_entered.emit(vehicle_id)


func exit_vehicle() -> void:
	var previous := _active_vehicle_id
	_active_vehicle_id = &""
	if InputManager.get_context() == InputManager.Context.VEHICLE:
		InputManager.pop_context()
	if previous != &"":
		EventBus.vehicle_exited.emit(previous)


## Arc hop between Grassland hubs. Keeps one continuous scene (no region reload).
func fly_to(player: Node3D, destination: Vector3, vehicle_id: StringName = &"field_skiff") -> void:
	if player == null or _traveling:
		return
	if not is_unlocked(vehicle_id):
		unlock(vehicle_id, true)
	_traveling = true
	enter_vehicle(vehicle_id)
	var body := player as CharacterBody3D
	if body:
		body.velocity = Vector3.ZERO
		body.set_physics_process(false)
	var craft := _spawn_craft_visual(player)
	var start := player.global_position
	var end := destination + Vector3(0, 0.2, 0)
	var mid := (start + end) * 0.5 + Vector3(0, clampf(start.distance_to(end) * 0.18, 12.0, 80.0), 0)
	var duration := clampf(start.distance_to(end) / 420.0, 1.4, 4.2)
	EventBus.ui_notification_requested.emit("Field Skiff departing…", 1.6)
	EventBus.sfx_play_requested.emit(&"vehicle_launch", start)
	var tween := player.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_flight_step.bind(player, craft, start, mid, end), 0.0, 1.0, duration)
	tween.finished.connect(_flight_finished.bind(player, body, craft, end))


func _flight_step(t: float, player: Node3D, craft: Node3D, start: Vector3, mid: Vector3, end: Vector3) -> void:
	var p := _bezier(start, mid, end, t)
	player.global_position = p
	if craft and is_instance_valid(craft):
		craft.global_position = p + Vector3(0, 0.6, 0)
		var look := _bezier(start, mid, end, mini(t + 0.02, 1.0)) - p
		if look.length_squared() > 0.01:
			craft.look_at(p + look, Vector3.UP)


func _flight_finished(player: Node3D, body: CharacterBody3D, craft: Node3D, end: Vector3) -> void:
	player.global_position = end
	WorldManager.set_player_checkpoint(end)
	if craft and is_instance_valid(craft):
		craft.queue_free()
	if body:
		body.set_physics_process(true)
	exit_vehicle()
	_traveling = false
	EventBus.ui_notification_requested.emit("Touchdown.", 1.8)
	EventBus.sfx_play_requested.emit(&"vehicle_land", end)


func _spawn_craft_visual(player: Node3D) -> Node3D:
	var parent := player.get_parent() as Node3D
	if parent == null:
		return null
	if ExternalPropKit.is_available():
		var n := ExternalPropKit.spawn(parent, &"craft_speeder", player.global_position, player.rotation_degrees.y, 1.2, "FieldSkiffFlight")
		if n:
			n.top_level = true
			return n
	var fallback := Node3D.new()
	fallback.name = "FieldSkiffFlight"
	fallback.top_level = true
	fallback.global_position = player.global_position
	parent.add_child(fallback)
	StylizedMesh.add_box(fallback, Vector3(2.4, 0.55, 3.2), Color(0.35, 0.55, 0.85), Vector3(0, 0.4, 0), "Hull")
	StylizedMesh.add_box(fallback, Vector3(1.2, 0.45, 1.4), Color(0.55, 0.75, 0.95), Vector3(0, 0.85, -0.2), "Canopy")
	return fallback


func _bezier(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return u * u * a + 2.0 * u * t * b + t * t * c


func export_state() -> Dictionary:
	return {
		&"unlocked": _unlocked.duplicate(),
		&"active_vehicle_id": _active_vehicle_id,
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"unlocked"):
		_unlocked = data[&"unlocked"].duplicate()
	if data.has(&"active_vehicle_id"):
		_active_vehicle_id = data[&"active_vehicle_id"]


func reset_state() -> void:
	_unlocked.clear()
	_active_vehicle_id = &""
	_traveling = false
