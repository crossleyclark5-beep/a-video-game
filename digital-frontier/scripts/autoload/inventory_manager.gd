extends BaseManager
## Player inventory state and item operations.
##
## WHY: Items are data-driven (ItemData). InventoryManager owns runtime quantities
## and slot layout; UI and gameplay query it rather than maintaining local copies.

var _items: Dictionary = {}  ## item_id -> quantity


func _initialize_manager() -> void:
	_log("InventoryManager initialized")


func get_quantity(item_id: StringName) -> int:
	return _items.get(item_id, 0)


func has_item(item_id: StringName, quantity: int = 1) -> bool:
	return get_quantity(item_id) >= quantity


func export_state() -> Dictionary:
	return _items.duplicate()


func import_state(data: Dictionary) -> void:
	_items = data.duplicate()


## Stub — implemented when inventory gameplay is added.
func add_item(item_id: StringName, quantity: int = 1) -> bool:
	if not ResourceRegistry.has_id(&"item", item_id):
		return false
	_items[item_id] = get_quantity(item_id) + quantity
	EventBus.item_added.emit(item_id, quantity)
	EventBus.inventory_changed.emit()
	return true
