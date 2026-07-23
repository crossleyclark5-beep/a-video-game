class_name WorldSaveSchema
extends RefCounted
## Save schema contract — versioned, expandable with future content.
## GameState.schema_version tracks the on-disk integer; this documents sections.


const CURRENT_VERSION := 4
const MIN_SUPPORTED := 1

## Section keys expected inside GameState / manager exports.
const SECTION_INVENTORY := &"inventory_data"
const SECTION_QUEST := &"quest_data"
const SECTION_CREATURE := &"creature_data"
const SECTION_NPC := &"npc_data"
const SECTION_VEHICLE := &"vehicle_data"
const SECTION_WORLD := &"world_flags"
const SECTION_COLLECTION := &"collection_data"
const SECTION_SHOP := &"shop_data"
const SECTION_ROSTER := &"character_roster_data"
const SECTION_SETTINGS := &"settings_data"
const SECTION_FRAMEWORK := &"framework_data"


static func section_keys() -> Array[StringName]:
	return [
		SECTION_INVENTORY, SECTION_QUEST, SECTION_CREATURE, SECTION_NPC,
		SECTION_VEHICLE, SECTION_WORLD, SECTION_COLLECTION, SECTION_SHOP,
		SECTION_ROSTER, SECTION_SETTINGS, SECTION_FRAMEWORK,
	]


static func migrate(state: GameState) -> GameState:
	## Forward-compatible migrations. Never drop unknown keys silently in managers.
	if state == null:
		return state
	if state.schema_version < CURRENT_VERSION:
		if state.framework_data == null:
			state.framework_data = {}
		state.schema_version = CURRENT_VERSION
	return state


static func describe() -> Dictionary:
	return {
		&"version": CURRENT_VERSION,
		&"min_supported": MIN_SUPPORTED,
		&"sections": section_keys(),
		&"notes": "Player, companions, world flags, discoveries, NPC memory, quests, settings, framework meta.",
	}
