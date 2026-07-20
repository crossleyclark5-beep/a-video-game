class_name DiscoverableInteractable
extends Interactable
## Discoverable location / landmark. Prefers DiscoverableData when available.

@export var location_id: StringName = &""
@export var location_name: String = "Point of Interest"
@export_multiline var discover_message: String = ""
@export var bits_reward: int = 10
@export var item_reward_id: StringName = &""
@export var item_reward_qty: int = 0


func _ready() -> void:
	super._ready()
	if location_id == &"":
		location_id = StringName(name.to_snake_case())
	_apply_data_defaults()
	once = false
	prompt_text = "Press E to inspect"
	if WorldManager.is_location_discovered(location_id):
		prompt_text = "Press E to look around"


func _apply_data_defaults() -> void:
	var data: DiscoverableData = ResourceRegistry.get_discoverable(location_id)
	if data == null:
		return
	if location_name == "Point of Interest" or location_name.is_empty():
		location_name = data.display_name
	if discover_message.is_empty():
		discover_message = data.short_blurb if not data.short_blurb.is_empty() else data.description
	if bits_reward == 10 and data.bits_reward != 10:
		bits_reward = data.bits_reward
	elif bits_reward == 10:
		bits_reward = data.bits_reward


func _on_interact(_actor: Node) -> void:
	var first := not WorldManager.is_location_discovered(location_id)
	var data: DiscoverableData = ResourceRegistry.get_discoverable(location_id)
	if first:
		WorldManager.discover_location(location_id, location_name if not location_name.is_empty() else (data.display_name if data else String(location_id)))
		var rewards: Array = []
		var bits := bits_reward
		var xp := 4
		if data:
			bits = data.bits_reward
			xp = data.creature_xp_reward
			for i in data.reward_item_ids.size():
				var iid := StringName(data.reward_item_ids[i])
				var qty := 1
				if i < data.reward_quantities.size():
					qty = int(data.reward_quantities[i])
				rewards.append({"item_id": iid, "quantity": qty})
			## Auto-offer linked side quests when first found.
			for qid in data.linked_quest_ids:
				QuestManager.start_quest(StringName(qid))
		elif item_reward_id != &"" and item_reward_qty > 0:
			rewards.append({"item_id": item_reward_id, "quantity": item_reward_qty})
		var reason := "Discovered: %s" % (data.display_name if data else location_name)
		InventoryManager.grant_rewards(rewards, bits, reason)
		if xp > 0:
			CreatureManager.grant_adventure_experience(xp)
		prompt_text = "Press E to look around"
	var msg := discover_message
	if msg.is_empty() and data:
		msg = data.description
	if msg.is_empty():
		msg = "%s — marked on your explorer notes." % location_name
	EventBus.ui_notification_requested.emit(msg, 3.0 if first else 2.5)
