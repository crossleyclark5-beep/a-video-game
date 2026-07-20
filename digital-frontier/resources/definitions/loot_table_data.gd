class_name LootTableData
extends IdentifiableResource
## Weighted loot table for encounters, chests, and hex tile drops.

## Entries: [{ "item_id": StringName, "weight": float, "min_qty": int, "max_qty": int }]
@export var entries: Array[Dictionary] = []
@export var rolls: int = 1
