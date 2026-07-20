extends Node3D
## Polished angled top-down camera for miniature 2.5D exploration.
## Steeper diorama angle, smooth follow, look-ahead, and natural zoom.

@export var follow_distance := Vector3(0.0, 22.0, 16.0)
@export var interior_follow_distance := Vector3(0.0, 16.5, 11.5)
@export var follow_smoothing := 5.5
@export var look_ahead := 2.6
@export var look_at_offset := Vector3(0.0, 0.45, 0.0)
@export var default_zoom := 14.5
@export var min_zoom := 8.0
@export var max_zoom := 24.0
@export var zoom_step := 1.25
@export var zoom_smoothing := 7.0
@export var settle_smoothing := 3.5

var _target: Node3D = null
var _target_zoom: float = 14.5
var _look_ahead_offset := Vector3.ZERO
var _zoom_velocity: float = 0.0
var _interior_mode: bool = false
var _active_follow_distance := Vector3(0.0, 22.0, 16.0)

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_target_zoom = default_zoom
	_active_follow_distance = follow_distance
	if _camera:
		_camera.size = default_zoom
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.near = 0.2
		_camera.far = 280.0
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if not players.is_empty():
		set_target(players[0] as Node3D)


func set_target(target: Node3D) -> void:
	_target = target
	if _target != null and _camera != null:
		global_position = _target.global_position + _active_follow_distance
		_camera.look_at(_target.global_position + look_at_offset, Vector3.UP)


func set_zoom_size(size: float, immediate: bool = false) -> void:
	_target_zoom = clampf(size, min_zoom, max_zoom)
	if immediate and _camera:
		_camera.size = _target_zoom
		_zoom_velocity = 0.0


func set_interior_mode(inside: bool) -> void:
	_interior_mode = inside
	_active_follow_distance = interior_follow_distance if inside else follow_distance


func _unhandled_input(event: InputEvent) -> void:
	## Zoom is optional on handheld — Prefer fixed framing. Keep wheel for PC editor only.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom_size(_target_zoom - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom_size(_target_zoom + zoom_step)


func _process(delta: float) -> void:
	if _target == null:
		_find_player()
		return
	if _camera == null:
		return

	var vel := Vector3.ZERO
	if _target is CharacterBody3D:
		vel = (_target as CharacterBody3D).velocity
	var flat := Vector3(vel.x, 0.0, vel.z)
	var speed_factor := clampf(flat.length() / 6.0, 0.0, 1.0)
	## Less look-ahead indoors so framing stays on the room.
	var ahead_scale := 0.35 if _interior_mode else 1.0
	var desired_look := flat.normalized() * look_ahead * ahead_scale * (0.55 + speed_factor * 0.45) if flat.length() > 0.35 else Vector3.ZERO
	_look_ahead_offset = _look_ahead_offset.lerp(desired_look, clampf(3.8 * delta, 0.0, 1.0))

	var focus := _target.global_position + _look_ahead_offset
	var height_boost := speed_factor * (0.35 if _interior_mode else 0.8)
	var desired_pos := focus + _active_follow_distance + Vector3(0, height_boost, 0)
	var smooth := follow_smoothing if flat.length() > 0.2 else settle_smoothing
	global_position = global_position.lerp(desired_pos, clampf(smooth * delta, 0.0, 1.0))
	_camera.look_at(focus + look_at_offset, Vector3.UP)

	var zoom_diff := _target_zoom - _camera.size
	_zoom_velocity = lerpf(_zoom_velocity, zoom_diff * zoom_smoothing, clampf(10.0 * delta, 0.0, 1.0))
	_camera.size += _zoom_velocity * delta
