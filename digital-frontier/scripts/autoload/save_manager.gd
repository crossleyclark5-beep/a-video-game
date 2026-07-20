extends BaseManager
## Save and load orchestration.
##
## WHY: Multiple managers own slices of persistent state. SaveManager aggregates
## GameState snapshots and handles file I/O, versioning, and migration.

const SAVE_DIR := "user://saves/"

var _current_state: GameState = null
var _playtime_accumulator: float = 0.0


func _initialize_manager() -> void:
	_ensure_save_directory()
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)
	_current_state = GameState.new()
	_log("SaveManager initialized")


func _process(delta: float) -> void:
	_playtime_accumulator += delta


func get_current_state() -> GameState:
	return _current_state


func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _on_save_requested(slot: int) -> void:
	var success := save_to_slot(slot)
	EventBus.save_completed.emit(slot, success)


func _on_load_requested(slot: int) -> void:
	var success := load_from_slot(slot)
	EventBus.load_completed.emit(slot, success)


func save_to_slot(slot: int) -> bool:
	if slot < 0 or slot >= GameConstants.SAVE_SLOT_COUNT:
		return false

	_collect_state_from_managers()
	_current_state.timestamp_unix = int(Time.get_unix_time_from_system())
	_current_state.playtime_seconds += _playtime_accumulator
	_playtime_accumulator = 0.0

	var path := SAVE_DIR + "slot_%d" % slot + GameConstants.SAVE_FILE_EXTENSION
	var err := ResourceSaver.save(_current_state, path)
	return err == OK


func load_from_slot(slot: int) -> bool:
	if slot < 0 or slot >= GameConstants.SAVE_SLOT_COUNT:
		return false

	var path := SAVE_DIR + "slot_%d" % slot + GameConstants.SAVE_FILE_EXTENSION
	if not FileAccess.file_exists(path):
		return false

	var loaded := load(path) as GameState
	if loaded == null:
		return false

	_current_state = loaded
	_distribute_state_to_managers()
	return true


func _collect_state_from_managers() -> void:
	## Each manager writes its section into _current_state.
	_current_state.inventory_data = InventoryManager.export_state()
	_current_state.quest_data = QuestManager.export_state()
	_current_state.creature_data = CreatureManager.export_state()
	_current_state.npc_data = NPCManager.export_state()
	_current_state.vehicle_data = VehicleManager.export_state()
	_current_state.world_flags = WorldManager.export_state()
	_current_state.settings_data = {
		&"master_volume": GameConfig.master_volume,
		&"music_volume": GameConfig.music_volume,
		&"sfx_volume": GameConfig.sfx_volume,
	}


func _distribute_state_to_managers() -> void:
	InventoryManager.import_state(_current_state.inventory_data)
	QuestManager.import_state(_current_state.quest_data)
	CreatureManager.import_state(_current_state.creature_data)
	NPCManager.import_state(_current_state.npc_data)
	VehicleManager.import_state(_current_state.vehicle_data)
	WorldManager.import_state(_current_state.world_flags)

	if _current_state.settings_data.has(&"master_volume"):
		GameConfig.master_volume = _current_state.settings_data[&"master_volume"]
