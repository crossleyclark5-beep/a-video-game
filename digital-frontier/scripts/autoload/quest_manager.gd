extends BaseManager
## Quest progression and objective tracking.
##
## WHY: Quests are authored as QuestData resources. This manager tracks runtime
## progress (active stage, completion) separately from static definitions.

var _active_quests: Dictionary = {}   ## quest_id -> stage_index
var _completed_quests: Dictionary = {} ## quest_id -> true


func _initialize_manager() -> void:
	_log("QuestManager initialized")


func is_quest_active(quest_id: StringName) -> bool:
	return _active_quests.has(quest_id)


func is_quest_completed(quest_id: StringName) -> bool:
	return _completed_quests.has(quest_id)


func get_quest_stage(quest_id: StringName) -> int:
	return _active_quests.get(quest_id, -1)


func export_state() -> Dictionary:
	return {
		&"active": _active_quests.duplicate(),
		&"completed": _completed_quests.duplicate(),
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"active"):
		_active_quests = data[&"active"].duplicate()
	if data.has(&"completed"):
		_completed_quests = data[&"completed"].duplicate()


func start_quest(quest_id: StringName) -> bool:
	if not ResourceRegistry.has_id(&"quest", quest_id):
		return false
	_active_quests[quest_id] = 0
	EventBus.quest_started.emit(quest_id)
	return true
