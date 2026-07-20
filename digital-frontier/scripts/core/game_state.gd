class_name GameState
extends Resource
## Serializable snapshot of runtime game state.
##
## Managers populate sections of this resource during save.
## Keeps save format decoupled from scene/node structure.

@export var schema_version: int = 1
@export var timestamp_unix: int = 0
@export var playtime_seconds: float = 0.0

@export var current_region_id: StringName = &""
@export var current_hex_coords: Vector3i = Vector3i.ZERO

@export var inventory_data: Dictionary = {}
@export var quest_data: Dictionary = {}
@export var creature_data: Dictionary = {}
@export var npc_data: Dictionary = {}
@export var vehicle_data: Dictionary = {}
@export var world_flags: Dictionary = {}
@export var settings_data: Dictionary = {}
