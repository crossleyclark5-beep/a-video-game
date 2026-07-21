extends BaseManager
## Handheld shop: catalog browse, purchase, use. Bits via InventoryManager.

const SHOP_ID_HOME := &"field_unit_shop"
const SHOP_ID_MILE := &"market_mile_shop"

## item_id -> true for unique cosmetics / furniture owned (also mirrored in inventory qty).
var _owned_uniques: Dictionary = {}
var _equipped: Dictionary = {}  ## slot -> item_id


func _initialize_manager() -> void:
	_log("ShopManager initialized")


func get_catalog(shop_id: StringName = SHOP_ID_HOME) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for item in ResourceRegistry.get_all_items():
		var data: ItemData = item
		if data == null or data.shop_category == ItemData.ShopCategory.NONE:
			continue
		## Character roster entries stay visible even at 0 Bits (earn / starter).
		var is_character := data.equip_slot == CharacterOutfitCatalog.EQUIP_SLOT
		if data.buy_value <= 0 and not is_character:
			continue
		## Mile stock skews adventure + creature; home has full catalog.
		if shop_id == SHOP_ID_MILE and data.shop_category == ItemData.ShopCategory.HOME:
			continue
		out.append(data)
	out.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		if a.shop_category != b.shop_category:
			return int(a.shop_category) < int(b.shop_category)
		return a.buy_value < b.buy_value
	)
	return out


func get_catalog_by_category(category: ItemData.ShopCategory, shop_id: StringName = SHOP_ID_HOME) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for data in get_catalog(shop_id):
		if data.shop_category == category:
			out.append(data)
	return out


func category_label(cat: ItemData.ShopCategory) -> String:
	match cat:
		ItemData.ShopCategory.CREATURE:
			return "CREATURE"
		ItemData.ShopCategory.PLAYER:
			return "PLAYER"
		ItemData.ShopCategory.HOME:
			return "HOME"
		ItemData.ShopCategory.ADVENTURE:
			return "ADVENTURE"
		_:
			return "ALL"


func can_buy(item_id: StringName) -> bool:
	var data: ItemData = ResourceRegistry.get_item(item_id)
	if data == null:
		return false
	if data.equip_slot == CharacterOutfitCatalog.EQUIP_SLOT and data.buy_value <= 0:
		return false
	if data.buy_value <= 0:
		return false
	if data.is_unique and is_owned_unique(item_id):
		return false
	return InventoryManager.get_bits() >= data.buy_value


func buy(item_id: StringName) -> String:
	var data: ItemData = ResourceRegistry.get_item(item_id)
	if data == null:
		return "Unknown item."
	if data.shop_category == ItemData.ShopCategory.NONE:
		return "Not for sale."
	if data.equip_slot == CharacterOutfitCatalog.EQUIP_SLOT and data.buy_value <= 0:
		if is_owned_unique(item_id):
			return equip_item(item_id)
		return CharacterRosterManager.earn_hint(item_id)
	if data.buy_value <= 0:
		return "Not for sale."
	if data.is_unique and is_owned_unique(item_id):
		return "Already owned."
	if not InventoryManager.spend_bits(data.buy_value, "Bought %s" % data.display_name, "shop"):
		return "Not enough Bits. Need %d." % data.buy_value
	InventoryManager.add_item(item_id, 1, false)
	if data.is_unique:
		_owned_uniques[item_id] = true
	if data.equip_slot == CharacterOutfitCatalog.EQUIP_SLOT:
		CharacterRosterManager.unlock(item_id, false)
		equip_item(item_id)
	EventBus.sfx_play_requested.emit(&"bits_gain", Vector3.ZERO)
	EventBus.ui_notification_requested.emit("Purchased: %s (−%d Bits)" % [data.display_name, data.buy_value], 2.4)
	return "Bought %s!" % data.display_name


func is_owned_unique(item_id: StringName) -> bool:
	if bool(_owned_uniques.get(item_id, false)):
		return true
	return InventoryManager.has_item(item_id, 1)


func use_item(item_id: StringName) -> String:
	var data: ItemData = ResourceRegistry.get_item(item_id)
	if data == null:
		return "Unknown item."
	if not InventoryManager.has_item(item_id, 1):
		return "You don't have that."
	if data.use_effect_id == &"":
		if data.is_unique and data.equip_slot != &"":
			return equip_item(item_id)
		return "Can't use that here."
	var msg := _apply_effect(data.use_effect_id, data)
	if msg.begins_with("FAIL:"):
		return msg.trim_prefix("FAIL:")
	## Consumables spend a charge.
	if data.item_type == ItemData.ItemType.CONSUMABLE or data.item_type == ItemData.ItemType.CREATURE_ITEM:
		if not data.is_unique:
			InventoryManager.remove_item(item_id, 1)
	EventBus.inventory_changed.emit()
	return msg


func equip_item(item_id: StringName) -> String:
	var data: ItemData = ResourceRegistry.get_item(item_id)
	if data == null or data.equip_slot == &"":
		return "Not equippable."
	if not InventoryManager.has_item(item_id, 1):
		return "You don't have that."
	set_equipped_slot(data.equip_slot, item_id)
	if data.equip_slot == CharacterOutfitCatalog.EQUIP_SLOT:
		CharacterRosterManager.note_equipped(item_id)
	EventBus.inventory_changed.emit()
	return "Equipped %s." % data.display_name


func set_equipped_slot(slot: StringName, item_id: StringName) -> void:
	_equipped[slot] = item_id


func get_equipped(slot: StringName) -> StringName:
	return StringName(str(_equipped.get(slot, &"")))


func get_owned_item_ids() -> Array[StringName]:
	## Shop-relevant pack contents (bought / usable / equippable).
	var out: Array[StringName] = []
	for key in InventoryManager.get_all_items().keys():
		var iid := StringName(str(key))
		if InventoryManager.get_quantity(iid) <= 0:
			continue
		var data: ItemData = ResourceRegistry.get_item(iid)
		if data == null:
			continue
		if data.shop_category != ItemData.ShopCategory.NONE or data.use_effect_id != &"" or data.equip_slot != &"":
			out.append(iid)
	out.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
	return out


func get_owned_summary() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Bits: %d" % InventoryManager.get_bits())
	lines.append("-- Pack --")
	lines.append(InventoryManager.get_pack_text())
	if not _equipped.is_empty():
		lines.append("-- Equipped --")
		for slot in _equipped.keys():
			var iid: StringName = StringName(str(_equipped[slot]))
			var d: ItemData = ResourceRegistry.get_item(iid)
			var label := d.display_name if d else String(iid)
			lines.append("%s: %s" % [String(slot), label])
	return "\n".join(lines)


func _apply_effect(effect_id: StringName, _data: ItemData) -> String:
	match effect_id:
		&"feed_boost":
			var m := CreatureManager.feed()
			CreatureManager.pet()
			return "Fed treat! %s" % m
		&"play_boost":
			return CreatureManager.play()
		&"train_boost":
			return CreatureManager.train()
		&"rest_boost":
			return CreatureManager.rest()
		&"heal_boost":
			var m2 := CreatureManager.rest()
			## Also restore field HP when exploring.
			var healed_player := false
			var tree := Engine.get_main_loop() as SceneTree
			if tree:
				for n in tree.get_nodes_in_group(&"player_health"):
					if n.has_method("heal"):
						n.call("heal", 45.0)
						healed_player = true
			if healed_player:
				return "Field Salve — partner rested and you recovered HP!"
			return "Healing glow. %s" % m2
		&"adventure_ration":
			return "Packed trail rations — ready for the road."
		&"luck_charm":
			return "Charm equipped vibe — discoveries feel luckier."
		_:
			return "FAIL:No effect for %s." % String(effect_id)


func export_state() -> Dictionary:
	return {
		&"owned_uniques": _owned_uniques.duplicate(),
		&"equipped": _equipped.duplicate(),
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	_owned_uniques = data.get(&"owned_uniques", data.get("owned_uniques", {})).duplicate()
	_equipped = data.get(&"equipped", data.get("equipped", {})).duplicate()


func reset_state() -> void:
	_owned_uniques.clear()
	_equipped.clear()
