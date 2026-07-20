class_name DiscoverableData
extends IdentifiableResource
## Data-driven discoverable location / landmark / secret.
##
## Scene DiscoverableInteractables should reference location_id matching this id.
## Rewards and flavor live here so new locations can be added without code changes.

enum Category {
	LANDMARK,
	SECRET,
	HIDDEN,
	REGION,
}

@export var category: Category = Category.LANDMARK
@export var region_id: StringName = &"pleasant_park"
@export_multiline var short_blurb: String = ""
@export var bits_reward: int = 10
@export var reward_item_ids: PackedStringArray = PackedStringArray()
@export var reward_quantities: PackedInt32Array = PackedInt32Array()
@export var linked_quest_ids: PackedStringArray = PackedStringArray()
@export var encounter_id: StringName = &""
@export var map_hint: String = ""
@export var is_secret: bool = false
@export var creature_xp_reward: int = 4
