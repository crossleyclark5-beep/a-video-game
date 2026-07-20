class_name CreatureAbilityData
extends IdentifiableResource
## Data-driven companion ability template.
##
## Specs live in data/abilities/*.tres. Runtime uses kind + numbers —
## actors never hardcode forest/water/flight rules.

enum Kind {
	SENSE_SECRETS,   ## Notices rare chests / hidden POIs
	SENSE_NATURE,    ## Future: plants / soft paths
	WATER_AID,       ## Future: water traversal help
	FLIGHT_REACH,    ## Future: high ledges
	CUSTOM,
}

@export var kind: Kind = Kind.SENSE_SECRETS
@export var sense_radius: float = 9.0
@export var cooldown_seconds: float = 10.0
@export var bond_reward: float = 2.5
@export var xp_reward: int = 3
@export var hint_prefix: String = "notices something"
@export var region_tags: PackedStringArray = PackedStringArray()  ## Optional biome filters later
