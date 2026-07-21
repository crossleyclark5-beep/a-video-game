extends BaseManager
## Save / load + local multi-user profiles for the Field Unit.
##
## Offline only. Each profile owns an isolated GameState under
## user://saves/profiles/{id}/slot_0.res. Digi-Pet Home always reflects
## the active profile’s partner.

const SAVE_DIR := "user://saves/"
const LEGACY_SLOT0_SAV := "user://saves/slot_0.sav"
const LEGACY_SLOT0_RES := "user://saves/slot_0.res"

var _current_state: GameState = null
var _playtime_accumulator: float = 0.0
var _autosave_enabled: bool = true
var _active_profile_id: String = ""
var _index: Dictionary = {}  ## {schema, active_profile_id, profiles: Array}


func _initialize_manager() -> void:
	_ensure_save_directory()
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)
	EventBus.scene_transition_started.connect(_on_scene_transition_started)
	_current_state = GameState.new()
	_load_or_migrate_index()
	## Do NOT auto-load a profile — ProfileSelect chooses after boot logo.
	_log("SaveManager initialized (profiles)")


func _process(delta: float) -> void:
	if _active_profile_id != "":
		_playtime_accumulator += delta


func get_current_state() -> GameState:
	return _current_state


func get_active_profile_id() -> String:
	return _active_profile_id


func has_active_profile() -> bool:
	return _active_profile_id != ""


func get_profile_count() -> int:
	return (_index.get("profiles", []) as Array).size()


func can_create_profile() -> bool:
	return get_profile_count() < ProfileCatalog.MAX_PROFILES


func list_profiles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in _index.get("profiles", []):
		if p is Dictionary:
			out.append((p as Dictionary).duplicate(true))
	## Most recently played first.
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("last_played_unix", 0)) > int(b.get("last_played_unix", 0))
	)
	return out


func get_profile(profile_id: String) -> Dictionary:
	for p in _index.get("profiles", []):
		if p is Dictionary and str(p.get("id", "")) == profile_id:
			return (p as Dictionary).duplicate(true)
	return {}


func get_active_profile() -> Dictionary:
	return get_profile(_active_profile_id)


func request_autosave() -> void:
	if not _autosave_enabled or _active_profile_id == "":
		return
	EventBus.save_requested.emit(GameConstants.AUTOSAVE_SLOT)


func set_autosave_enabled(enabled: bool) -> void:
	_autosave_enabled = enabled


func create_profile(display_name: String, avatar_id: StringName) -> String:
	if not can_create_profile():
		return ""
	var name_clean := display_name.strip_edges()
	if name_clean.is_empty():
		name_clean = "Traveler"
	if name_clean.length() > ProfileCatalog.NAME_MAX_LEN:
		name_clean = name_clean.substr(0, ProfileCatalog.NAME_MAX_LEN)
	var pid := ProfileCatalog.make_profile_id()
	var now := int(Time.get_unix_time_from_system())
	var rec := {
		"id": pid,
		"display_name": name_clean,
		"avatar_id": String(avatar_id),
		"created_unix": now,
		"last_played_unix": now,
		"summary": ProfileCatalog.empty_summary(),
	}
	var profiles: Array = _index.get("profiles", [])
	profiles.append(rec)
	_index["profiles"] = profiles
	_ensure_profile_dir(pid)
	_write_index()
	return pid


func delete_profile(profile_id: String) -> bool:
	if profile_id.is_empty():
		return false
	var profiles: Array = _index.get("profiles", [])
	var next: Array = []
	var found := false
	for p in profiles:
		if p is Dictionary and str(p.get("id", "")) == profile_id:
			found = true
			continue
		next.append(p)
	if not found:
		return false
	_index["profiles"] = next
	if str(_index.get("active_profile_id", "")) == profile_id:
		_index["active_profile_id"] = ""
	_write_index()
	_wipe_profile_dir(profile_id)
	if _active_profile_id == profile_id:
		_active_profile_id = ""
		reset_all_managers()
		_current_state = GameState.new()
	return true


func select_profile(profile_id: String) -> bool:
	var rec := get_profile(profile_id)
	if rec.is_empty():
		return false
	## Persist previous profile before switching.
	if _active_profile_id != "" and _active_profile_id != profile_id:
		save_to_slot(GameConstants.AUTOSAVE_SLOT)
	_active_profile_id = profile_id
	_index["active_profile_id"] = profile_id
	_touch_last_played(profile_id)
	_write_index()
	reset_all_managers()
	_current_state = GameState.new()
	if has_save(GameConstants.AUTOSAVE_SLOT):
		if not load_from_slot(GameConstants.AUTOSAVE_SLOT):
			return false
	else:
		## Brand-new adventure — starting bits already set by InventoryManager.reset.
		_current_state.schema_version = 3
		_current_state.profile_id = profile_id
		_current_state.profile_display_name = str(rec.get("display_name", "Traveler"))
		_current_state.profile_avatar_id = StringName(str(rec.get("avatar_id", "ember")))
	EventBus.profile_changed.emit(profile_id)
	_log("Active profile: %s" % profile_id)
	return true


func clear_active_profile(save_first: bool = true) -> void:
	if save_first and _active_profile_id != "":
		save_to_slot(GameConstants.AUTOSAVE_SLOT)
	_active_profile_id = ""
	_index["active_profile_id"] = ""
	_write_index()
	reset_all_managers()
	_current_state = GameState.new()
	EventBus.profile_changed.emit("")


func refresh_active_summary() -> void:
	if _active_profile_id == "":
		return
	_collect_state_from_managers()
	_update_summary_from_state(_active_profile_id)
	_write_index()


func reset_all_managers() -> void:
	_playtime_accumulator = 0.0
	InventoryManager.reset_state()
	QuestManager.reset_state()
	CreatureManager.reset_state()
	NPCManager.reset_state()
	VehicleManager.reset_state()
	WorldManager.reset_state()
	CollectionManager.reset_state()
	ShopManager.reset_state()
	CharacterRosterManager.reset_state()


func save_to_slot(slot: int) -> bool:
	if _active_profile_id == "":
		return false
	if slot < 0 or slot >= GameConstants.SAVE_SLOT_COUNT:
		return false
	_collect_state_from_managers()
	_current_state.timestamp_unix = int(Time.get_unix_time_from_system())
	_current_state.playtime_seconds += _playtime_accumulator
	_playtime_accumulator = 0.0
	_current_state.schema_version = 3
	var rec := get_profile(_active_profile_id)
	_current_state.profile_id = _active_profile_id
	_current_state.profile_display_name = str(rec.get("display_name", ""))
	_current_state.profile_avatar_id = StringName(str(rec.get("avatar_id", "ember")))
	_ensure_profile_dir(_active_profile_id)
	var path := _slot_path(_active_profile_id, slot)
	var err := ResourceSaver.save(_current_state, path)
	if err != OK:
		return false
	_update_summary_from_state(_active_profile_id)
	_touch_last_played(_active_profile_id)
	_write_index()
	return true


func load_from_slot(slot: int) -> bool:
	if _active_profile_id == "":
		return false
	if slot < 0 or slot >= GameConstants.SAVE_SLOT_COUNT:
		return false
	var path := _slot_path(_active_profile_id, slot)
	if not FileAccess.file_exists(path):
		return false
	var loaded := load(path) as GameState
	if loaded == null:
		return false
	_current_state = loaded
	_distribute_state_to_managers()
	return true


func has_save(slot: int = GameConstants.AUTOSAVE_SLOT) -> bool:
	if _active_profile_id == "":
		return false
	return FileAccess.file_exists(_slot_path(_active_profile_id, slot))


func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(ProfileCatalog.PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(ProfileCatalog.PROFILES_DIR)


func _ensure_profile_dir(profile_id: String) -> void:
	var path := ProfileCatalog.PROFILES_DIR + profile_id
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)


func _wipe_profile_dir(profile_id: String) -> void:
	var path := ProfileCatalog.PROFILES_DIR + profile_id
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			dir.remove(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _slot_path(profile_id: String, slot: int) -> String:
	return ProfileCatalog.PROFILES_DIR + profile_id + "/slot_%d" % slot + GameConstants.SAVE_FILE_EXTENSION


func _on_save_requested(slot: int) -> void:
	var success := save_to_slot(slot)
	EventBus.save_completed.emit(slot, success)
	if success:
		_log("Saved profile %s slot %d" % [_active_profile_id, slot])


func _on_load_requested(slot: int) -> void:
	var success := load_from_slot(slot)
	EventBus.load_completed.emit(slot, success)


func _on_scene_transition_started(_from: StringName, _to: StringName) -> void:
	if _from != StringName(""):
		request_autosave()


func _collect_state_from_managers() -> void:
	_current_state.inventory_data = InventoryManager.export_state()
	_current_state.quest_data = QuestManager.export_state()
	_current_state.creature_data = CreatureManager.export_state()
	_current_state.npc_data = NPCManager.export_state()
	_current_state.vehicle_data = VehicleManager.export_state()
	_current_state.character_roster_data = CharacterRosterManager.export_state()
	_current_state.collection_data = CollectionManager.export_state()
	_current_state.shop_data = ShopManager.export_state()
	var world := WorldManager.export_state()
	_current_state.world_flags = world
	_current_state.current_region_id = WorldManager.get_active_region_id()
	_current_state.current_hex_coords = WorldManager.get_active_hex_coords()
	_current_state.player_position = WorldManager.get_player_checkpoint()
	_current_state.has_player_checkpoint = WorldManager.has_player_checkpoint()
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
	if _current_state.shop_data:
		ShopManager.import_state(_current_state.shop_data)
	if _current_state.character_roster_data:
		CharacterRosterManager.import_state(_current_state.character_roster_data)
	else:
		CharacterRosterManager.ensure_starter()
	if _current_state.has_player_checkpoint:
		WorldManager.set_player_checkpoint(_current_state.player_position)
	if _current_state.settings_data.has(&"master_volume"):
		GameConfig.master_volume = _current_state.settings_data[&"master_volume"]
	if _current_state.settings_data.has(&"music_volume"):
		GameConfig.music_volume = _current_state.settings_data[&"music_volume"]
	if _current_state.settings_data.has(&"sfx_volume"):
		GameConfig.sfx_volume = _current_state.settings_data[&"sfx_volume"]


func _update_summary_from_state(profile_id: String) -> void:
	var profiles: Array = _index.get("profiles", [])
	for i in profiles.size():
		var p: Dictionary = profiles[i]
		if str(p.get("id", "")) != profile_id:
			continue
		var quests: Dictionary = _current_state.quest_data
		var completed: Dictionary = quests.get(&"completed", quests.get("completed", {}))
		var disc := WorldManager.get_discovery_count()
		var ach: Dictionary = _current_state.collection_data.get(
			&"achievements", _current_state.collection_data.get("achievements", {})
		)
		var has_partner := CreatureManager.has_chosen_partner()
		var summary := {
			&"partner_species": String(CreatureManager.get_companion_id()) if has_partner else "",
			&"partner_nickname": CreatureManager.get_companion_nickname() if has_partner else "",
			&"partner_level": CreatureManager.get_level() if has_partner else 0,
			&"partner_stage": CreatureManager.get_evolution_stage() if has_partner else 0,
			&"playtime_seconds": _current_state.playtime_seconds,
			&"bits": InventoryManager.get_bits(),
			&"quests_completed": completed.size(),
			&"discoveries": disc,
			&"achievements": ach.size(),
			&"completion_pct": ProfileCatalog.compute_completion_pct(
				completed.size(), disc, ach.size(), has_partner
			),
		}
		p["summary"] = summary
		profiles[i] = p
		_index["profiles"] = profiles
		return


func _touch_last_played(profile_id: String) -> void:
	var profiles: Array = _index.get("profiles", [])
	for i in profiles.size():
		var p: Dictionary = profiles[i]
		if str(p.get("id", "")) == profile_id:
			p["last_played_unix"] = int(Time.get_unix_time_from_system())
			profiles[i] = p
			_index["profiles"] = profiles
			return


func _load_or_migrate_index() -> void:
	if FileAccess.file_exists(ProfileCatalog.INDEX_PATH):
		var f := FileAccess.open(ProfileCatalog.INDEX_PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if parsed is Dictionary:
				_index = parsed
				_active_profile_id = ""
				return
	_index = {"schema": 1, "active_profile_id": "", "profiles": []}
	## Migrate legacy single-slot save into a first profile.
	var legacy := ""
	if FileAccess.file_exists(LEGACY_SLOT0_RES):
		legacy = LEGACY_SLOT0_RES
	elif FileAccess.file_exists(LEGACY_SLOT0_SAV):
		legacy = LEGACY_SLOT0_SAV
	if legacy != "":
		var pid := create_profile("Traveler", &"ember")
		if pid != "":
			_ensure_profile_dir(pid)
			var dest := _slot_path(pid, GameConstants.AUTOSAVE_SLOT)
			DirAccess.copy_absolute(legacy, dest)
			_log("Migrated legacy save into profile %s" % pid)
	_write_index()


func _write_index() -> void:
	_index["schema"] = 1
	var f := FileAccess.open(ProfileCatalog.INDEX_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write profile index")
		return
	f.store_string(JSON.stringify(_index, "\t"))
	f.close()
