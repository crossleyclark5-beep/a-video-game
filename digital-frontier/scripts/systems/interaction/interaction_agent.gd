class_name InteractionAgent
extends Area3D
## Mount on the player. Detects nearby Interactables and handles the interact action.

signal focus_changed(interactable: Interactable)
signal interaction_performed(interactable: Interactable)

var _nearby: Array[Interactable] = []
var _focus: Interactable = null
var _actor: Node = null


func _ready() -> void:
	_actor = get_parent()
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 16  ## detect interactables
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		try_interact()
		get_viewport().set_input_as_handled()


func try_interact() -> bool:
	_refresh_focus()
	if _focus == null:
		return false
	if not _focus.can_interact(_actor):
		return false
	_focus.interact(_actor)
	interaction_performed.emit(_focus)
	_refresh_focus()
	return true


func get_focus() -> Interactable:
	return _focus


func get_prompt_text() -> String:
	if _focus == null:
		return ""
	return _focus.get_prompt_text()


func _on_area_entered(area: Area3D) -> void:
	if area is Interactable:
		var interactable := area as Interactable
		if not _nearby.has(interactable):
			_nearby.append(interactable)
		_refresh_focus()


func _on_area_exited(area: Area3D) -> void:
	if area is Interactable:
		_nearby.erase(area)
		_refresh_focus()


func _refresh_focus() -> void:
	var best: Interactable = null
	var best_dist := INF
	var origin := global_position
	for item in _nearby:
		if item == null or not is_instance_valid(item):
			continue
		if not item.can_interact(_actor):
			continue
		var d := origin.distance_squared_to(item.global_position)
		if d < best_dist:
			best_dist = d
			best = item
	if best != _focus:
		_focus = best
		focus_changed.emit(_focus)
