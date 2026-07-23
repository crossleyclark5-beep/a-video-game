class_name BiomeDressingRules
extends RefCounted
## Placement rules per biome — density with intent, not random scatter.
## Grassland is live; other biomes are data-ready for future continents.


enum BiomeId {
	GRASSLAND,
	FOREST,
	MOUNTAIN,
	COAST,
	RUINS,
}


static func grassland() -> Dictionary:
	return {
		&"id": BiomeId.GRASSLAND,
		&"label": "Grassland",
		&"forest": {
			&"clump_min": 6,
			&"clump_max": 12,
			&"clearing_chance": 0.22,
			&"fallen_log_chance": 0.35,
			&"mushroom_chance": 0.4,
			&"moss_rock_chance": 0.5,
			&"trail_chance": 0.3,
		},
		&"meadow": {
			&"tall_grass_patches": 18,
			&"flower_clusters": 22,
			&"lone_tree_chance": 0.55,
			&"rock_cluster_chance": 0.4,
			&"dirt_patch_chance": 0.35,
			&"bush_chance": 0.5,
		},
		&"landmark_spacing_m": 180.0,
		&"micro_story_cap": 28,
		&"viewpoint_cap": 10,
		&"trail_marker_spacing_m": 220.0,
	}


static func rules_for(biome: BiomeId) -> Dictionary:
	match biome:
		BiomeId.GRASSLAND:
			return grassland()
		_:
			## Future biomes inherit grassland spacing until authored.
			var r := grassland()
			r[&"id"] = biome
			return r
