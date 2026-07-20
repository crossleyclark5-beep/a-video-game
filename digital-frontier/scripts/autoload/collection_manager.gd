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
		entries.append({
			&"id": c.id,
			&"name": c.display_name if owned else "????",
			&"description": c.description if owned else "A friend waiting somewhere out there.",
			&"collected": owned,
			&"level": CreatureManager.get_level() if owned and CreatureManager.get_companion_id() == c.id else 0,
		})
	return entries


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
	var ach_unlocked := _unlocked_achievements.size()
	var ach_total := ResourceRegistry.get_all_achievements().size()
	return "Discoveries %d/%d · Creatures %d · Achievements %d/%d" % [
		disc.x, disc.y,
		CreatureManager.get_collection_count(),
		ach_unlocked, maxi(ach_total, 1),
	]


func get_journal_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== EXPLORER LOG ===")
	lines.append(get_summary_line())
	lines.append("")
	lines.append("-- Locations --")
	for e in get_discovery_entries():
		var mark := "✓" if e[&"discovered"] else "·"
		lines.append("%s %s" % [mark, e[&"name"]])
		if e[&"discovered"] and not str(e[&"description"]).is_empty():
			lines.append("   %s" % e[&"description"])
	lines.append("")
	lines.append("-- Creatures --")
	for e in get_creature_entries():
		var mark := "✓" if e[&"collected"] else "·"
		lines.append("%s %s" % [mark, e[&"name"]])
	lines.append("")
	lines.append("-- Pack finds --")
	for e in get_item_entries():
		if e[&"collected"]:
			lines.append("✓ %s ×%d" % [e[&"name"], e[&"quantity"]])
	lines.append("")
	lines.append("-- Rare finds --")
	if _rare_finds.is_empty():
		lines.append("· None yet — check bushes and alleys.")
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
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	_unlocked_achievements = data.get(&"achievements", data.get("achievements", {})).duplicate()
	_rare_finds = data.get(&"rare_finds", data.get("rare_finds", [])).duplicate(true)
	_chests_opened_count = int(data.get(&"chests_opened_count", data.get("chests_opened_count", 0)))
	_bits_earned_lifetime = int(data.get(&"bits_earned_lifetime", data.get("bits_earned_lifetime", 0)))


func _creature_captured(creature_id: StringName) -> bool:
	## Soft check — active companion counts; expand when capture map is public.
	return CreatureManager.get_companion_id() == creature_id


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
