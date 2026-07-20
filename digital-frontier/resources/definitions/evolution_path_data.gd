class_name EvolutionPathData
extends IdentifiableResource
## One possible evolution branch for a partner species.
## Different raising styles unlock different forms of the same creature.

@export var species_id: StringName = &""
@export var from_stage: int = 0
@export var to_stage: int = 1
@export var form_display_name: String = ""
@export_multiline var blurb: String = ""

@export var need_level: int = 8
@export var need_friendship: float = 35.0
@export var need_battles_won: int = 0
@export var need_training_style: StringName = &""  ## care | train | explore | battle | ""
@export var need_trait: StringName = &""  ## brave, playful, …
@export var need_trait_min: float = 0.0
@export var need_memory_id: StringName = &""
@export var need_world_flag: StringName = &""

## Soft growth bias applied on evolve (stat -> multiplier).
@export var stat_bias: Dictionary = {
	"hp": 1.0,
	"attack": 1.0,
	"defense": 1.0,
	"speed": 1.0,
}

@export var priority: int = 0  ## Higher wins when multiple paths qualify.
