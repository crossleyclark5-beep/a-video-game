class_name BuildingFloor
extends Node3D
## One story inside a building. Works for ground, upper floors, basements, skyscraper levels.
## Visibility is driven by BuildingInteriorController so only the occupied floor reads clearly.

enum FloorState {
	ACTIVE,   ## Player is here — fully visible
	BELOW,    ## Lower story — hidden (keeps collision off so you don't fall through ghosts)
	ABOVE,    ## Higher story — hidden until you climb
	HIDDEN,   ## Forced off
}

@export var floor_index: int = 0
@export var floor_name: String = "Ground Floor"
@export var spawn_marker: Marker3D
@export var floor_height: float = 3.2  ## Typical story rise (used when stacking procedurally)

var _state: FloorState = FloorState.ACTIVE
var _collision_cache: Array[CollisionObject3D] = []


func _ready() -> void:
	add_to_group(&"building_floors")
	_cache_colliders()


func get_spawn_position() -> Vector3:
	if spawn_marker:
		return spawn_marker.global_position
	return global_position + Vector3(0, 0.15, 0)


func get_focus_height() -> float:
	## World Y the camera should frame for this story.
	return global_position.y + 0.2


func get_floor_state() -> FloorState:
	return _state


func set_floor_state(state: FloorState) -> void:
	_state = state
	## Refresh after late-built interior meshes (visuals often spawn in parent _ready).
	_cache_colliders()
	match state:
		FloorState.ACTIVE:
			visible = true
			_set_physics_enabled(true)
		FloorState.BELOW, FloorState.ABOVE, FloorState.HIDDEN:
			visible = false
			_set_physics_enabled(false)


func _cache_colliders() -> void:
	_collision_cache.clear()
	_gather_colliders(self)


func _gather_colliders(node: Node) -> void:
	if node is StaticBody3D or node is AnimatableBody3D:
		_collision_cache.append(node as CollisionObject3D)
	for child in node.get_children():
		_gather_colliders(child)


func _set_physics_enabled(enabled: bool) -> void:
	if _collision_cache.is_empty():
		_cache_colliders()
	for body in _collision_cache:
		if is_instance_valid(body):
			body.collision_layer = 1 if enabled else 0
	## Stairs / chests / signs on this floor only work when the floor is active.
	for child in find_children("*", "Area3D", true, false):
		if child is Interactable:
			(child as Interactable).enabled = enabled
