extends Node3D
## Polished angled top-down camera for miniature 2.5D exploration.
## Smooth follow, look-ahead, and zoom (mouse wheel / +/-).

@export var follow_distance := Vector3(0.0, 18.0, 18.0)
@export var follow_smoothing := 6.5
@export var look_ahead := 2.2
@export var look_at_offset := Vector3(0.0, 0.6, 0.0)
@export var default_zoom := 16.0
@export var min_zoom := 10.0
@export var max_zoom := 26.0
@export var zoom_step := 1.5
@export var zoom_smoothing := 8.0

var _target: Node3D = null
var _target_zoom: float = 16.0
var _look_ahead_offset := Vector3.ZERO

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_target_zoom = default_zoom
	if _camera:
		_camera.size = default_zoom
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if not players.is_empty():
		set_target(players[0] as Node3D)


func set_target(target: Node3D) -> void:
	_target = target
	if _target != null and _camera != null:
		global_position = _target.global_position + follow_distance
		_camera.look_at(_target.global_position + look_at_offset, Vector3.UP)


func set_zoom_size(size: float, immediate: bool = false) -> void:
	_target_zoom = clampf(size, min_zoom, max_zoom)
	if immediate and _camera:
		_camera.size = _target_zoom


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom_size(_target_zoom - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom_size(_target_zoom + zoom_step)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			set_zoom_size(_target_zoom - zoom_step)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			set_zoom_size(_target_zoom + zoom_step)


func _process(delta: float) -> void:
	if _target == null:
		_find_player()
		return
	if _camera == null:
		return

	# Soft look-ahead in movement direction.
	var vel := Vector3.ZERO
	if _target is CharacterBody3D:
		vel = (_target as CharacterBody3D).velocity
	var flat := Vector3(vel.x, 0.0, vel.z)
	var desired_look := flat.normalized() * look_ahead if flat.length() > 0.4 else Vector3.ZERO
	_look_ahead_offset = _look_ahead_offset.lerp(desired_look, clampf(4.0 * delta, 0.0, 1.0))

	var focus := _target.global_position + _look_ahead_offset
	var desired_pos := focus + follow_distance
	global_position = global_position.lerp(desired_pos, clampf(follow_smoothing * delta, 0.0, 1.0))
	_camera.look_at(focus + look_at_offset, Vector3.UP)

	_camera.size = lerpf(_camera.size, _target_zoom, clampf(zoom_smoothing * delta, 0.0, 1.0))
