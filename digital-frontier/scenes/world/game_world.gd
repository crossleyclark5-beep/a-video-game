extends Node3D
## Adventure world — loads Pleasant Park as the first playable region.

@onready var hex_grid_layer: Node3D = $HexGridLayer
@onready var building_layer: Node3D = $BuildingLayer
@onready var entity_layer: Node3D = $EntityLayer
@onready var camera_rig: Node3D = $CameraRig
@onready var hint_label: Label = %HintLabel

var _region_data: Dictionary = {}
var _nearby_chest: Area3D = null
var _nearby_house: Node3D = null
var _inside_house: Node3D = null
var _player: Node3D = null


func _ready() -> void:
	InputManager.set_context(InputManager.Context.OVERWORLD)
	_clear_placeholder_geometry()
	_region_data = PleasantParkBuilder.build(hex_grid_layer)
	EventBus.region_load_requested.emit(&"pleasant_park")
	_wire_interactables()
	_spawn_player()
	_set_hint("WASD move · E interact · H home · Explore Pleasant Park!")


func _clear_placeholder_geometry() -> void:
	for child in hex_grid_layer.get_children():
		child.queue_free()


func _spawn_player() -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	if player_scene == null:
		push_error("GameWorld: missing player.tscn")
		return
	_player = player_scene.instantiate()
	_player.name = "Player"
	entity_layer.add_child(_player)
	var spawn: Vector3 = _region_data.get(&"player_spawn", Vector3(0.0, 0.15, 8.0))
	_player.global_position = spawn
	if camera_rig.has_method("set_target"):
		camera_rig.call("set_target", _player)


func _wire_interactables() -> void:
	for chest in _region_data.get(&"chests", []):
		if chest is Area3D:
			chest.body_entered.connect(_on_chest_body_entered.bind(chest))
			chest.body_exited.connect(_on_chest_body_exited.bind(chest))
	for house in _region_data.get(&"enterable_houses", []):
		var door: Area3D = house.get_node_or_null("DoorArea")
		if door:
			door.body_entered.connect(_on_door_body_entered.bind(house))
			door.body_exited.connect(_on_door_body_exited.bind(house))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact"):
		return
	if _nearby_chest != null:
		_try_open_chest(_nearby_chest)
		return
	if _inside_house != null:
		_exit_house()
		return
	if _nearby_house != null:
		_enter_house(_nearby_house)


func _on_chest_body_entered(body: Node3D, chest: Area3D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		_nearby_chest = chest
		if not bool(chest.get_meta("opened", false)):
			_set_hint("Press E to open chest")


func _on_chest_body_exited(body: Node3D, chest: Area3D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER) and _nearby_chest == chest:
		_nearby_chest = null
		_refresh_default_hint()


func _on_door_body_entered(body: Node3D, house: Node3D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		_nearby_house = house
		if _inside_house == null:
			_set_hint("Press E to enter %s" % house.name)


func _on_door_body_exited(body: Node3D, house: Node3D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER) and _nearby_house == house:
		_nearby_house = null
		if _inside_house == null:
			_refresh_default_hint()


func _try_open_chest(chest: Area3D) -> void:
	if bool(chest.get_meta("opened", false)):
		_set_hint("Chest already opened")
		return
	chest.set_meta("opened", true)
	var item_id: StringName = chest.get_meta("loot_item", &"hex_shard")
	var qty: int = int(chest.get_meta("loot_qty", 1))
	InventoryManager.add_item(item_id, qty)
	# Dim the chest mesh
	for child in chest.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).modulate = Color(0.4, 0.4, 0.4)
	_set_hint("Found Hex Shard! (Inventory: %d)" % InventoryManager.get_quantity(item_id))
	EventBus.ui_notification_requested.emit("Opened chest — Hex Shard +%d" % qty, 2.0)


func _enter_house(house: Node3D) -> void:
	_inside_house = house
	InputManager.set_context(InputManager.Context.BUILDING_INTERIOR)
	var roof: MeshInstance3D = house.get_meta("roof_node") as MeshInstance3D
	if roof:
		var tween := create_tween()
		tween.tween_property(roof, "modulate:a", 0.0, 0.35)
	# Move player slightly inside
	if _player:
		_player.global_position = house.global_position + Vector3(0.0, 0.15, 0.5)
	# Zoom camera a bit
	if camera_rig.has_method("set_zoom_size"):
		camera_rig.call("set_zoom_size", 12.0)
	elif camera_rig.get_node_or_null("Camera3D"):
		var cam: Camera3D = camera_rig.get_node("Camera3D")
		var tween_cam := create_tween()
		tween_cam.tween_property(cam, "size", 12.0, 0.35)
	_set_hint("Inside %s — press E at the door to leave" % house.name)
	EventBus.building_interior_loaded.emit(StringName(house.name))


func _exit_house() -> void:
	if _inside_house == null:
		return
	var house := _inside_house
	var roof: MeshInstance3D = house.get_meta("roof_node") as MeshInstance3D
	if roof:
		var tween := create_tween()
		tween.tween_property(roof, "modulate:a", 1.0, 0.35)
	if _player:
		_player.global_position = house.global_position + Vector3(0.0, 0.15, 5.0)
	if camera_rig.get_node_or_null("Camera3D"):
		var cam: Camera3D = camera_rig.get_node("Camera3D")
		var tween_cam := create_tween()
		tween_cam.tween_property(cam, "size", 18.0, 0.35)
	_inside_house = null
	InputManager.set_context(InputManager.Context.OVERWORLD)
	_set_hint("Back outside — explore Pleasant Park!")


func _set_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text


func _refresh_default_hint() -> void:
	_set_hint("WASD move · E interact · H home · Explore Pleasant Park!")
