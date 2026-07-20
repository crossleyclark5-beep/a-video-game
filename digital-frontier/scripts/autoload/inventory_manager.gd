extends BaseManager
## Player inventory state, soft currency (Bits), and reward grants.
##
## Items are data-driven (ItemData). Bits are the collectible soft currency.
## All loot / quest / exploration rewards should go through grant helpers
## so notifications and quest listeners stay consistent.

var _items: Dictionary = {}  ## item_id (StringName/String) -> quantity
var _bits: int = 50  ## Starting pocket change — earn more via chests / discovery


func _initialize_manager() -> void:
	_log("InventoryManager initialized (bits=%d)" % _bits)


func get_quantity(item_id: StringName) -> int:
	return int(_items.get(item_id, _items.get(String(item_id), 0)))


func has_item(item_id: StringName, quantity: int = 1) -> bool:
	return get_quantity(item_id) >= quantity


func get_all_items() -> Dictionary:
	return _items.duplicate()


func get_bits() -> int:
	return _bits


func add_bits(amount: int, notify: bool = true, reason: String = "") -> void:
	if amount == 0:
		return
	_bits = maxi(0, _bits + amount)
	EventBus.bits_changed.emit(_bits, amount)
	EventBus.inventory_changed.emit()
	if notify and amount > 0:
		var msg := "+%d Bits" % amount
		if not reason.is_empty():
			msg += " (%s)" % reason
		EventBus.reward_granted.emit(msg)
		EventBus.ui_notification_requested.emit(msg, 2.0)


func spend_bits(amount: int) -> bool:
	if amount < 0 or _bits < amount:
		return false
	_bits -= amount
	EventBus.bits_changed.emit(_bits, -amount)
	EventBus.inventory_changed.emit()
	return true


func add_item(item_id: StringName, quantity: int = 1, notify: bool = false) -> bool:
	if quantity <= 0:
		return false
	if not ResourceRegistry.has_id(&"item", item_id):
		push_warning("InventoryManager: unknown item '%s'" % String(item_id))
		return false
	var data: ItemData = ResourceRegistry.get_item(item_id)
	var max_stack := 99
	if data:
		max_stack = maxi(1, data.max_stack)
	var current := get_quantity(item_id)
	var next := mini(current + quantity, max_stack)
	var added := next - current
	if added <= 0:
		return false
	_items[item_id] = next
	EventBus.item_added.emit(item_id, added)
	EventBus.inventory_changed.emit()
	if notify:
		var label := String(item_id)
		if data and not data.display_name.is_empty():
			label = data.display_name
		var msg := "Found: %s ×%d" % [label, added]
		EventBus.reward_granted.emit(msg)
		EventBus.ui_notification_requested.emit(msg, 2.2)
	return true


func remove_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0 or not has_item(item_id, quantity):
		return false
	var next := get_quantity(item_id) - quantity
	if next <= 0:
		_items.erase(item_id)
		_items.erase(String(item_id))
	else:
		_items[item_id] = next
	EventBus.item_removed.emit(item_id, quantity)
	EventBus.inventory_changed.emit()
	return true


## Grant a mixed reward bundle (items + optional bits) with one summary toast.
func grant_rewards(rewards: Array, bits: int = 0, reason: String = "") -> String:
	var parts: PackedStringArray = PackedStringArray()
	if bits > 0:
		add_bits(bits, false)
		parts.append("+%d Bits" % bits)
	for entry in rewards:
		if entry is Dictionary:
			var iid := StringName(str(entry.get("item_id", entry.get(&"item_id", ""))))
			var qty := int(entry.get("quantity", entry.get(&"quantity", 1)))
			if iid != &"" and add_item(iid, qty, false):
				var data: ItemData = ResourceRegistry.get_item(iid)
				var label := data.display_name if data and not data.display_name.is_empty() else String(iid)
				parts.append("%s ×%d" % [label, qty])
	var summary := ", ".join(parts)
	if summary.is_empty():
		summary = "Nothing found"
	elif not reason.is_empty():
		summary = "%s — %s" % [reason, summary]
	EventBus.reward_granted.emit(summary)
	EventBus.ui_notification_requested.emit(summary, 2.8)
	return summary


func export_state() -> Dictionary:
	return {
		&"items": _items.duplicate(),
		&"bits": _bits,
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
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
	EventBus.inventory_changed.emit()
	EventBus.bits_changed.emit(_bits, 0)
