extends BaseManager
## World, region, discovery flags, chest persistence, and adventure checkpoint.

const FLAG_DISCOVERED_PREFIX := "discovered_"
const FLAG_CHEST_PREFIX := "chest_opened_"
const FLAG_CHEST_TIME_PREFIX := "chest_opened_at_"

var _active_region_id: StringName = &""
var _active_hex_coords: Vector3i = Vector3i.ZERO
var _world_flags: Dictionary = {}
var _loaded_regions: Dictionary = {}
var _player_position: Vector3 = Vector3.ZERO
var _has_player_checkpoint: bool = false


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


func set_player_checkpoint(position: Vector3) -> void:
	_player_position = position
	_has_player_checkpoint = true
	set_world_flag(&"player_pos_x", position.x)
	set_world_flag(&"player_pos_y", position.y)
	set_world_flag(&"player_pos_z", position.z)
	set_world_flag(&"has_player_checkpoint", true)


func get_player_checkpoint() -> Vector3:
	return _player_position


func has_player_checkpoint() -> bool:
	return _has_player_checkpoint


func clear_player_checkpoint() -> void:
	_has_player_checkpoint = false
	set_world_flag(&"has_player_checkpoint", false)


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
		var data: DiscoverableData = ResourceRegistry.get_discoverable(location_id)
		if data and display_name.is_empty():
			label = data.display_name
		if not names.has(label):
			names.append(label)
		set_world_flag(&"discovery_names", names)
	EventBus.location_discovered.emit(location_id)
	EventBus.sfx_play_requested.emit(&"discover", Vector3.ZERO)
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


func get_map_blurb() -> String:
	## Placeholder map text for the adventure device HUD.
	var region := String(_active_region_id) if _active_region_id != &"" else "unknown"
	var lines: PackedStringArray = PackedStringArray()
	lines.append("REGION: %s" % region.replace("_", " ").capitalize())
	lines.append("")
	lines.append("Landmarks:")
	for data in ResourceRegistry.get_all_discoverables():
		var d: DiscoverableData = data
		if d.region_id != &"" and d.region_id != _active_region_id and _active_region_id != &"":
			continue
		var mark := "●" if is_location_discovered(d.id) else "○"
		var hint := d.map_hint if not d.map_hint.is_empty() else d.display_name
		if not is_location_discovered(d.id):
			hint = "???" if d.is_secret else hint
		lines.append("%s %s" % [mark, hint if is_location_discovered(d.id) else ("??? (%s)" % hint if not d.is_secret else "???")])
	lines.append("")
	lines.append("Explore to fill the map.")
	return "\n".join(lines)


func is_chest_opened(chest_id: StringName) -> bool:
	return bool(get_world_flag(StringName(FLAG_CHEST_PREFIX + String(chest_id)), false))


func set_chest_opened(chest_id: StringName, opened: bool = true) -> void:
	set_world_flag(StringName(FLAG_CHEST_PREFIX + String(chest_id)), opened)
	if opened:
		set_world_flag(
			StringName(FLAG_CHEST_TIME_PREFIX + String(chest_id)),
			int(Time.get_unix_time_from_system()),
		)
	else:
		_world_flags.erase(StringName(FLAG_CHEST_TIME_PREFIX + String(chest_id)))
		_world_flags.erase(FLAG_CHEST_TIME_PREFIX + String(chest_id))


func get_chest_opened_at(chest_id: StringName) -> int:
	return int(get_world_flag(StringName(FLAG_CHEST_TIME_PREFIX + String(chest_id)), 0))


## Returns true if chest should be treated as available (never opened or respawned).
func refresh_chest_respawn(chest_id: StringName, respawn_hours: float) -> bool:
	if respawn_hours <= 0.0:
		return not is_chest_opened(chest_id)
	if not is_chest_opened(chest_id):
		return true
	var opened_at := get_chest_opened_at(chest_id)
	if opened_at <= 0:
		return false
	var elapsed_h := (Time.get_unix_time_from_system() - opened_at) / 3600.0
	if elapsed_h >= respawn_hours:
		set_chest_opened(chest_id, false)
		return true
	return false


func export_state() -> Dictionary:
	return {
		&"active_region_id": _active_region_id,
		&"active_hex_coords": _active_hex_coords,
		&"world_flags": _world_flags.duplicate(true),
		&"player_position": _player_position,
		&"has_player_checkpoint": _has_player_checkpoint,
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
	if data.has(&"player_position"):
		_player_position = data[&"player_position"]
		_has_player_checkpoint = bool(data.get(&"has_player_checkpoint", true))
	elif data.has("player_position"):
		_player_position = data["player_position"]
		_has_player_checkpoint = bool(data.get("has_player_checkpoint", true))
	elif bool(get_world_flag(&"has_player_checkpoint", false)):
		_player_position = Vector3(
			float(get_world_flag(&"player_pos_x", 0.0)),
			float(get_world_flag(&"player_pos_y", 0.15)),
			float(get_world_flag(&"player_pos_z", 0.0)),
		)
		_has_player_checkpoint = true


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
	set_world_flag(StringName("visited_building_%s" % String(building_id)), true)
	QuestManager.notify_objective(&"enter_building", building_id, 1)
	_log("Building enter requested: %s" % building_id)
