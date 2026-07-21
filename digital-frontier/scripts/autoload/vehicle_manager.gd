extends BaseManager
## Vehicle ownership and active vehicle state.
##
## WHY: Vehicles may be region-locked or quest-gated. This manager tracks unlocked
## vehicles and the currently mounted vehicle without scene coupling.

var _unlocked: Dictionary = {}  ## vehicle_id -> true
var _active_vehicle_id: StringName = &""


func _initialize_manager() -> void:
	_log("VehicleManager initialized")


func is_unlocked(vehicle_id: StringName) -> bool:
	return _unlocked.has(vehicle_id)


func get_active_vehicle_id() -> StringName:
	return _active_vehicle_id


func export_state() -> Dictionary:
	return {
		&"unlocked": _unlocked.duplicate(),
		&"active_vehicle_id": _active_vehicle_id,
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"unlocked"):
		_unlocked = data[&"unlocked"].duplicate()
	if data.has(&"active_vehicle_id"):
		_active_vehicle_id = data[&"active_vehicle_id"]


func reset_state() -> void:
	_unlocked.clear()
	_active_vehicle_id = &""
