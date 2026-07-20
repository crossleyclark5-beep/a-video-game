extends Node3D
## Adventure world — Pleasant Park with modular interaction + building systems.

@onready var hex_grid_layer: Node3D = $HexGridLayer
@onready var building_layer: Node3D = $BuildingLayer
@onready var entity_layer: Node3D = $EntityLayer
@onready var camera_rig: Node3D = $CameraRig
@onready var hint_label: Label = %HintLabel
@onready var toast_label: Label = %ToastLabel

var _region_data: Dictionary = {}
var _player: Node3D = null
var _interior_controller: BuildingInteriorController = null
var _interaction_prompt: Control = null
var _toast_timer: float = 0.0


func _ready() -> void:
	InputManager.set_context(InputManager.Context.OVERWORLD)
	_clear_placeholder_geometry()
	_setup_systems()
	_region_data = PleasantParkBuilder.build(hex_grid_layer)
	EventBus.region_load_requested.emit(&"pleasant_park")
	_spawn_player()
	_bind_prompt()
	EventBus.ui_notification_requested.connect(_on_notification)
	_refresh_default_hint()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and toast_label:
			toast_label.visible = false


func _clear_placeholder_geometry() -> void:
	for child in hex_grid_layer.get_children():
		child.queue_free()


func _setup_systems() -> void:
	var interior_root := Node3D.new()
	interior_root.name = "InteriorContainer"
	building_layer.add_child(interior_root)
	_interior_controller = BuildingInteriorController.new()
	_interior_controller.name = "BuildingInteriorController"
	add_child(_interior_controller)
	_interior_controller.setup(camera_rig, interior_root)

	var prompt_scene: PackedScene = load("res://scenes/ui/components/interaction_prompt.tscn")
	if prompt_scene and has_node("HUD"):
		_interaction_prompt = prompt_scene.instantiate()
		$HUD.add_child(_interaction_prompt)


func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	if player_scene == null:
		push_error("GameWorld: missing player.tscn")
		return
	_player = player_scene.instantiate()
	_player.name = "Player"
	entity_layer.add_child(_player)
	var spawn: Vector3 = _region_data.get(&"player_spawn", Vector3(0.0, 0.15, 10.0))
	_player.global_position = spawn
	if camera_rig.has_method("set_target"):
		camera_rig.call("set_target", _player)


func _bind_prompt() -> void:
	if _player == null or _interaction_prompt == null:
		return
	if _player.has_method("get_interaction_agent"):
		var agent: InteractionAgent = _player.call("get_interaction_agent")
		if agent and _interaction_prompt.has_method("bind_agent"):
			_interaction_prompt.call("bind_agent", agent)


func _on_notification(message: String, duration: float) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	toast_label.visible = true
	_toast_timer = duration


func _refresh_default_hint() -> void:
	if hint_label:
		hint_label.text = "WASD move · Shift run · E/A interact · scroll zoom · H home"
