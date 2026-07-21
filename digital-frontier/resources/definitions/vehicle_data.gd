class_name VehicleData
extends IdentifiableResource
## Static vehicle definition — cars, trucks, boats, aircraft, story craft.


enum VehicleClass {
	GROUND,
	WATER,
	AIR,
	HYBRID,
}

@export var vehicle_class: VehicleClass = VehicleClass.GROUND
@export var scene_path: String = ""
@export var max_speed: float = 18.0
@export var acceleration: float = 14.0
@export var brake_force: float = 22.0
@export var reverse_speed: float = 7.0
@export var turn_rate: float = 2.4  ## radians/sec at full lock while moving
@export var coast_friction: float = 6.0
@export var offroad_mul: float = 0.72
@export var camera_zoom: float = 18.0
@export var camera_follow: Vector3 = Vector3(0.0, 26.0, 20.0)
@export var camera_look_ahead: float = 3.2
@export var visual_prop_id: StringName = &""  ## ExternalPropCatalog id when using curated GLB
@export var body_color: Color = Color(0.75, 0.25, 0.22)
@export var exit_offset: Vector3 = Vector3(2.2, 0.0, 0.4)
@export var can_own: bool = true
@export var starter_unlock: bool = false

## Terrain tile categories this vehicle can traverse (HexTileData.TileCategory values).
@export var allowed_terrain: PackedInt32Array = PackedInt32Array()

@export var unlock_quest_id: StringName = &""
@export var fuel_item_id: StringName = &""
