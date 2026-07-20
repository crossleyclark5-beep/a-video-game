class_name BuildingData
extends IdentifiableResource
## Static definition for an enterable building.

enum BuildingType {
	RESIDENTIAL,
	SHOP,
	QUEST_HUB,
	DUNGEON,
	WAREHOUSE,
	CUSTOM,
}

@export var building_type: BuildingType = BuildingType.RESIDENTIAL
@export var interior_scene_path: String = ""  ## Loaded additively on enter
@export var exterior_scene_path: String = ""  ## Placed on hex grid
@export var region_id: StringName = &""
@export var hex_coords: Vector3i = Vector3i.ZERO

@export var required_quest_id: StringName = &""  ## Empty = always accessible
@export var npc_ids: PackedStringArray = PackedStringArray()
