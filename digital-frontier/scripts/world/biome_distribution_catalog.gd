class_name BiomeDistributionCatalog
extends RefCounted
## Creature Distribution Plan — every species assigned to biomes / chapters.
## Only Grassland is spawn-live today; other biomes are database-ready.
## Digimon / franchise meshes stay rejected — IDs are DF look-alike silhouettes.


enum Biome {
	GRASSLAND,
	FOREST,
	SWAMP,
	MOUNTAIN,
	SNOW,
	DESERT,
	VOLCANIC,
	ANCIENT_RUINS,
	DIGITAL_CITY,
	SKY_ISLANDS,
	OCEAN,
	DARK_LANDS,
	ENDGAME,
}


static func biome_label(b: int) -> String:
	match b:
		Biome.FOREST: return "Forest"
		Biome.SWAMP: return "Swamp"
		Biome.MOUNTAIN: return "Mountains"
		Biome.SNOW: return "Snow"
		Biome.DESERT: return "Desert"
		Biome.VOLCANIC: return "Volcanic Region"
		Biome.ANCIENT_RUINS: return "Ancient Ruins"
		Biome.DIGITAL_CITY: return "Digital City"
		Biome.SKY_ISLANDS: return "Sky Islands"
		Biome.OCEAN: return "Ocean"
		Biome.DARK_LANDS: return "Dark Lands"
		Biome.ENDGAME: return "Endgame Regions"
		_: return "Grasslands"


static func all_biomes() -> Array[int]:
	return [
		Biome.GRASSLAND, Biome.FOREST, Biome.SWAMP, Biome.MOUNTAIN, Biome.SNOW,
		Biome.DESERT, Biome.VOLCANIC, Biome.ANCIENT_RUINS, Biome.DIGITAL_CITY,
		Biome.SKY_ISLANDS, Biome.OCEAN, Biome.DARK_LANDS, Biome.ENDGAME,
	]


## id -> { biomes, role, chapter, notes }
## chapter 1 = Grassland intro; higher = later story.
const DISTRIBUTION: Dictionary = {
	## Grassland wildlife (early teaching set)
	&"cotton_rabbit": {"biomes": [Biome.GRASSLAND], "role": &"wildlife", "chapter": 1, "notes": "First friend hopper"},
	&"meadow_bird": {"biomes": [Biome.GRASSLAND], "role": &"wildlife", "chapter": 1, "notes": "Morning songbird"},
	&"park_deer": {"biomes": [Biome.GRASSLAND], "role": &"wildlife", "chapter": 1, "notes": "Clearing grazer"},
	&"glow_kit": {"biomes": [Biome.GRASSLAND], "role": &"wildlife", "chapter": 1, "notes": "Dusk fox-kit"},
	&"pack_pup": {"biomes": [Biome.GRASSLAND], "role": &"wildlife", "chapter": 1, "notes": "Pack chirper"},
	&"lunamoth": {"biomes": [Biome.GRASSLAND], "role": &"wildlife", "chapter": 1, "notes": "Night rarity"},
	&"phantom_hare": {"biomes": [Biome.GRASSLAND], "role": &"wildlife", "chapter": 1, "notes": "Mythical dusk mirage"},
	## Future wildlife
	&"hex_squirrel": {"biomes": [Biome.FOREST], "role": &"wildlife", "chapter": 2, "notes": "Oak belt chatter"},
	&"timber_moose": {"biomes": [Biome.FOREST], "role": &"wildlife", "chapter": 2, "notes": "Pine giant"},
	&"thorn_boar": {"biomes": [Biome.FOREST], "role": &"enemy", "chapter": 2, "notes": "Berry thicket charger"},
	&"ridge_goat": {"biomes": [Biome.MOUNTAIN], "role": &"wildlife", "chapter": 3, "notes": "Sure-footed ridge"},
	&"byte_bat": {"biomes": [Biome.MOUNTAIN, Biome.ANCIENT_RUINS], "role": &"enemy", "chapter": 3, "notes": "Cave mouth flyer"},
	&"scrub_wolf": {"biomes": [Biome.MOUNTAIN], "role": &"enemy", "chapter": 3, "notes": "Overlook predator"},
	&"sand_skitter": {"biomes": [Biome.DESERT], "role": &"wildlife", "chapter": 4, "notes": "Heat runner"},
	&"tide_drifter": {"biomes": [Biome.OCEAN], "role": &"wildlife", "chapter": 4, "notes": "Coast floater"},
	&"mire_wisp": {"biomes": [Biome.SWAMP], "role": &"enemy", "chapter": 3, "notes": "Poison glow"},
	&"frost_puff": {"biomes": [Biome.SNOW], "role": &"wildlife", "chapter": 4, "notes": "Ice plains fluff"},
	## Grassland beginner enemies only
	&"glitchmite": {"biomes": [Biome.GRASSLAND], "role": &"enemy", "chapter": 1, "notes": "Static pest — tutorial hostile"},
	&"enemy_koromon": {"biomes": [Biome.GRASSLAND], "role": &"enemy", "chapter": 1, "notes": "Soft pink puff"},
	&"enemy_chuumon": {"biomes": [Biome.GRASSLAND], "role": &"enemy", "chapter": 1, "notes": "Bit thief mouse"},
	&"enemy_gazimon": {"biomes": [Biome.GRASSLAND], "role": &"enemy", "chapter": 1, "notes": "Mean fox-bat — late Grassland"},
	## Later enemies
	&"enemy_junkmon": {"biomes": [Biome.DESERT, Biome.DIGITAL_CITY], "role": &"enemy", "chapter": 4, "notes": "Scrap crawler"},
	&"enemy_impmon": {"biomes": [Biome.DARK_LANDS], "role": &"enemy", "chapter": 5, "notes": "Shadow imp"},
	&"enemy_hagurumon": {"biomes": [Biome.DIGITAL_CITY, Biome.ANCIENT_RUINS], "role": &"enemy", "chapter": 5, "notes": "Gear sphere"},
	&"enemy_numemon": {"biomes": [Biome.SWAMP], "role": &"enemy", "chapter": 3, "notes": "Swamp slug"},
	&"enemy_datamon": {"biomes": [Biome.DIGITAL_CITY, Biome.ANCIENT_RUINS], "role": &"enemy", "chapter": 5, "notes": "Lab cube"},
	&"enemy_bakemon": {"biomes": [Biome.DARK_LANDS, Biome.SWAMP], "role": &"enemy", "chapter": 5, "notes": "Sheet ghost"},
	&"enemy_frigimon": {"biomes": [Biome.SNOW], "role": &"enemy", "chapter": 4, "notes": "Snow bruiser"},
	&"enemy_monzaemon": {"biomes": [Biome.ENDGAME, Biome.DARK_LANDS], "role": &"enemy", "chapter": 6, "notes": "Sinister teddy"},
	&"enemy_gotsumon": {"biomes": [Biome.MOUNTAIN, Biome.ANCIENT_RUINS], "role": &"enemy", "chapter": 3, "notes": "Rock-kid"},
	&"enemy_icemon": {"biomes": [Biome.SNOW, Biome.MOUNTAIN], "role": &"enemy", "chapter": 4, "notes": "Crystal sibling"},
	&"enemy_pumpkinmon": {"biomes": [Biome.FOREST, Biome.SWAMP], "role": &"enemy", "chapter": 2, "notes": "Jack-o vine"},
	&"enemy_digitamamon": {"biomes": [Biome.ENDGAME, Biome.DIGITAL_CITY], "role": &"enemy", "chapter": 6, "notes": "Egg chef chaos"},
	## Grassland chapter bosses (only these spawn in chapter 1)
	&"glitch_alpha": {"biomes": [Biome.GRASSLAND], "role": &"mini_boss", "chapter": 1, "notes": "Grassland mini-boss"},
	&"hollow_warden": {"biomes": [Biome.GRASSLAND], "role": &"boss", "chapter": 1, "notes": "Grassland major boss — Pine Hollow"},
	## Future biome bosses — database only
	&"boss_snimon": {"biomes": [Biome.FOREST], "role": &"boss", "chapter": 2, "notes": "Mantis of the deep wood"},
	&"boss_orgemon": {"biomes": [Biome.MOUNTAIN], "role": &"boss", "chapter": 3, "notes": "Ogre of the high ridges"},
	&"boss_whamon": {"biomes": [Biome.OCEAN], "role": &"boss", "chapter": 4, "notes": "Tide whale"},
	&"boss_meramon": {"biomes": [Biome.VOLCANIC], "role": &"boss", "chapter": 4, "notes": "Flame titan"},
	&"boss_andromon": {"biomes": [Biome.DIGITAL_CITY, Biome.ANCIENT_RUINS], "role": &"boss", "chapter": 5, "notes": "Chrome android"},
	&"boss_devimon": {"biomes": [Biome.DARK_LANDS], "role": &"boss", "chapter": 5, "notes": "Winged shadow"},
	## Companions available in Grassland partner select
	&"companion_agumon": {"biomes": [Biome.GRASSLAND], "role": &"companion", "chapter": 1, "notes": "Orange hatchling partner"},
	&"companion_gabumon": {"biomes": [Biome.GRASSLAND, Biome.SNOW], "role": &"companion", "chapter": 1, "notes": "Pelt-pup partner"},
	&"companion_biyomon": {"biomes": [Biome.GRASSLAND, Biome.SKY_ISLANDS], "role": &"companion", "chapter": 1, "notes": "Songbird partner"},
	&"companion_tentomon": {"biomes": [Biome.GRASSLAND, Biome.FOREST], "role": &"companion", "chapter": 1, "notes": "Ladybug scout partner"},
	&"companion_gomamon": {"biomes": [Biome.GRASSLAND, Biome.OCEAN], "role": &"companion", "chapter": 1, "notes": "Surf seal partner"},
	&"companion_gatomon": {"biomes": [Biome.GRASSLAND, Biome.ANCIENT_RUINS], "role": &"companion", "chapter": 1, "notes": "Holy-ring cat partner"},
	&"emberling": {"biomes": [Biome.GRASSLAND], "role": &"companion", "chapter": 1, "notes": "Legacy DF mascot (data kept)"},
	&"sparkbit": {"biomes": [Biome.DIGITAL_CITY], "role": &"companion", "chapter": 5, "notes": "Later digital companion"},
	&"tidepup": {"biomes": [Biome.OCEAN], "role": &"companion", "chapter": 4, "notes": "Later ocean companion"},
}

## Beginner lookalike hostiles that may spawn in live Grassland.
const GRASSLAND_LOOKALIKE_ENEMIES: Array[StringName] = [
	&"enemy_koromon",
	&"enemy_chuumon",
	&"enemy_gazimon",
]


static func has_entry(id: StringName) -> bool:
	return DISTRIBUTION.has(id)


static func entry(id: StringName) -> Dictionary:
	return DISTRIBUTION.get(id, {})


static func biomes_for(id: StringName) -> Array:
	return entry(id).get("biomes", []) as Array


static func primary_biome(id: StringName) -> int:
	var b: Array = biomes_for(id)
	if b.is_empty():
		return Biome.GRASSLAND
	return int(b[0])


static func belongs_to_biome(id: StringName, biome: int) -> bool:
	return biomes_for(id).has(biome)


static func ids_for_biome(biome: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in DISTRIBUTION.keys():
		if belongs_to_biome(id, biome):
			out.append(id)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


static func ids_for_role_in_biome(biome: int, role: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in ids_for_biome(biome):
		if entry(id).get("role", &"") == role:
			out.append(id)
	return out


static func chapter_for(id: StringName) -> int:
	return int(entry(id).get("chapter", 99))


static func grassland_live_enemy_ids() -> Array[StringName]:
	return GRASSLAND_LOOKALIKE_ENEMIES.duplicate()


static func habitat_label_for(id: StringName) -> String:
	return biome_label(primary_biome(id))


static func summary_by_biome() -> Dictionary:
	var out: Dictionary = {}
	for b in all_biomes():
		out[biome_label(b)] = {
			&"wildlife": ids_for_role_in_biome(b, &"wildlife"),
			&"enemy": ids_for_role_in_biome(b, &"enemy"),
			&"boss": ids_for_role_in_biome(b, &"boss"),
			&"mini_boss": ids_for_role_in_biome(b, &"mini_boss"),
			&"companion": ids_for_role_in_biome(b, &"companion"),
		}
	return out
