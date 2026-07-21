class_name AircraftPadInteractable
extends Interactable
## Field Skiff hangar pad — unlock, pick a hub, and arc-hop across Grassland.


@export var vehicle_id: StringName = &"field_skiff"
@export var pad_label: String = "Field Hangar"

var _selecting: bool = false
var _dest_index: int = 0
var _nearby_actor: Node = null


func _ready() -> void:
	super._ready()
	once = false
	prompt_verb = "Board Field Skiff"
	_refresh_prompt()


func _process(_delta: float) -> void:
	if not _selecting:
		return
	if InputManager.is_action_just_pressed(&"ui_cancel"):
		_cancel_select()
		return
	if InputManager.is_action_just_pressed(&"ui_left") or InputManager.is_action_just_pressed(&"move_left"):
		_cycle(-1)
	elif InputManager.is_action_just_pressed(&"ui_right") or InputManager.is_action_just_pressed(&"move_right"):
		_cycle(1)


func can_interact(actor: Node) -> bool:
	if VehicleManager.is_traveling():
		return false
	return super.can_interact(actor)


func _on_interact(actor: Node) -> void:
	_nearby_actor = actor
	if not VehicleManager.is_unlocked(vehicle_id):
		VehicleManager.unlock(vehicle_id, true)
	if not _selecting:
		_begin_select()
		return
	_confirm_flight(actor)


func _begin_select() -> void:
	_selecting = true
	_dest_index = 0
	InputManager.push_context(InputManager.Context.MENU)
	_announce_destination()
	prompt_verb = "Fly here"
	_refresh_prompt()


func _cancel_select() -> void:
	_selecting = false
	if InputManager.get_context() == InputManager.Context.MENU:
		InputManager.pop_context()
	prompt_verb = "Board Field Skiff"
	_refresh_prompt()
	EventBus.ui_notification_requested.emit("Stay on the pad.", 1.4)


func _cycle(dir: int) -> void:
	var dests := AircraftTravelCatalog.destinations()
	if dests.is_empty():
		return
	_dest_index = (_dest_index + dir) % dests.size()
	if _dest_index < 0:
		_dest_index = dests.size() - 1
	_announce_destination()


func _announce_destination() -> void:
	var dests := AircraftTravelCatalog.destinations()
	if dests.is_empty():
		return
	var d: Dictionary = dests[_dest_index]
	EventBus.ui_notification_requested.emit(
		"Course: %s  (%d/%d) · A fly · B cancel" % [String(d["label"]), _dest_index + 1, dests.size()],
		2.4,
	)


func _confirm_flight(actor: Node) -> void:
	var dests := AircraftTravelCatalog.destinations()
	if dests.is_empty():
		_cancel_select()
		return
	var d: Dictionary = dests[_dest_index]
	var target: Vector3 = d["pos"]
	## Don't hop to the pad you're already on.
	if actor is Node3D and (actor as Node3D).global_position.distance_to(target) < 40.0:
		EventBus.ui_notification_requested.emit("Already near %s." % String(d["label"]), 1.8)
		_cycle(1)
		return
	_selecting = false
	if InputManager.get_context() == InputManager.Context.MENU:
		InputManager.pop_context()
	prompt_verb = "Board Field Skiff"
	_refresh_prompt()
	if actor is Node3D:
		VehicleManager.fly_to(actor as Node3D, target, vehicle_id)


func _refresh_prompt() -> void:
	pass


static func build_pad(parent: Node3D, pos: Vector3, yaw: float = 0.0, pad_name: String = "FieldHangar") -> AircraftPadInteractable:
	var root := Node3D.new()
	root.name = pad_name
	root.position = pos
	root.rotation_degrees.y = yaw
	parent.add_child(root)
	StylizedMesh.add_box(root, Vector3(8.0, 0.08, 8.0), WorldPalette.SIDEWALK.darkened(0.05), Vector3(0, 0.05, 0), "PadDeck", true, 1.0, &"asphalt")
	StylizedMesh.add_box(root, Vector3(6.5, 0.04, 0.35), WorldPalette.FLOWER_Y, Vector3(0, 0.1, 0), "Stripe")
	if ExternalPropKit.is_available():
		ExternalPropKit.spawn(root, &"hangar_small", Vector3(-4.5, 0, -1.5), 90.0, 1.15, "Hangar")
		ExternalPropKit.spawn(root, &"craft_speeder", Vector3(1.2, 0, 0.5), -25.0, 1.25, "ParkedSkiff")
		ExternalPropKit.spawn(root, &"barrel", Vector3(-2.2, 0, 2.8), 10.0, 1.0, "FuelBarrel")
		ExternalPropKit.spawn(root, &"supply_crate", Vector3(3.5, 0, -2.5), -15.0, 1.0, "Supply")
	else:
		StylizedMesh.add_box(root, Vector3(3.5, 2.2, 4.0), Color(0.55, 0.6, 0.68), Vector3(-4.0, 1.1, -1.0), "HangarShell", true)
		StylizedMesh.add_box(root, Vector3(2.4, 0.55, 3.2), Color(0.35, 0.55, 0.85), Vector3(1.2, 0.55, 0.5), "SkiffHull", true)
	var pad := AircraftPadInteractable.new()
	pad.name = "BoardPad"
	pad.position = Vector3(1.0, 0.5, 1.5)
	pad.pad_label = "Field Hangar"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.5, 2.5, 4.5)
	shape.shape = box
	pad.add_child(shape)
	root.add_child(pad)
	var sign := Label3D.new()
	sign.text = "FIELD SKIFF"
	sign.font_size = 42
	sign.position = Vector3(0, 2.8, 3.2)
	sign.modulate = WorldPalette.UI_PAPER
	root.add_child(sign)
	return pad
