class_name QuestData
extends IdentifiableResource
## Static quest definition with staged objectives.

enum QuestType {
	MAIN,
	SIDE,
	DAILY,
	HIDDEN,
	EXPLORATION,
	CREATURE,
}

@export var quest_type: QuestType = QuestType.SIDE
@export var prerequisite_quest_ids: PackedStringArray = PackedStringArray()
@export var reward_item_ids: PackedStringArray = PackedStringArray()
@export var reward_quantities: PackedInt32Array = PackedInt32Array()
@export var reward_bits: int = 0

## Each stage is a Dictionary: { "type": "collect"|"talk"|"defeat"|"reach"|"discover"|"chest", "target_id": ..., "count": ... }
@export var stages: Array[Dictionary] = []

@export var start_npc_id: StringName = &""
@export var turn_in_npc_id: StringName = &""
