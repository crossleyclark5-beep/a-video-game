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
var _discoverables: Dictionary = {}
var _achievements: Dictionary = {}
var _abilities: Dictionary = {}
var _evolutions: Dictionary = {}


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
	_scan_directory(GameConstants.DATA_DISCOVERABLES, _discoverables)
	_scan_directory(GameConstants.DATA_ACHIEVEMENTS, _achievements)
	_scan_directory(GameConstants.DATA_ABILITIES, _abilities)
	_scan_directory(GameConstants.DATA_EVOLUTIONS, _evolutions)
	_log(
		"Indexed %d regions, %d creatures, %d items, %d quests, %d loot, %d discoverables, %d achievements, %d abilities, %d evolutions"
		% [
			_regions.size(), _creatures.size(), _items.size(), _quests.size(),
			_loot_tables.size(), _discoverables.size(), _achievements.size(), _abilities.size(),
			_evolutions.size(),
		]
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


func get_discoverable(id: StringName) -> DiscoverableData:
	return _discoverables.get(id)


func get_achievement(id: StringName) -> AchievementData:
	return _achievements.get(id)


func get_ability(id: StringName) -> CreatureAbilityData:
	return _abilities.get(id)


func get_evolution_path(id: StringName) -> EvolutionPathData:
	return _evolutions.get(id)


func get_all_regions() -> Array:
	return _regions.values()


func get_all_quests() -> Array:
	return _quests.values()


func get_all_creatures() -> Array:
	return _creatures.values()


func get_all_discoverables() -> Array:
	return _discoverables.values()


func get_all_achievements() -> Array:
	return _achievements.values()


func get_all_abilities() -> Array:
	return _abilities.values()


func get_all_evolution_paths() -> Array:
	return _evolutions.values()


func get_evolution_paths_for(species_id: StringName, from_stage: int = -1) -> Array:
	var out: Array = []
	for path in _evolutions.values():
		if path is EvolutionPathData:
			var p := path as EvolutionPathData
			if p.species_id != species_id:
				continue
			if from_stage >= 0 and p.from_stage != from_stage:
				continue
			out.append(p)
	out.sort_custom(func(a: EvolutionPathData, b: EvolutionPathData) -> bool: return a.priority > b.priority)
	return out


func get_all_items() -> Array:
	return _items.values()


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
		&"discoverable": return _discoverables.has(id)
		&"achievement": return _achievements.has(id)
		&"ability": return _abilities.has(id)
		&"evolution": return _evolutions.has(id)
		_: return false
