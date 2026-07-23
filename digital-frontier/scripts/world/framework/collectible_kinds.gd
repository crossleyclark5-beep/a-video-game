class_name CollectibleKinds
extends RefCounted
## Unified collectible vocabulary — Bits, materials, lore, cosmetics, keys…


enum Kind {
	BITS,
	MATERIAL,
	RARE_ITEM,
	CREATURE_DATA,
	PORTAL_UNLOCK,
	COSMETIC,
	KEY,
	LORE,
	CHEST_LOOT,
	SUPPLY,
	CUSTOM,
}


static func id_of(kind: int) -> StringName:
	match kind:
		Kind.BITS: return &"bits"
		Kind.MATERIAL: return &"material"
		Kind.RARE_ITEM: return &"rare_item"
		Kind.CREATURE_DATA: return &"creature_data"
		Kind.PORTAL_UNLOCK: return &"portal_unlock"
		Kind.COSMETIC: return &"cosmetic"
		Kind.KEY: return &"key"
		Kind.LORE: return &"lore"
		Kind.CHEST_LOOT: return &"chest_loot"
		Kind.SUPPLY: return &"supply"
		_: return &"custom"


## Grant through the single inventory / collection path.
static func grant(kind: int, payload: Dictionary) -> void:
	match kind:
		Kind.BITS:
			InventoryManager.add_bits(int(payload.get(&"amount", payload.get("amount", 0))))
		Kind.MATERIAL, Kind.RARE_ITEM, Kind.KEY, Kind.COSMETIC, Kind.SUPPLY, Kind.CHEST_LOOT:
			var item_id: StringName = payload.get(&"item_id", payload.get("item_id", &""))
			var qty := int(payload.get(&"quantity", payload.get("quantity", 1)))
			if item_id != &"":
				InventoryManager.add_item(item_id, qty)
		Kind.CREATURE_DATA:
			## Sighting payload already flows through CollectionManager elsewhere.
			pass
		Kind.LORE:
			var lore_id: StringName = payload.get(&"id", payload.get("id", &"lore"))
			WorldManager.set_world_flag(StringName("lore_%s" % String(lore_id)), true)
			CollectionManager.record_rare_find(
				String(payload.get(&"label", payload.get("label", "Lore"))),
				String(lore_id),
			)
		Kind.PORTAL_UNLOCK:
			var portal: StringName = payload.get(&"portal_id", payload.get("portal_id", &""))
			if portal != &"":
				WorldManager.set_world_flag(StringName("portal_%s" % String(portal)), true)
		_:
			pass
