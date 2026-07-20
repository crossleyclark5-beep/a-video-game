extends BaseManager
## World, region, and hex-grid state orchestration.
##
## WHY: The hex overworld spans multiple regions with streaming and building interiors.
## WorldManager tracks active region, loaded chunks, and world-level flags without
## embedding that logic in scene nodes.

var _active_region_id: StringName = &""
var _active_hex_coords: Vector3i = Vector3i.ZERO
var _world_flags: Dictionary = {}
var _loaded_regions: Dictionary = {}


func _initialize_manager() -> void:
	EventBus.region_load_requested.connect(_on_region_load_requested)
	EventBus.building_enter_requested.connect(_on_building_enter_requested)
	_log("WorldManager initialized")


func get_active_region_id() -> StringName:
	return _active_region_id


func get_active_hex_coords() -> Vector3i:
	return _active_hex_coords


func get_world_flag(flag_id: StringName, default: Variant = false) -> Variant:
	return _world_flags.get(flag_id, default)


func set_world_flag(flag_id: StringName, value: Variant) -> void:
	_world_flags[flag_id] = value


func export_state() -> Dictionary:
	return {
		&"active_region_id": _active_region_id,
		&"active_hex_coords": _active_hex_coords,
		&"world_flags": _world_flags.duplicate(true),
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"active_region_id"):
		_active_region_id = data[&"active_region_id"]
	if data.has(&"active_hex_coords"):
		_active_hex_coords = data[&"active_hex_coords"]
	if data.has(&"world_flags"):
		_world_flags = data[&"world_flags"].duplicate(true)


func _on_region_load_requested(region_id: StringName) -> void:
	var region_data: RegionData = ResourceRegistry.get_region(region_id)
	if region_data == null:
		push_error("WorldManager: unknown region '%s'" % region_id)
		return
	_active_region_id = region_id
	_loaded_regions[region_id] = true
	EventBus.region_loaded.emit(region_id)
	_log("Region loaded: %s" % region_id)


func _on_building_enter_requested(building_id: StringName) -> void:
	var building_data: BuildingData = ResourceRegistry.get_building(building_id)
	if building_data == null:
		push_error("WorldManager: unknown building '%s'" % building_id)
		return
	_log("Building enter requested: %s" % building_id)
