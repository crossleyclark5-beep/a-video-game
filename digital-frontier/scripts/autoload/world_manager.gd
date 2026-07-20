extends BaseManager
## World, region, discovery flags, and chest-opened persistence.
##
## Exploration progress lives in world_flags so SaveManager can persist it
## without scene-node coupling.

const FLAG_DISCOVERED_PREFIX := "discovered_"
const FLAG_CHEST_PREFIX := "chest_opened_"

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


func set_active_hex_coords(coords: Vector3i) -> void:
	_active_hex_coords = coords
	EventBus.hex_tile_entered.emit(_active_region_id, coords)


func get_world_flag(flag_id: StringName, default: Variant = false) -> Variant:
	return _world_flags.get(flag_id, _world_flags.get(String(flag_id), default))


func set_world_flag(flag_id: StringName, value: Variant) -> void:
	_world_flags[flag_id] = value


func is_location_discovered(location_id: StringName) -> bool:
	return bool(get_world_flag(StringName(FLAG_DISCOVERED_PREFIX + String(location_id)), false))


func discover_location(location_id: StringName, display_name: String = "") -> bool:
	if is_location_discovered(location_id):
		return false
	set_world_flag(StringName(FLAG_DISCOVERED_PREFIX + String(location_id)), true)
	var names: Array = get_world_flag(&"discovery_names", [])
	if names is Array:
		var label := display_name if not display_name.is_empty() else String(location_id)
		if not names.has(label):
			names.append(label)
		set_world_flag(&"discovery_names", names)
	EventBus.location_discovered.emit(location_id)
	_log("Discovered: %s" % String(location_id))
	return true


func get_discovery_count() -> int:
	var count := 0
	for key in _world_flags.keys():
		var k := str(key)
		if k.begins_with(FLAG_DISCOVERED_PREFIX) and bool(_world_flags[key]):
			count += 1
	return count


func get_discovered_names() -> PackedStringArray:
	var names = get_world_flag(&"discovery_names", [])
	if names is Array:
		return PackedStringArray(names)
	return PackedStringArray()


func is_chest_opened(chest_id: StringName) -> bool:
	return bool(get_world_flag(StringName(FLAG_CHEST_PREFIX + String(chest_id)), false))


func set_chest_opened(chest_id: StringName, opened: bool = true) -> void:
	set_world_flag(StringName(FLAG_CHEST_PREFIX + String(chest_id)), opened)


func export_state() -> Dictionary:
	return {
		&"active_region_id": _active_region_id,
		&"active_hex_coords": _active_hex_coords,
		&"world_flags": _world_flags.duplicate(true),
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"active_region_id"):
		_active_region_id = data[&"active_region_id"]
	elif data.has("active_region_id"):
		_active_region_id = StringName(str(data["active_region_id"]))
	if data.has(&"active_hex_coords"):
		_active_hex_coords = data[&"active_hex_coords"]
	elif data.has("active_hex_coords"):
		_active_hex_coords = data["active_hex_coords"]
	if data.has(&"world_flags"):
		_world_flags = data[&"world_flags"].duplicate(true)
	elif data.has("world_flags"):
		_world_flags = data["world_flags"].duplicate(true)


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
	## Presentation systems handle the actual interior load; flag for save/quests.
	set_world_flag(StringName("visited_building_%s" % String(building_id)), true)
	QuestManager.notify_objective(&"enter_building", building_id, 1)
	_log("Building enter requested: %s" % building_id)
