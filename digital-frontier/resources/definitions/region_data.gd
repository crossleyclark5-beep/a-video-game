class_name RegionData
extends IdentifiableResource
## Static definition for an overworld region.
##
## Regions contain hex grids, spawn tables, music, and connections to neighbors.
## Runtime state (discovered tiles, cleared bosses) lives in WorldManager/SaveManager.

@export var hex_width: int = 32
@export var hex_height: int = 32
@export var hex_size: float = 1.0
@export var hex_orientation: StringName = &"pointy"

@export var scene_path: String = ""  ## res://scenes/world/regions/<region>.tscn
@export var music_track_id: StringName = &""
@export var ambient_sfx_id: StringName = &""

## Neighbor region IDs for seamless transitions at hex borders.
@export var neighbor_regions: PackedStringArray = PackedStringArray()

## Hex coordinate -> tile data path or embedded tile overrides.
@export var tile_overrides: Dictionary = {}

## Spawn tables reference creature/item IDs with weights (see tables/ loot_tables).
@export var creature_spawn_table_id: StringName = &""
@export var weather_profile_id: StringName = &""
