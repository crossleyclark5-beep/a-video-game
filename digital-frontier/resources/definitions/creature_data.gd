class_name CreatureData
extends IdentifiableResource
## Static template for a collectible creature species.
##
## Runtime companions are CreatureInstance objects created from this template.
## Keep gameplay numbers here — never hardcode them on the actor.

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

@export var rarity: Rarity = Rarity.COMMON
@export var base_stats: Dictionary = {}  ## stat_id -> base value
@export var growth_rates: Dictionary = {}  ## stat_id -> per-level growth
@export var ability_ids: PackedStringArray = PackedStringArray()
@export var evolution_chain_id: StringName = &""
@export var max_evolution_stage: int = 0
## Display names per evolution stage (0 = base). Falls back to display_name.
@export var stage_display_names: PackedStringArray = PackedStringArray()
## Level required to unlock stage 1, stage 2, ...
@export var evolve_level_thresholds: PackedInt32Array = PackedInt32Array()
## Friendship required alongside level for each stage unlock.
@export var evolve_friendship_thresholds: PackedInt32Array = PackedInt32Array()

@export var scene_path: String = ""       ## Battle/overworld creature scene
@export var icon_path: String = ""
@export var capture_rate: float = 0.5

## Adventure partner defaults (overworld follower).
@export var follow_distance: float = 1.85
@export var follow_lag: float = 0.35
@export var sense_radius_bonus: float = 0.0
@export var adventure_bond_on_discover: float = 1.5
@export var adventure_bond_on_chest: float = 2.0

@export var habitat_region_ids: PackedStringArray = PackedStringArray()

## Visual / animation profile ids — resolve to skins & anim sets later.
@export var default_skin_id: StringName = &"default"
@export var available_skin_ids: PackedStringArray = PackedStringArray(["default"])
@export var visual_profile_id: StringName = &"emberling"
@export var anim_set_id: StringName = &"companion_default"

## Flavor for journals / Field Unit (optional).
@export_multiline var lore_blurb: String = ""
@export var likes: PackedStringArray = PackedStringArray()
@export var dislikes: PackedStringArray = PackedStringArray()
@export var habitat_blurb: String = ""
@export var favorite_activities: PackedStringArray = PackedStringArray()

## Personality defaults (0–100). Copied onto new CreatureInstance.
@export var default_personality: Dictionary = {
	"playful": 55.0,
	"curious": 60.0,
	"affectionate": 50.0,
	"lazy": 35.0,
	"brave": 45.0,
}

## Optional care affinity multipliers (action -> float).
@export var care_affinities: Dictionary = {
	"feed": 1.0,
	"play": 1.0,
	"rest": 1.0,
	"train": 1.0,
	"pet": 1.0,
}

## Primary silhouette tint for procedural placeholder visuals.
@export var body_color: Color = Color(0.45, 0.82, 0.85)
@export var accent_color: Color = Color(0.95, 0.55, 0.45)
@export var core_color: Color = Color(0.7, 0.95, 1.0)
