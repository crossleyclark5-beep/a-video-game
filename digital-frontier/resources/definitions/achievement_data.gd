class_name AchievementData
extends IdentifiableResource
## Simple achievement / milestone definition for the collection journal.

enum Trigger {
	DISCOVER_COUNT,
	CHEST_COUNT,
	QUEST_COMPLETE,
	BITS_EARNED,
	CREATURE_LEVEL,
	RARE_FIND,
	CUSTOM,
}

@export var trigger: Trigger = Trigger.CUSTOM
@export var trigger_target: StringName = &""
@export var trigger_count: int = 1
@export var bits_reward: int = 0
@export var icon_label: String = "★"
