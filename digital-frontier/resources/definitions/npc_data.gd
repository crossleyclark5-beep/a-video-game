class_name NPCData
extends IdentifiableResource
## Static NPC identity and default behavior profile.

enum NPCRole {
	VILLAGER,
	MERCHANT,
	QUEST_GIVER,
	TRAINER,
	BOSS_CONTACT,
	CUSTOM,
	RESEARCHER,
	EXPLORER,
	STORY,
}

@export var role: NPCRole = NPCRole.VILLAGER
@export var scene_path: String = ""
@export var portrait_path: String = ""
@export var dialogue_tree_id: StringName = &""
@export var schedule_id: StringName = &""  ## References data/tables/npc_schedules
@export var shop_inventory_id: StringName = &""

@export var region_id: StringName = &""
@export var default_hex_coords: Vector3i = Vector3i.ZERO
