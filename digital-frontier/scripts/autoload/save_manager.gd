extends BaseManager
## Save and load orchestration.
##
## Aggregates manager state into GameState and writes user://saves/slot_N.sav.
## Autosave is requested on scene transitions via request_autosave().

const SAVE_DIR := "user://saves/"

var _current_state: GameState = null
var _playtime_accumulator: float = 0.0
var _autosave_enabled: bool = true


func _initialize_manager() -> void:
	_ensure_save_directory()
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)
	EventBus.scene_transition_started.connect(_on_scene_transition_started)
	_current_state = GameState.new()
	## Defer so Inventory/Quest/World/Creature have finished _ready first.
	call_deferred("_try_load_autosave")
	_log("SaveManager initialized")


func _try_load_autosave() -> void:
	if FileAccess.file_exists(SAVE_DIR + "slot_%d" % GameConstants.AUTOSAVE_SLOT + GameConstants.SAVE_FILE_EXTENSION):
		load_from_slot(GameConstants.AUTOSAVE_SLOT)
		_log("Autosave loaded")


func _process(delta: float) -> void:
	_playtime_accumulator += delta


func get_current_state() -> GameState:
	return _current_state


func request_autosave() -> void:
	if not _autosave_enabled:
		return
	EventBus.save_requested.emit(GameConstants.AUTOSAVE_SLOT)


func set_autosave_enabled(enabled: bool) -> void:
	_autosave_enabled = enabled


func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _on_save_requested(slot: int) -> void:
	var success := save_to_slot(slot)
	EventBus.save_completed.emit(slot, success)
	if success:
		_log("Saved slot %d" % slot)


func _on_load_requested(slot: int) -> void:
	var success := load_from_slot(slot)
	EventBus.load_completed.emit(slot, success)


func _on_scene_transition_started(_from: StringName, _to: StringName) -> void:
	## Persist progress whenever leaving a scene (Home ↔ Adventure).
	if _from != StringName(""):
		request_autosave()


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


func has_save(slot: int = GameConstants.AUTOSAVE_SLOT) -> bool:
	var path := SAVE_DIR + "slot_%d" % slot + GameConstants.SAVE_FILE_EXTENSION
	return FileAccess.file_exists(path)


func _collect_state_from_managers() -> void:
	_current_state.inventory_data = InventoryManager.export_state()
	_current_state.quest_data = QuestManager.export_state()
	_current_state.creature_data = CreatureManager.export_state()
	_current_state.npc_data = NPCManager.export_state()
	_current_state.vehicle_data = VehicleManager.export_state()
	_current_state.collection_data = CollectionManager.export_state()
	var world := WorldManager.export_state()
	_current_state.world_flags = world
	_current_state.current_region_id = WorldManager.get_active_region_id()
	_current_state.current_hex_coords = WorldManager.get_active_hex_coords()
	_current_state.player_position = WorldManager.get_player_checkpoint()
	_current_state.has_player_checkpoint = WorldManager.has_player_checkpoint()
	_current_state.schema_version = 2
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
	if _current_state.collection_data:
		CollectionManager.import_state(_current_state.collection_data)
	if _current_state.has_player_checkpoint:
		WorldManager.set_player_checkpoint(_current_state.player_position)

	if _current_state.settings_data.has(&"master_volume"):
		GameConfig.master_volume = _current_state.settings_data[&"master_volume"]
	if _current_state.settings_data.has(&"music_volume"):
		GameConfig.music_volume = _current_state.settings_data[&"music_volume"]
	if _current_state.settings_data.has(&"sfx_volume"):
		GameConfig.sfx_volume = _current_state.settings_data[&"sfx_volume"]
