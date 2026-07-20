class_name ItemData
extends IdentifiableResource
## Static definition for an inventory item.

enum ItemType {
	CONSUMABLE,
	MATERIAL,
	KEY_ITEM,
	EQUIPMENT,
	CREATURE_ITEM,
	QUEST_ITEM,
}

enum ShopCategory {
	NONE,           ## Not sold in shops
	CREATURE,       ## Food, toys, training, heal, evolution
	PLAYER,         ## Cosmetics / outfits / accessories
	HOME,           ## Decor / furniture / habitat
	ADVENTURE,      ## Tools / boosts / exploration
}

@export var item_type: ItemType = ItemType.MATERIAL
@export var shop_category: ShopCategory = ShopCategory.NONE
@export var max_stack: int = 99
@export var sell_value: int = 0
@export var buy_value: int = 0
@export var icon_path: String = ""
@export_multiline var shop_blurb: String = ""

## Effect hooks reference system IDs, not inline logic.
@export var use_effect_id: StringName = &""
@export var equip_slot: StringName = &""
@export var is_unique: bool = false  ## Cosmetics / furniture — own once
