extends BaseManager
## Player inventory state, soft currency (Bits), ledger, and reward grants.
##
## Items are data-driven (ItemData). Bits are the collectible soft currency.
## Transaction history prepares Bits for shop / skins / homes / vehicles.

const MAX_LEDGER_ENTRIES := 80

var _items: Dictionary = {}  ## item_id (StringName/String) -> quantity
var _bits: int = 50  ## Starting pocket change — earn more via chests / discovery
var _bits_earned_total: int = 0
var _bits_spent_total: int = 0
var _ledger: Array = []  ## newest last: {unix, delta, balance, reason, category}


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


func get_bits_earned_total() -> int:
	return _bits_earned_total


func get_bits_spent_total() -> int:
	return _bits_spent_total


func get_ledger(limit: int = 20) -> Array:
	if limit <= 0 or _ledger.size() <= limit:
		return _ledger.duplicate(true)
	return _ledger.slice(_ledger.size() - limit, _ledger.size())


func get_ledger_summary_text(limit: int = 12) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Bits: %d  (earned %d · spent %d)" % [_bits, _bits_earned_total, _bits_spent_total])
	lines.append("-- Recent --")
	var entries := get_ledger(limit)
	if entries.is_empty():
		lines.append("No transactions yet.")
	else:
		for i in range(entries.size() - 1, -1, -1):
			var e: Dictionary = entries[i]
			var delta := int(e.get("delta", 0))
			var sign := "+" if delta >= 0 else ""
			lines.append("%s%d  %s  [%s]" % [sign, delta, str(e.get("reason", "")), str(e.get("category", "misc"))])
	return "\n".join(lines)


func add_bits(amount: int, notify: bool = true, reason: String = "", category: String = "earn") -> void:
	if amount == 0:
		return
	_bits = maxi(0, _bits + amount)
	if amount > 0:
		_bits_earned_total += amount
	_record_transaction(amount, reason if not reason.is_empty() else "Bits gained", category)
	EventBus.bits_changed.emit(_bits, amount)
	EventBus.inventory_changed.emit()
	if notify and amount > 0:
		var msg := "+%d Bits" % amount
		if not reason.is_empty():
			msg += " (%s)" % reason
		EventBus.reward_granted.emit(msg)
		EventBus.ui_notification_requested.emit(msg, 2.0)
		EventBus.sfx_play_requested.emit(&"bits_gain", Vector3.ZERO)


func spend_bits(amount: int, reason: String = "Purchase", category: String = "spend") -> bool:
	if amount < 0 or _bits < amount:
		return false
	_bits -= amount
	_bits_spent_total += amount
	_record_transaction(-amount, reason, category)
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
		add_bits(bits, false, reason, "reward")
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


func get_pack_text() -> String:
	if _items.is_empty():
		return "Pack empty\nBits: %d" % _bits
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Bits: %d" % _bits)
	for key in _items.keys():
		var data: ItemData = ResourceRegistry.get_item(StringName(str(key)))
		var label := data.display_name if data and not data.display_name.is_empty() else str(key)
		lines.append("%s × %s" % [label, str(_items[key])])
	return "\n".join(lines)


func export_state() -> Dictionary:
	return {
		&"items": _items.duplicate(),
		&"bits": _bits,
		&"bits_earned_total": _bits_earned_total,
		&"bits_spent_total": _bits_spent_total,
		&"ledger": _ledger.duplicate(true),
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	if data.has(&"items") or data.has("items"):
		_items = data.get(&"items", data.get("items", {})).duplicate()
		_bits = int(data.get(&"bits", data.get("bits", _bits)))
	else:
		_items = data.duplicate()
		_items.erase(&"bits")
		_items.erase("bits")
		_items.erase(&"bits_earned_total")
		_items.erase("bits_earned_total")
		_items.erase(&"bits_spent_total")
		_items.erase("bits_spent_total")
		_items.erase(&"ledger")
		_items.erase("ledger")
		if data.has(&"bits"):
			_bits = int(data[&"bits"])
		elif data.has("bits"):
			_bits = int(data["bits"])
	_bits_earned_total = int(data.get(&"bits_earned_total", data.get("bits_earned_total", _bits_earned_total)))
	_bits_spent_total = int(data.get(&"bits_spent_total", data.get("bits_spent_total", _bits_spent_total)))
	_ledger = data.get(&"ledger", data.get("ledger", [])).duplicate(true)
	EventBus.inventory_changed.emit()
	EventBus.bits_changed.emit(_bits, 0)


func reset_state() -> void:
	_items.clear()
	_bits = 50
	_bits_earned_total = 0
	_bits_spent_total = 0
	_ledger.clear()
	EventBus.inventory_changed.emit()
	EventBus.bits_changed.emit(_bits, 0)


func _record_transaction(delta: int, reason: String, category: String) -> void:
	_ledger.append({
		"unix": int(Time.get_unix_time_from_system()),
		"delta": delta,
		"balance": _bits,
		"reason": reason,
		"category": category,
	})
	while _ledger.size() > MAX_LEDGER_ENTRIES:
		_ledger.pop_front()
