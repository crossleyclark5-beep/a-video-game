class_name HomeStation
extends Area3D
## Interactive care station inside the habitat (bowl / bed / toy / train).
## Click or activate to care for the companion — modular for decor skins later.

signal station_activated(station_id: StringName, care_action: StringName)

@export var station_id: StringName = &"food"
@export var care_action: StringName = &"feed"
@export var prompt_text: String = "Care"
@export var enabled: bool = true

var _hovered: bool = false


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 16
	collision_mask = 0
	input_ray_pickable = true
	add_to_group(&"home_stations")
	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.55
		col.shape = shape
		col.position = Vector3(0, 0.3, 0)
		add_child(col)


func _input_event(_camera: Camera3D, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activate()


func activate() -> Dictionary:
	if not enabled:
		return {}
	var message := ""
	match care_action:
		&"feed":
			message = CreatureManager.feed()
		&"rest":
			message = CreatureManager.rest()
		&"play":
			message = CreatureManager.play()
		&"train":
			message = CreatureManager.train()
		_:
			message = "Nothing happened."
	station_activated.emit(station_id, care_action)
	EventBus.ui_notification_requested.emit(message, 2.5)
	return {"message": message, "action": care_action, "station": station_id}


func get_prompt_text() -> String:
	return prompt_text
