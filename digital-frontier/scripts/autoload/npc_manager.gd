extends BaseManager
## NPC runtime state (dialogue progress, schedules, disposition).
##
## WHY: NPCData defines static identity; NPCManager tracks per-save changes
## (which dialogue branches seen, quest-giver availability, shop inventory).

var _npc_states: Dictionary = {}  ## npc_id -> Dictionary


func _initialize_manager() -> void:
	_log("NPCManager initialized")


func get_npc_state(npc_id: StringName) -> Dictionary:
	if not _npc_states.has(npc_id):
		_npc_states[npc_id] = {}
	return _npc_states[npc_id]


func export_state() -> Dictionary:
	return _npc_states.duplicate(true)


func import_state(data: Dictionary) -> void:
	_npc_states = data.duplicate(true)
