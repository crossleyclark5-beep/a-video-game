extends Node3D
## Starter adventure region shell — Phase 1 playable spine.
## One simple grasslands floor, player spawn, follow camera.

@onready var entity_layer: Node3D = $EntityLayer
@onready var camera_rig: Node3D = $CameraRig


func _ready() -> void:
	InputManager.set_context(InputManager.Context.OVERWORLD)
	EventBus.region_load_requested.emit(&"starter_plains")
	_spawn_player()
	print("[GameWorld] WASD/Arrows = move | H = Home")


func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	if player_scene == null:
		push_error("GameWorld: missing player.tscn")
		return
	var player: Node3D = player_scene.instantiate()
	player.name = "Player"
	entity_layer.add_child(player)
	player.global_position = Vector3(0.0, 0.1, 0.0)
	if camera_rig.has_method("set_target"):
		camera_rig.call("set_target", player)
