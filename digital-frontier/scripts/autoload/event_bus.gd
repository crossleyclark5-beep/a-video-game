extends Node
## Global signal bus for decoupled cross-system communication.
##
## WHY: Direct manager-to-manager calls create tight coupling and circular dependencies.
## EventBus lets any system emit or listen without knowing the publisher/subscriber.
##
## RULES:
## - Signals are named by domain (world_, quest_, inventory_, etc.).
## - Payloads use typed parameters; avoid passing entire node references when an ID suffices.
## - Do NOT put gameplay logic here — only signal declarations.

# --- Bootstrap & scenes ---
signal bootstrap_completed
signal scene_transition_started(from_scene: StringName, to_scene: StringName)
signal scene_transition_finished(scene: StringName)

# --- World & regions ---
signal region_load_requested(region_id: StringName)
signal region_loaded(region_id: StringName)
signal region_unloaded(region_id: StringName)
signal hex_tile_entered(region_id: StringName, hex_coords: Vector3i)
signal building_enter_requested(building_id: StringName)
signal building_interior_loaded(building_id: StringName)
signal location_discovered(location_id: StringName)
signal chest_opened(chest_id: StringName, rarity: StringName)

# --- Save / load ---
signal save_requested(slot: int)
signal save_completed(slot: int, success: bool)
signal load_requested(slot: int)
signal load_completed(slot: int, success: bool)

# --- Inventory ---
signal item_added(item_id: StringName, quantity: int)
signal item_removed(item_id: StringName, quantity: int)
signal inventory_changed
signal bits_changed(total: int, delta: int)
signal reward_granted(summary: String)

# --- Quests ---
signal quest_started(quest_id: StringName)
signal quest_updated(quest_id: StringName, stage: int)
signal quest_completed(quest_id: StringName)

# --- Creatures ---
signal creature_captured(creature_id: StringName)
signal creature_released(instance_id: StringName)
signal party_changed
signal companion_state_changed
signal companion_cared(action: StringName)
signal companion_noticed(target_id: StringName, kind: StringName)
signal companion_helped(target_id: StringName, kind: StringName)

# --- NPCs ---
signal npc_dialogue_started(npc_id: StringName)
signal npc_dialogue_ended(npc_id: StringName)
signal npc_state_changed(npc_id: StringName)

# --- Vehicles ---
signal vehicle_entered(vehicle_id: StringName)
signal vehicle_exited(vehicle_id: StringName)

# --- UI ---
signal ui_modal_opened(modal_id: StringName)
signal ui_modal_closed(modal_id: StringName)
signal ui_notification_requested(message: String, duration: float)

# --- Audio ---
signal music_change_requested(track_id: StringName)
signal sfx_play_requested(sfx_id: StringName, position: Vector3)

# --- Debug ---
signal debug_command_executed(command: String, args: PackedStringArray)
