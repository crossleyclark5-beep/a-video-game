class_name CreatureData
extends IdentifiableResource
## Static template for a collectible creature species.

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

@export var rarity: Rarity = Rarity.COMMON
@export var base_stats: Dictionary = {}  ## stat_id -> base value
@export var growth_rates: Dictionary = {}
@export var ability_ids: PackedStringArray = PackedStringArray()
@export var evolution_chain_id: StringName = &""

@export var scene_path: String = ""       ## Battle/overworld creature scene
@export var icon_path: String = ""
@export var capture_rate: float = 0.5

@export var habitat_region_ids: PackedStringArray = PackedStringArray()
