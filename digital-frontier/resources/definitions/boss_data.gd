class_name BossData
extends IdentifiableResource
## Static boss encounter definition.

@export var creature_id: StringName = &""  ## Base creature template
@export var arena_scene_path: String = ""
@export var phase_count: int = 1
@export var phase_thresholds: PackedFloat32Array = PackedFloat32Array([0.5, 0.25])

@export var region_id: StringName = &""
@export var reward_item_ids: PackedStringArray = PackedStringArray()
@export var reward_quantities: PackedInt32Array = PackedInt32Array()

@export var intro_dialogue_id: StringName = &""
@export var defeat_dialogue_id: StringName = &""
