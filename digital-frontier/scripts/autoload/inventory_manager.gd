extends BaseManager
## Player inventory state and item operations.
##
## WHY: Items are data-driven (ItemData). InventoryManager owns runtime quantities
## and slot layout; UI and gameplay query it rather than maintaining local copies.

var _items: Dictionary = {}  ## item_id -> quantity
var _bits: int = 120  ## Soft currency foundation for shop / care items later.


func _initialize_manager() -> void:
	_log("InventoryManager initialized")


func get_quantity(item_id: StringName) -> int:
	return _items.get(item_id, 0)


func has_item(item_id: StringName, quantity: int = 1) -> bool:
	return get_quantity(item_id) >= quantity


func get_bits() -> int:
	return _bits


func add_bits(amount: int) -> void:
	_bits = maxi(0, _bits + amount)
	EventBus.inventory_changed.emit()


func spend_bits(amount: int) -> bool:
	if amount < 0 or _bits < amount:
		return false
	_bits -= amount
	EventBus.inventory_changed.emit()
	return true


func export_state() -> Dictionary:
	return {
		&"items": _items.duplicate(),
		&"bits": _bits,
	}


func import_state(data: Dictionary) -> void:
	## Backward compatible with older saves that stored a flat item map.
	if data.has(&"items"):
		_items = data[&"items"].duplicate()
		_bits = int(data.get(&"bits", _bits))
	elif data.has("items"):
		_items = data["items"].duplicate()
		_bits = int(data.get("bits", _bits))
	else:
		_items = data.duplicate()
		_items.erase(&"bits")
		_items.erase("bits")
		if data.has(&"bits"):
			_bits = int(data[&"bits"])
		elif data.has("bits"):
			_bits = int(data["bits"])


## Stub — implemented when inventory gameplay is added.
func add_item(item_id: StringName, quantity: int = 1) -> bool:
	if not ResourceRegistry.has_id(&"item", item_id):
		return false
	_items[item_id] = get_quantity(item_id) + quantity
	EventBus.item_added.emit(item_id, quantity)
	EventBus.inventory_changed.emit()
	return true
