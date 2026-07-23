class_name WorldInspectController
extends Node
## Temporary developer World Inspection Mode — free 3D camera + review overlays.
## Not a player feature. Gated by GameConfig.enable_cheats (debug builds).
##
## Toggle: F3 (or inspect_toggle action)
## Exit: F3 / Esc
## See docs/WORLD_INSPECT_MODE.md for controls + checklist.


signal mode_changed(active: bool)
signal overlay_changed(overlay_id: StringName, enabled: bool)
signal placement_scan_finished(issue_count: int)

const GROUP := &"world_inspect"

enum Overlay {
	GRID,
	HEIGHT,
	OBJECT_INFO,
	COLLISION,
	SCALE,
	PLACEMENT,
	PERF,
}

var active: bool = false
var _camera: Camera3D = null
var _rig: Node3D = null
var _gameplay_camera: Camera3D = null
var _yaw: float = 0.0
var _pitch: float = -0.45
var _move_speed: float = 48.0
var _look_sensitivity: float = 0.0032
var _fov: float = 70.0
var _mouse_look: bool = false
var _overlays: WorldInspectOverlays = null
var _placement: WorldInspectPlacement = null
var _hud: WorldInspectHud = null
var _overlay_flags: Dictionary = {
	Overlay.GRID: false,
	Overlay.HEIGHT: false,
	Overlay.OBJECT_INFO: true,
	Overlay.COLLISION: false,
	Overlay.SCALE: false,
	Overlay.PLACEMENT: false,
	Overlay.PERF: true,
}
var _rig_was_processing: bool = true
var _perf: WorldPerfMonitor = null
var _perf_world_root: Node = null


func _ready() -> void:
	add_to_group(GROUP)
	name = "WorldInspectController"
	set_process(false)
	set_process_unhandled_input(true)
	_overlays = WorldInspectOverlays.new()
	_overlays.name = "Overlays"
	add_child(_overlays)
	_placement = WorldInspectPlacement.new()
	_placement.name = "PlacementReview"
	add_child(_placement)
	_hud = WorldInspectHud.new()
	_hud.name = "InspectHud"
	add_child(_hud)
	_hud.visible = false


func setup(camera_rig: Node3D) -> void:
	_rig = camera_rig
	if _rig and _rig.has_node("Camera3D"):
		_gameplay_camera = _rig.get_node("Camera3D") as Camera3D


func bind_perf_monitor(perf: WorldPerfMonitor, world_root: Node) -> void:
	_perf = perf
	_perf_world_root = world_root
	if _hud:
		_hud.bind_perf(perf, world_root)


func is_active() -> bool:
	return active


func can_enter() -> bool:
	if not GameConfig.enable_cheats:
		return false
	var ctx := InputManager.get_context()
	if ctx == InputManager.Context.COMBAT or ctx == InputManager.Context.MENU:
		return false
	if ctx == InputManager.Context.WORLD_INSPECT:
		return true
	return ctx == InputManager.Context.OVERWORLD \
		or ctx == InputManager.Context.BUILDING_INTERIOR \
		or ctx == InputManager.Context.VEHICLE


func toggle() -> void:
	if active:
		exit_mode()
	else:
		enter_mode()


func enter_mode() -> void:
	if active or not can_enter():
		return
	if _rig == null:
		var rigs := get_tree().get_nodes_in_group(&"camera_rig")
		if not rigs.is_empty():
			setup(rigs[0] as Node3D)
	if _rig == null or _gameplay_camera == null:
		push_warning("WorldInspect: no CameraRig bound")
		return
	active = true
	InputManager.push_context(InputManager.Context.WORLD_INSPECT)
	_ensure_camera()
	_seed_from_gameplay()
	_rig_was_processing = _rig.is_processing()
	_rig.set_process(false)
	if _rig.has_method("set_inspect_paused"):
		_rig.call("set_inspect_paused", true)
	_camera.make_current()
	_hud.visible = true
	_hud.refresh(self)
	_apply_overlay_state()
	set_process(true)
	mode_changed.emit(true)
	EventBus.debug_command_executed.emit("world_inspect", PackedStringArray(["on"]))
	print("WORLD_INSPECT_ON")


func exit_mode() -> void:
	if not active:
		return
	active = false
	_mouse_look = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _overlays:
		_overlays.clear_all()
	if _placement:
		_placement.clear_highlights()
	if _camera:
		_camera.current = false
	if _gameplay_camera:
		_gameplay_camera.make_current()
	if _rig:
		_rig.set_process(_rig_was_processing)
		if _rig.has_method("set_inspect_paused"):
			_rig.call("set_inspect_paused", false)
	if InputManager.get_context() == InputManager.Context.WORLD_INSPECT:
		InputManager.pop_context()
	_hud.visible = false
	set_process(false)
	mode_changed.emit(false)
	EventBus.debug_command_executed.emit("world_inspect", PackedStringArray(["off"]))
	print("WORLD_INSPECT_OFF")


func set_overlay(overlay: Overlay, enabled: bool) -> void:
	_overlay_flags[overlay] = enabled
	if active:
		_apply_overlay_state()
		_hud.refresh(self)
	overlay_changed.emit(_overlay_name(overlay), enabled)


func is_overlay_on(overlay: Overlay) -> bool:
	return bool(_overlay_flags.get(overlay, false))


func run_placement_scan() -> int:
	if not active:
		return 0
	var count := _placement.scan(get_tree().current_scene if get_tree() else null, _camera.global_position if _camera else Vector3.ZERO)
	set_overlay(Overlay.PLACEMENT, true)
	_hud.set_status("Placement issues: %d (near camera)" % count)
	_hud.refresh(self)
	placement_scan_finished.emit(count)
	return count


func _unhandled_input(event: InputEvent) -> void:
	if not GameConfig.enable_cheats:
		return
	if event.is_action_pressed(&"inspect_toggle"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if event.is_action_pressed(&"ui_cancel"):
		exit_mode()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		match key:
			KEY_1:
				set_overlay(Overlay.GRID, not is_overlay_on(Overlay.GRID))
			KEY_2:
				set_overlay(Overlay.HEIGHT, not is_overlay_on(Overlay.HEIGHT))
			KEY_3:
				set_overlay(Overlay.OBJECT_INFO, not is_overlay_on(Overlay.OBJECT_INFO))
			KEY_4:
				set_overlay(Overlay.COLLISION, not is_overlay_on(Overlay.COLLISION))
			KEY_5:
				set_overlay(Overlay.SCALE, not is_overlay_on(Overlay.SCALE))
			KEY_6:
				run_placement_scan()
			KEY_7:
				set_overlay(Overlay.PERF, not is_overlay_on(Overlay.PERF))
			KEY_F4:
				run_placement_scan()
			KEY_C:
				## Teleport inspect cam above player.
				_snap_above_player()
			KEY_HOME:
				_camera.global_position = Vector3(0, 80, 120)
				_yaw = 0.0
				_pitch = -0.55
				_apply_look()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_mouse_look = mb.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _mouse_look else Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_fov = clampf(_fov - 4.0, 25.0, 110.0)
			_camera.fov = _fov
			get_viewport().set_input_as_handled()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_fov = clampf(_fov + 4.0, 25.0, 110.0)
			_camera.fov = _fov
			get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and _mouse_look:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * _look_sensitivity
		_pitch = clampf(_pitch - mm.relative.y * _look_sensitivity, -1.45, 1.45)
		_apply_look()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not active or _camera == null:
		return
	## Look with arrow keys when mouse not captured (handheld / no-mouse).
	var look := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		look.x += 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		look.x -= 1.0
	if Input.is_key_pressed(KEY_UP):
		look.y += 1.0
	if Input.is_key_pressed(KEY_DOWN):
		look.y -= 1.0
	if look != Vector2.ZERO:
		_yaw += look.x * 1.6 * delta
		_pitch = clampf(_pitch + look.y * 1.2 * delta, -1.45, 1.45)
		_apply_look()

	var speed := _move_speed
	if Input.is_key_pressed(KEY_SHIFT) or InputManager.is_action_pressed(&"run"):
		speed *= 4.0
	if Input.is_key_pressed(KEY_ALT):
		speed *= 0.25

	var wish := Vector3.ZERO
	var basis_yaw := Basis(Vector3.UP, _yaw)
	var forward := -basis_yaw.z
	var right := basis_yaw.x
	if InputManager.is_action_pressed(&"move_forward"):
		wish += forward
	if InputManager.is_action_pressed(&"move_back"):
		wish -= forward
	if InputManager.is_action_pressed(&"move_right"):
		wish += right
	if InputManager.is_action_pressed(&"move_left"):
		wish -= right
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE):
		wish += Vector3.UP
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_CTRL):
		wish -= Vector3.UP
	if wish != Vector3.ZERO:
		_camera.global_position += wish.normalized() * speed * delta

	if is_overlay_on(Overlay.OBJECT_INFO) or is_overlay_on(Overlay.SCALE):
		_overlays.update_pick(_camera, is_overlay_on(Overlay.OBJECT_INFO), is_overlay_on(Overlay.SCALE))
	if is_overlay_on(Overlay.HEIGHT):
		_overlays.update_height_field(_camera.global_position)
	if is_overlay_on(Overlay.GRID):
		_overlays.update_grid(_camera.global_position)
	if is_overlay_on(Overlay.COLLISION):
		_overlays.update_collision(_camera.global_position)

	_hud.update_readout(self, _camera)


func _ensure_camera() -> void:
	if _camera != null and is_instance_valid(_camera):
		return
	_camera = Camera3D.new()
	_camera.name = "InspectCamera"
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = _fov
	_camera.near = 0.15
	_camera.far = 20000.0
	add_child(_camera)


func _seed_from_gameplay() -> void:
	var origin := _gameplay_camera.global_position
	var looking := origin + _gameplay_camera.global_transform.basis.z * -20.0
	## Start slightly above / behind the ortho view for an immediate aerial read.
	_camera.global_position = origin + Vector3(0, 18, 24)
	var to := looking - _camera.global_position
	_yaw = atan2(-to.x, -to.z)
	_pitch = asin(clampf(to.normalized().y, -0.99, 0.99))
	_fov = 70.0
	_camera.fov = _fov
	_apply_look()


func _apply_look() -> void:
	if _camera == null:
		return
	_camera.rotation = Vector3(_pitch, _yaw, 0.0)


func _snap_above_player() -> void:
	var players := get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if players.is_empty():
		return
	var p := (players[0] as Node3D).global_position
	_camera.global_position = p + Vector3(0, 40, 30)
	_yaw = 0.0
	_pitch = -0.7
	_apply_look()


func _apply_overlay_state() -> void:
	if is_overlay_on(Overlay.GRID):
		_overlays.enable_grid(true)
	else:
		_overlays.enable_grid(false)
	if is_overlay_on(Overlay.HEIGHT):
		_overlays.enable_height(true)
	else:
		_overlays.enable_height(false)
	if is_overlay_on(Overlay.COLLISION):
		_overlays.enable_collision(true)
	else:
		_overlays.enable_collision(false)
	if not is_overlay_on(Overlay.OBJECT_INFO) and not is_overlay_on(Overlay.SCALE):
		_overlays.clear_pick()
	if not is_overlay_on(Overlay.PLACEMENT):
		_placement.clear_highlights()


func overlay_summary() -> String:
	var parts: PackedStringArray = []
	if is_overlay_on(Overlay.GRID):
		parts.append("Grid")
	if is_overlay_on(Overlay.HEIGHT):
		parts.append("Height")
	if is_overlay_on(Overlay.OBJECT_INFO):
		parts.append("Info")
	if is_overlay_on(Overlay.COLLISION):
		parts.append("Collision")
	if is_overlay_on(Overlay.SCALE):
		parts.append("Scale")
	if is_overlay_on(Overlay.PLACEMENT):
		parts.append("Placement")
	if is_overlay_on(Overlay.PERF):
		parts.append("Perf")
	return ", ".join(parts) if not parts.is_empty() else "none"


func wants_perf() -> bool:
	return is_overlay_on(Overlay.PERF)


static func _overlay_name(overlay: Overlay) -> StringName:
	match overlay:
		Overlay.GRID: return &"grid"
		Overlay.HEIGHT: return &"height"
		Overlay.OBJECT_INFO: return &"object_info"
		Overlay.COLLISION: return &"collision"
		Overlay.SCALE: return &"scale"
		Overlay.PLACEMENT: return &"placement"
		Overlay.PERF: return &"perf"
		_: return &"unknown"
