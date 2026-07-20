class_name ChestInteractable
extends Interactable
## Loot chest using the shared Interactable contract.

@export var loot_item_id: StringName = &"hex_shard"
@export var loot_quantity: int = 1


func _ready() -> void:
	super._ready()
	once = true
	prompt_text = "Press E to open chest"


func _on_interact(_actor: Node) -> void:
	InventoryManager.add_item(loot_item_id, loot_quantity)
	for child in get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).modulate = Color(0.45, 0.45, 0.45)
	prompt_text = "Empty"
	EventBus.ui_notification_requested.emit("Found loot: %s x%d" % [String(loot_item_id), loot_quantity], 2.0)
	EventBus.item_added.emit(loot_item_id, loot_quantity)
