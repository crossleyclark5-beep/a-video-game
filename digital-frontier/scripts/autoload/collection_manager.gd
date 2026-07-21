extends BaseManager
## Collection journal — discoveries, creatures, items, rare finds, achievements.
##
## Aggregates progress for the handheld Collection screen. Unlock checks run
## off EventBus so content can expand without UI rewrites.

const MAX_RARE_FINDS := 48

var _unlocked_achievements: Dictionary = {}  ## id -> unix time
var _rare_finds: Array = []  ## [{label, source, unix}]
var _chests_opened_count: int = 0
var _bits_earned_lifetime: int = 0
## Creature Index — wild discoveries (separate from partner ownership).
var _creature_index: Dictionary = {}  ## id -> {name, blurb, rarity, habitat, first_unix, count, battles_won, battles_lost, temperament}


func _initialize_manager() -> void:
	EventBus.location_discovered.connect(_on_location_discovered)
	EventBus.chest_opened.connect(_on_chest_opened)
	EventBus.bits_changed.connect(_on_bits_changed)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.companion_state_changed.connect(_evaluate_achievements)
	_log("CollectionManager initialized")


func get_discovery_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for data in ResourceRegistry.get_all_discoverables():
		var d: DiscoverableData = data
		var discovered := WorldManager.is_location_discovered(d.id)
		entries.append({
			&"id": d.id,
			&"name": d.display_name,
			&"description": d.description if discovered else "????",
			&"discovered": discovered,
			&"category": d.category,
			&"region_id": d.region_id,
			&"map_hint": d.map_hint if discovered else "Unknown",
			&"is_secret": d.is_secret,
		})
	## Include discoveries that exist only as world flags (no .tres yet).
	for name in WorldManager.get_discovered_names():
		var already := false
		for e in entries:
			if str(e.get(&"name", "")) == name:
				already = true
				break
		if not already:
			entries.append({
				&"id": StringName(name.to_snake_case()),
				&"name": name,
				&"description": "Noted in your explorer log.",
				&"discovered": true,
				&"category": DiscoverableData.Category.LANDMARK,
				&"region_id": WorldManager.get_active_region_id(),
				&"map_hint": "",
				&"is_secret": false,
			})
	return entries


func get_discovery_progress() -> Vector2i:
	var total := ResourceRegistry.get_all_discoverables().size()
	var found := 0
	for data in ResourceRegistry.get_all_discoverables():
		if WorldManager.is_location_discovered((data as DiscoverableData).id):
			found += 1
	if total <= 0:
		total = maxi(WorldManager.get_discovery_count(), 1)
		found = WorldManager.get_discovery_count()
	return Vector2i(found, total)


func get_item_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for data in ResourceRegistry.get_all_items():
		var item: ItemData = data
		var qty := InventoryManager.get_quantity(item.id)
		entries.append({
			&"id": item.id,
			&"name": item.display_name,
			&"description": item.description,
			&"quantity": qty,
			&"collected": qty > 0,
		})
	return entries


func get_creature_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for data in ResourceRegistry.get_all_creatures():
		var c: CreatureData = data
		var owned := _creature_captured(c.id)
		var indexed := _creature_index.has(c.id) or _creature_index.has(String(c.id))
		entries.append({
			&"id": c.id,
			&"name": c.display_name if (owned or indexed) else "????",
			&"description": c.description if (owned or indexed) else "A friend waiting somewhere out there.",
			&"collected": owned,
			&"indexed": indexed,
			&"level": CreatureManager.get_level() if owned and CreatureManager.get_companion_id() == c.id else 0,
		})
	## Wild index-only species (not partner templates).
	for key in _creature_index.keys():
		var sid := StringName(str(key))
		var already := false
		for e in entries:
			if e.get(&"id", &"") == sid:
				already = true
				break
		if already:
			continue
		var row: Dictionary = _creature_index[key]
		entries.append({
			&"id": sid,
			&"name": str(row.get("name", sid)),
			&"description": str(row.get("blurb", "")),
			&"collected": false,
			&"indexed": true,
			&"level": 0,
		})
	return entries


func record_creature_sighting(payload: Dictionary, _world_pos: Vector3 = Vector3.ZERO, announce: bool = true) -> bool:
	var sid := StringName(str(payload.get(&"id", payload.get("id", ""))))
	if sid == &"":
		return false
	var key: Variant = sid if _creature_index.has(sid) else (String(sid) if _creature_index.has(String(sid)) else sid)
	var is_new := not _creature_index.has(sid) and not _creature_index.has(String(sid))
	var row: Dictionary
	if is_new:
		row = {
			"name": str(payload.get(&"name", payload.get("name", sid))),
			"blurb": str(payload.get(&"blurb", payload.get("blurb", ""))),
			"rarity": int(payload.get(&"rarity", payload.get("rarity", 0))),
			"rarity_label": str(payload.get(&"rarity_label", payload.get("rarity_label", "Common"))),
			"habitat": str(payload.get(&"habitat", payload.get("habitat", "Unknown"))),
			"temperament_label": str(payload.get(&"temperament_label", payload.get("temperament_label", "Wild"))),
			"first_unix": int(Time.get_unix_time_from_system()),
			"count": 1,
			"battles_won": 0,
			"battles_lost": 0,
		}
		_creature_index[sid] = row
		EventBus.creature_discovered.emit(sid, int(row["rarity"]))
		if announce:
			var rare_tag := str(row["rarity_label"])
			EventBus.ui_notification_requested.emit("New Index entry! %s · %s" % [row["name"], rare_tag], 3.2)
			EventBus.sfx_play_requested.emit(&"discover", Vector3.ZERO)
			DeviceService.notify_event(&"discover")
			CreatureManager.grant_adventure_bond(1.0, "")
			if int(row["rarity"]) >= EcosystemCatalog.Rarity.RARE:
				record_rare_find(str(row["name"]), "creature_index")
	else:
		row = _creature_index[key]
		row["count"] = int(row.get("count", 1)) + 1
		_creature_index[key] = row
	EventBus.creature_sighted.emit(sid)
	return is_new


func record_creature_battle(species_id: StringName, won: bool) -> void:
	if species_id == &"":
		return
	if not _creature_index.has(species_id) and not _creature_index.has(String(species_id)):
		## Auto-index on combat contact.
		var def := EcosystemCatalog.find_species(species_id)
		if not def.is_empty():
			record_creature_sighting({
				&"id": species_id,
				&"name": def.get("label", species_id),
				&"blurb": def.get("blurb", ""),
				&"rarity": def.get("rarity", 0),
				&"rarity_label": EcosystemCatalog.rarity_label(int(def.get("rarity", 0))),
				&"habitat": def.get("habitat", "Grassland"),
				&"temperament_label": EcosystemCatalog.temperament_label(int(def.get("temperament", 0))),
			}, Vector3.ZERO, true)
	var key: Variant = species_id if _creature_index.has(species_id) else String(species_id)
	if not _creature_index.has(key):
		return
	var row: Dictionary = _creature_index[key]
	if won:
		row["battles_won"] = int(row.get("battles_won", 0)) + 1
	else:
		row["battles_lost"] = int(row.get("battles_lost", 0)) + 1
	_creature_index[key] = row


func get_creature_index_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	## Known catalog species (discovered or ???).
	for def in EcosystemCatalog.grassland_species():
		var sid: StringName = def.get("id", &"")
		var row: Dictionary = _creature_index.get(sid, _creature_index.get(String(sid), {}))
		var known := not row.is_empty()
		entries.append({
			&"id": sid,
			&"name": str(def.get("label", sid)) if known else "????",
			&"blurb": str(def.get("blurb", "")) if known else "Undocumented wild signal…",
			&"rarity_label": EcosystemCatalog.rarity_label(int(def.get("rarity", 0))) if known else "???",
			&"habitat": str(def.get("habitat", "")) if known else "???",
			&"temperament_label": EcosystemCatalog.temperament_label(int(def.get("temperament", 0))) if known else "???",
			&"discovered": known,
			&"count": int(row.get("count", 0)),
			&"battles_won": int(row.get("battles_won", 0)),
			&"battles_lost": int(row.get("battles_lost", 0)),
			&"first_unix": int(row.get("first_unix", 0)),
		})
	## Boss + extras only in index.
	var boss := EcosystemCatalog.grassland_boss()
	var bid: StringName = boss.get("id", &"")
	var brow: Dictionary = _creature_index.get(bid, _creature_index.get(String(bid), {}))
	entries.append({
		&"id": bid,
		&"name": str(boss.get("label", bid)) if not brow.is_empty() else "????",
		&"blurb": str(boss.get("blurb", "")) if not brow.is_empty() else "A legendary guardian sleeps somewhere…",
		&"rarity_label": "Legendary" if not brow.is_empty() else "???",
		&"habitat": "Forest" if not brow.is_empty() else "???",
		&"temperament_label": "Boss" if not brow.is_empty() else "???",
		&"discovered": not brow.is_empty(),
		&"count": int(brow.get("count", 0)),
		&"battles_won": int(brow.get("battles_won", 0)),
		&"battles_lost": int(brow.get("battles_lost", 0)),
		&"first_unix": int(brow.get("first_unix", 0)),
	})
	return entries


func get_creature_index_progress() -> Vector2i:
	var total := EcosystemCatalog.grassland_species().size() + 1  ## + boss
	var found := 0
	for e in get_creature_index_entries():
		if e.get(&"discovered", false):
			found += 1
	return Vector2i(found, total)


func get_rare_finds() -> Array:
	return _rare_finds.duplicate(true)


func get_achievement_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for data in ResourceRegistry.get_all_achievements():
		var a: AchievementData = data
		var unlocked := _unlocked_achievements.has(a.id) or _unlocked_achievements.has(String(a.id))
		entries.append({
			&"id": a.id,
			&"name": a.display_name if unlocked else "Locked",
			&"description": a.description if unlocked else "Keep exploring…",
			&"unlocked": unlocked,
			&"icon": a.icon_label,
		})
	return entries


func get_summary_line() -> String:
	var disc := get_discovery_progress()
	var idx := get_creature_index_progress()
	var ach_unlocked := _unlocked_achievements.size()
	var ach_total := ResourceRegistry.get_all_achievements().size()
	return "Discoveries %d/%d · Index %d/%d · Achievements %d/%d" % [
		disc.x, disc.y,
		idx.x, idx.y,
		ach_unlocked, maxi(ach_total, 1),
	]


func get_journal_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== ADVENTURE JOURNAL ===")
	lines.append(get_summary_line())
	lines.append("")
	lines.append("-- Partner --")
	if CreatureManager.has_chosen_partner():
		lines.append("%s  Lv.%d  ·  %s" % [
			CreatureManager.get_companion_nickname(),
			CreatureManager.get_level(),
			CreatureManager.get_stage_display_name(),
		])
		lines.append("Bond %d%%  ·  Mood %s" % [
			int(CreatureManager.get_friendship()),
			CreatureManager.get_mood_label(),
		])
	else:
		lines.append("No partner yet.")
	lines.append("")
	lines.append("-- Locations --")
	for e in get_discovery_entries():
		var mark := "✓" if e[&"discovered"] else "·"
		lines.append("%s %s" % [mark, e[&"name"]])
		if e[&"discovered"] and not str(e[&"description"]).is_empty():
			lines.append("   %s" % e[&"description"])
	lines.append("")
	lines.append("-- Creature Index --")
	var idx := get_creature_index_progress()
	lines.append("Logged %d / %d wild species" % [idx.x, idx.y])
	for e in get_creature_index_entries():
		var mark := "✓" if e[&"discovered"] else "·"
		lines.append("%s %s  [%s]" % [mark, e[&"name"], e[&"rarity_label"]])
		if e[&"discovered"]:
			lines.append("   %s · %s · seen ×%d · W/L %d/%d" % [
				e[&"habitat"], e[&"temperament_label"], e[&"count"], e[&"battles_won"], e[&"battles_lost"],
			])
	lines.append("")
	lines.append("-- Partner templates --")
	for e in get_creature_entries():
		var mark2 := "✓" if e[&"collected"] else ("◇" if e.get(&"indexed", false) else "·")
		lines.append("%s %s" % [mark2, e[&"name"]])
	lines.append("")
	lines.append("-- Items --")
	var any_item := false
	for e in get_item_entries():
		if e[&"collected"]:
			any_item = true
			lines.append("✓ %s ×%d" % [e[&"name"], e[&"quantity"]])
	if not any_item:
		lines.append("· Pack empty — explore to find supplies.")
	lines.append("")
	lines.append("-- Memories --")
	if _rare_finds.is_empty():
		lines.append("· None yet — battles, secrets, and rare chests leave marks here.")
	else:
		for r in _rare_finds:
			lines.append("✦ %s (%s)" % [str(r.get("label", "?")), str(r.get("source", ""))])
	lines.append("")
	lines.append("-- Achievements --")
	for e in get_achievement_entries():
		var mark := "★" if e[&"unlocked"] else "·"
		lines.append("%s %s — %s" % [mark, e[&"name"], e[&"description"]])
	return "\n".join(lines)


func record_rare_find(label: String, source: String) -> void:
	_rare_finds.append({
		"label": label,
		"source": source,
		"unix": int(Time.get_unix_time_from_system()),
	})
	while _rare_finds.size() > MAX_RARE_FINDS:
		_rare_finds.pop_front()
	_try_unlock_by_trigger(AchievementData.Trigger.RARE_FIND, &"any", 1)


func export_state() -> Dictionary:
	return {
		&"achievements": _unlocked_achievements.duplicate(),
		&"rare_finds": _rare_finds.duplicate(true),
		&"chests_opened_count": _chests_opened_count,
		&"bits_earned_lifetime": _bits_earned_lifetime,
		&"creature_index": _creature_index.duplicate(true),
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	_unlocked_achievements = data.get(&"achievements", data.get("achievements", {})).duplicate()
	_rare_finds = data.get(&"rare_finds", data.get("rare_finds", [])).duplicate(true)
	_chests_opened_count = int(data.get(&"chests_opened_count", data.get("chests_opened_count", 0)))
	_bits_earned_lifetime = int(data.get(&"bits_earned_lifetime", data.get("bits_earned_lifetime", 0)))
	_creature_index = data.get(&"creature_index", data.get("creature_index", {})).duplicate(true)


func reset_state() -> void:
	_unlocked_achievements.clear()
	_rare_finds.clear()
	_chests_opened_count = 0
	_bits_earned_lifetime = 0
	_creature_index.clear()


func _creature_captured(creature_id: StringName) -> bool:
	if CreatureManager.get_companion_id() == creature_id:
		return true
	## Any captured instance of this species counts for the journal.
	var state: Dictionary = CreatureManager.export_state()
	var captured: Dictionary = state.get(&"captured", state.get("captured", {}))
	for key in captured.keys():
		var entry: Dictionary = captured[key]
		var sid := StringName(str(entry.get("species_id", entry.get(&"species_id", ""))))
		if sid == creature_id:
			return true
	return false


func _on_location_discovered(_location_id: StringName) -> void:
	_evaluate_achievements()


func _on_chest_opened(chest_id: StringName, rarity: StringName) -> void:
	_chests_opened_count += 1
	if rarity == &"rare" or rarity == &"legendary":
		record_rare_find("%s chest" % String(rarity).capitalize(), String(chest_id))
	_evaluate_achievements()


func _on_bits_changed(_total: int, delta: int) -> void:
	if delta > 0:
		_bits_earned_lifetime += delta
		_evaluate_achievements()


func _on_quest_completed(quest_id: StringName) -> void:
	_try_unlock_by_trigger(AchievementData.Trigger.QUEST_COMPLETE, quest_id, 1)
	_evaluate_achievements()


func _evaluate_achievements(_a = null) -> void:
	_try_unlock_by_trigger(AchievementData.Trigger.DISCOVER_COUNT, &"", WorldManager.get_discovery_count())
	_try_unlock_by_trigger(AchievementData.Trigger.CHEST_COUNT, &"", _chests_opened_count)
	_try_unlock_by_trigger(AchievementData.Trigger.BITS_EARNED, &"", _bits_earned_lifetime)
	_try_unlock_by_trigger(AchievementData.Trigger.CREATURE_LEVEL, &"", CreatureManager.get_level())


func _try_unlock_by_trigger(trigger: AchievementData.Trigger, target: StringName, count: int) -> void:
	for data in ResourceRegistry.get_all_achievements():
		var a: AchievementData = data
		if a.trigger != trigger:
			continue
		if a.trigger_target != &"" and a.trigger_target != &"any" and a.trigger_target != target:
			continue
		if count < a.trigger_count:
			continue
		_unlock_achievement(a)


func _unlock_achievement(a: AchievementData) -> void:
	if _unlocked_achievements.has(a.id) or _unlocked_achievements.has(String(a.id)):
		return
	_unlocked_achievements[a.id] = int(Time.get_unix_time_from_system())
	EventBus.ui_notification_requested.emit("Achievement: %s" % a.display_name, 3.0)
	if a.bits_reward > 0:
		InventoryManager.add_bits(a.bits_reward, true, "Achievement")
	EventBus.sfx_play_requested.emit(&"achievement", Vector3.ZERO)
	DeviceService.notify_event(&"achievement")
