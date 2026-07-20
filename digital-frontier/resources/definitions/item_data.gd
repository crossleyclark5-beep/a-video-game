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

@export var item_type: ItemType = ItemType.MATERIAL
@export var max_stack: int = 99
@export var sell_value: int = 0
@export var buy_value: int = 0
@export var icon_path: String = ""

## Effect hooks reference system IDs, not inline logic.
@export var use_effect_id: StringName = &""
@export var equip_slot: StringName = &""
