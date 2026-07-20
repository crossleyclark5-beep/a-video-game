extends BaseManager
## Quest progression, objective tracking, and completion rewards.
##
## Listens to gameplay events (items, discovery, chests, NPC talk) and advances
## data-driven QuestData stages. No objectives are hardcoded here.

var _active_quests: Dictionary = {}   ## quest_id -> stage_index
var _completed_quests: Dictionary = {} ## quest_id -> true
var _stage_progress: Dictionary = {} ## quest_id -> count toward current stage


func _initialize_manager() -> void:
	EventBus.item_added.connect(_on_item_added)
	EventBus.location_discovered.connect(_on_location_discovered)
	EventBus.chest_opened.connect(_on_chest_opened)
	EventBus.npc_dialogue_ended.connect(_on_npc_talked)
	_log("QuestManager initialized")


func is_quest_active(quest_id: StringName) -> bool:
	return _active_quests.has(quest_id) or _active_quests.has(String(quest_id))


func is_quest_completed(quest_id: StringName) -> bool:
	return _completed_quests.has(quest_id) or _completed_quests.has(String(quest_id))


func get_quest_stage(quest_id: StringName) -> int:
	return int(_active_quests.get(quest_id, _active_quests.get(String(quest_id), -1)))


func get_active_quest_ids() -> Array:
	return _active_quests.keys()


func get_quest_status_line() -> String:
	if _active_quests.is_empty():
		if not _completed_quests.is_empty():
			return "No active quests"
		return "Talk to the Park Guide to begin"
	var lines: PackedStringArray = PackedStringArray()
	for qid in _active_quests.keys():
		var data: QuestData = ResourceRegistry.get_quest(StringName(str(qid)))
		if data == null:
			continue
		var stage_idx := int(_active_quests[qid])
		var objective := _format_objective(data, stage_idx)
		lines.append("%s: %s" % [data.display_name, objective])
	return "\n".join(lines)


func start_quest(quest_id: StringName) -> bool:
	if is_quest_completed(quest_id) or is_quest_active(quest_id):
		return false
	if not ResourceRegistry.has_id(&"quest", quest_id):
		return false
	var data: QuestData = ResourceRegistry.get_quest(quest_id)
	if data:
		for pre in data.prerequisite_quest_ids:
			if not is_quest_completed(StringName(pre)):
				return false
	_active_quests[quest_id] = 0
	_stage_progress[quest_id] = 0
	EventBus.quest_started.emit(quest_id)
	EventBus.ui_notification_requested.emit("Quest started: %s" % (data.display_name if data else String(quest_id)), 2.5)
	_log("Quest started: %s" % String(quest_id))
	return true


func ensure_starter_quest() -> void:
	## Boot hook — start the tutorial quest once per save.
	if is_quest_active(&"first_steps") or is_quest_completed(&"first_steps"):
		_offer_followups()
		return
	start_quest(&"first_steps")


func _offer_followups() -> void:
	## Side / hidden quests unlock after the tutorial completes (or while active post-start).
	if not is_quest_completed(&"first_steps"):
		return
	for qid in [&"park_explorer", &"secret_seeker", &"spark_snack"]:
		if not is_quest_active(qid) and not is_quest_completed(qid):
			start_quest(qid)


## Generic objective notifier used by interactables and managers.
func notify_objective(objective_type: StringName, target_id: StringName, count: int = 1) -> void:
	if _active_quests.is_empty():
		return
	var completed_now: Array = []
	for qid in _active_quests.keys():
		var quest_id := StringName(str(qid))
		var data: QuestData = ResourceRegistry.get_quest(quest_id)
		if data == null:
			continue
		var stage_idx := int(_active_quests[qid])
		if stage_idx < 0 or stage_idx >= data.stages.size():
			continue
		var stage: Dictionary = data.stages[stage_idx]
		var stype := StringName(str(stage.get("type", stage.get(&"type", ""))))
		var starget := StringName(str(stage.get("target_id", stage.get(&"target_id", ""))))
		var needed := int(stage.get("count", stage.get(&"count", 1)))
		if stype != objective_type:
			continue
		## Empty / "any" target matches all events of that type.
		if starget != &"" and starget != &"any" and starget != target_id:
			continue
		var progress := int(_stage_progress.get(qid, 0)) + count
		_stage_progress[qid] = progress
		EventBus.quest_updated.emit(quest_id, stage_idx)
		if progress >= needed:
			completed_now.append(quest_id)
	for qid in completed_now:
		_advance_quest(qid)


func complete_quest(quest_id: StringName) -> void:
	if not is_quest_active(quest_id):
		return
	_active_quests.erase(quest_id)
	_active_quests.erase(String(quest_id))
	_stage_progress.erase(quest_id)
	_stage_progress.erase(String(quest_id))
	_completed_quests[quest_id] = true
	_grant_quest_rewards(quest_id)
	EventBus.quest_completed.emit(quest_id)
	var data: QuestData = ResourceRegistry.get_quest(quest_id)
	var title := data.display_name if data else String(quest_id)
	EventBus.ui_notification_requested.emit("Quest complete: %s" % title, 3.0)
	CreatureManager.grant_adventure_experience(12)
	_log("Quest completed: %s" % String(quest_id))
	if quest_id == &"first_steps":
		_offer_followups()


func export_state() -> Dictionary:
	return {
		&"active": _active_quests.duplicate(),
		&"completed": _completed_quests.duplicate(),
		&"stage_progress": _stage_progress.duplicate(),
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"active"):
		_active_quests = data[&"active"].duplicate()
	elif data.has("active"):
		_active_quests = data["active"].duplicate()
	if data.has(&"completed"):
		_completed_quests = data[&"completed"].duplicate()
	elif data.has("completed"):
		_completed_quests = data["completed"].duplicate()
	if data.has(&"stage_progress"):
		_stage_progress = data[&"stage_progress"].duplicate()
	elif data.has("stage_progress"):
		_stage_progress = data["stage_progress"].duplicate()


func _advance_quest(quest_id: StringName) -> void:
	var data: QuestData = ResourceRegistry.get_quest(quest_id)
	if data == null:
		return
	var stage_idx := get_quest_stage(quest_id) + 1
	_stage_progress[quest_id] = 0
	if stage_idx >= data.stages.size():
		complete_quest(quest_id)
		return
	_active_quests[quest_id] = stage_idx
	EventBus.quest_updated.emit(quest_id, stage_idx)
	EventBus.ui_notification_requested.emit(
		"Quest updated: %s" % _format_objective(data, stage_idx),
		2.4,
	)


func _grant_quest_rewards(quest_id: StringName) -> void:
	var data: QuestData = ResourceRegistry.get_quest(quest_id)
	if data == null:
		return
	var rewards: Array = []
	for i in data.reward_item_ids.size():
		var iid := StringName(data.reward_item_ids[i])
		var qty := 1
		if i < data.reward_quantities.size():
			qty = int(data.reward_quantities[i])
		rewards.append({"item_id": iid, "quantity": qty})
	InventoryManager.grant_rewards(rewards, data.reward_bits, "Quest reward")


func _format_objective(data: QuestData, stage_idx: int) -> String:
	if stage_idx < 0 or stage_idx >= data.stages.size():
		return "Complete"
	var stage: Dictionary = data.stages[stage_idx]
	var stype := str(stage.get("type", ""))
	var starget := str(stage.get("target_id", "any"))
	var needed := int(stage.get("count", 1))
	var progress := int(_stage_progress.get(data.id, _stage_progress.get(String(data.id), 0)))
	match stype:
		"talk":
			return "Talk to %s (%d/%d)" % [starget, mini(progress, needed), needed]
		"discover", "reach":
			return "Discover %s (%d/%d)" % [starget, mini(progress, needed), needed]
		"collect":
			return "Collect %s (%d/%d)" % [starget, mini(progress, needed), needed]
		"chest", "open_chest":
			return "Open chests (%d/%d)" % [mini(progress, needed), needed]
		"chest_rarity":
			return "Open a %s chest (%d/%d)" % [starget, mini(progress, needed), needed]
		_:
			return "%s %s (%d/%d)" % [stype, starget, mini(progress, needed), needed]


func _on_item_added(item_id: StringName, quantity: int) -> void:
	notify_objective(&"collect", item_id, quantity)


func _on_location_discovered(location_id: StringName) -> void:
	notify_objective(&"discover", location_id, 1)
	notify_objective(&"reach", location_id, 1)


func _on_chest_opened(_chest_id: StringName, rarity: StringName) -> void:
	notify_objective(&"chest", &"any", 1)
	notify_objective(&"open_chest", &"any", 1)
	notify_objective(&"chest_rarity", rarity, 1)
	## Legendary also satisfies a "rare" seeker objective.
	if rarity == &"legendary":
		notify_objective(&"chest_rarity", &"rare", 1)


func _on_npc_talked(npc_id: StringName) -> void:
	notify_objective(&"talk", npc_id, 1)
