class_name HexTileData
extends IdentifiableResource
## Definition for a single hex tile type (terrain, passability, visuals).

enum TileCategory {
	GRASS,
	WATER,
	MOUNTAIN,
	ROAD,
	URBAN,
	INTERIOR_ENTRANCE,
	CUSTOM,
}

@export var category: TileCategory = TileCategory.GRASS
@export var is_walkable: bool = true
@export var movement_cost: float = 1.0
@export var elevation: float = 0.0

@export var mesh_scene_path: String = ""   ## 3D mesh for 2.5D rendering
@export var texture_path: String = ""      ## Fallback 2D sprite/top-down tile

## Optional links to content placed on this tile type.
@export var building_id: StringName = &""
@export var encounter_table_id: StringName = &""
