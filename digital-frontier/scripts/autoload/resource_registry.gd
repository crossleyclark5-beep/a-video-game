extends BaseManager
## Central registry for data-driven Resource definitions.
##
## WHY: Game content lives in data/ as .tres files. ResourceRegistry loads and indexes
## them by ID so gameplay never hardcodes paths or duplicates lookup logic.

var _regions: Dictionary = {}
var _creatures: Dictionary = {}
var _items: Dictionary = {}
var _quests: Dictionary = {}
var _buildings: Dictionary = {}
var _npcs: Dictionary = {}
var _vehicles: Dictionary = {}
var _bosses: Dictionary = {}
var _loot_tables: Dictionary = {}


func _initialize_manager() -> void:
	_scan_directory(GameConstants.DATA_REGIONS, _regions)
	_scan_directory(GameConstants.DATA_CREATURES, _creatures)
	_scan_directory(GameConstants.DATA_ITEMS, _items)
	_scan_directory(GameConstants.DATA_QUESTS, _quests)
	_scan_directory(GameConstants.DATA_BUILDINGS, _buildings)
	_scan_directory(GameConstants.DATA_NPCS, _npcs)
	_scan_directory(GameConstants.DATA_VEHICLES, _vehicles)
	_scan_directory(GameConstants.DATA_BOSSES, _bosses)
	_scan_directory(GameConstants.DATA_LOOT, _loot_tables)
	_log(
		"Indexed %d regions, %d creatures, %d items, %d quests, %d loot tables"
		% [_regions.size(), _creatures.size(), _items.size(), _quests.size(), _loot_tables.size()]
	)


func _scan_directory(path: String, target: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource := load(path.path_join(file_name))
			if resource != null and resource.has_method("get_id"):
				target[resource.get_id()] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


func get_region(id: StringName) -> RegionData:
	return _regions.get(id)


func get_creature(id: StringName) -> CreatureData:
	return _creatures.get(id)


func get_item(id: StringName) -> ItemData:
	return _items.get(id)


func get_quest(id: StringName) -> QuestData:
	return _quests.get(id)


func get_building(id: StringName) -> BuildingData:
	return _buildings.get(id)


func get_npc(id: StringName) -> NPCData:
	return _npcs.get(id)


func get_vehicle(id: StringName) -> VehicleData:
	return _vehicles.get(id)


func get_boss(id: StringName) -> BossData:
	return _bosses.get(id)


func get_loot_table(id: StringName) -> LootTableData:
	return _loot_tables.get(id)


func get_all_regions() -> Array:
	return _regions.values()


func get_all_quests() -> Array:
	return _quests.values()


func has_id(category: StringName, id: StringName) -> bool:
	match category:
		&"region": return _regions.has(id)
		&"creature": return _creatures.has(id)
		&"item": return _items.has(id)
		&"quest": return _quests.has(id)
		&"building": return _buildings.has(id)
		&"npc": return _npcs.has(id)
		&"vehicle": return _vehicles.has(id)
		&"boss": return _bosses.has(id)
		&"loot": return _loot_tables.has(id)
		_: return false
