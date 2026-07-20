class_name BuildingFloor
extends Node3D
## One floor inside a building (ground=0, upstairs=1+, basement=-1).

@export var floor_index: int = 0
@export var floor_name: String = "Ground Floor"
@export var spawn_marker: Marker3D


func get_spawn_position() -> Vector3:
	if spawn_marker:
		return spawn_marker.global_position
	return global_position + Vector3(0, 0.15, 0)
