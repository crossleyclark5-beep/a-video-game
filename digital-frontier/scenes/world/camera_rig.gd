extends Node3D
## Smooth follow camera for 2.5D top-down adventure.

@export var follow_distance := Vector3(0.0, 14.0, 14.0)
@export var follow_smoothing := 8.0
@export var look_at_offset := Vector3(0.0, 0.5, 0.0)

var _target: Node3D = null
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if not players.is_empty():
		_target = players[0] as Node3D
		if _target != null:
			global_position = _target.global_position + follow_distance
			_camera.look_at(_target.global_position + look_at_offset, Vector3.UP)


func set_target(target: Node3D) -> void:
	_target = target


func _process(delta: float) -> void:
	if _target == null:
		_find_player()
		return

	var desired := _target.global_position + follow_distance
	global_position = global_position.lerp(desired, clampf(follow_smoothing * delta, 0.0, 1.0))
	_camera.look_at(_target.global_position + look_at_offset, Vector3.UP)
