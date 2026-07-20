class_name VehicleData
extends IdentifiableResource
## Static vehicle definition (speed, terrain, scene).

enum VehicleClass {
	GROUND,
	WATER,
	AIR,
	HYBRID,
}

@export var vehicle_class: VehicleClass = VehicleClass.GROUND
@export var scene_path: String = ""
@export var max_speed: float = 10.0
@export var acceleration: float = 5.0

## Terrain tile categories this vehicle can traverse (HexTileData.TileCategory values).
@export var allowed_terrain: PackedInt32Array = PackedInt32Array()

@export var unlock_quest_id: StringName = &""
@export var fuel_item_id: StringName = &""
