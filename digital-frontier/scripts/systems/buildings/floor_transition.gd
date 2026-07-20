class_name FloorTransition
extends Interactable
## Stairs / ladder interactable that moves the player between BuildingFloor levels.

@export var target_floor_index: int = 1
@export var target_spawn: Marker3D
@export var going_up: bool = true


func _ready() -> void:
	super._ready()
	if target_spawn == null:
		for child in get_children():
			if child is Marker3D:
				target_spawn = child
				break
	prompt_verb = "Go upstairs" if going_up else "Go downstairs"


func _on_interact(actor: Node) -> void:
	if not (actor is Node3D):
		return
	var spawn := global_position + Vector3(0, 3.2 if going_up else -3.2, 0)
	if target_spawn:
		spawn = target_spawn.global_position
	var controllers := get_tree().get_nodes_in_group(&"building_interior_controller")
	if not controllers.is_empty() and controllers[0].has_method("go_to_floor"):
		controllers[0].call("go_to_floor", target_floor_index, actor, spawn)
	else:
		(actor as Node3D).global_position = spawn
