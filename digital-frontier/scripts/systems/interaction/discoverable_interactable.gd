class_name DiscoverableInteractable
extends Interactable
## Discoverable location / landmark. First visit grants Bits and a world flag.

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
	once = false  ## Can re-read, but discovery reward is once.
	prompt_text = "Press E to inspect"
	if WorldManager.is_location_discovered(location_id):
		prompt_text = "Press E to look around"


func _on_interact(_actor: Node) -> void:
	var first := not WorldManager.is_location_discovered(location_id)
	if first:
		WorldManager.discover_location(location_id, location_name)
		var rewards: Array = []
		if item_reward_id != &"" and item_reward_qty > 0:
			rewards.append({"item_id": item_reward_id, "quantity": item_reward_qty})
		var reason := "Discovered: %s" % location_name
		InventoryManager.grant_rewards(rewards, bits_reward, reason)
		prompt_text = "Press E to look around"
	var msg := discover_message
	if msg.is_empty():
		msg = "%s — marked on your explorer notes." % location_name
	if not first:
		EventBus.ui_notification_requested.emit(msg, 2.5)
	else:
		## grant_rewards already toasted; append flavor shortly via message.
		EventBus.ui_notification_requested.emit(msg, 3.0)
