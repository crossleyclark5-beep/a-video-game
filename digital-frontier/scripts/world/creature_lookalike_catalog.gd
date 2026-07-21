class_name CreatureLookalikeCatalog
extends RefCounted
## Digimon-inspired Digital Frontier creature roster — original retro kits only.
## Bandai/Toei Digimon meshes are rejected. Display names mirror the requested
## fantasy; silhouettes are DF pixel-toon look-alikes.


enum Role { COMPANION, ENEMY, BOSS }

## id -> { role, display, blurb, color, accent, scale }
const CREATURES: Dictionary = {
	## --- Companions (good) ---
	&"companion_tentomon": {
		"role": Role.COMPANION, "display": "Tentomon", "blurb": "Ladybug-shell scout with buzzing wings.",
		"color": Color(0.85, 0.22, 0.18), "accent": Color(0.15, 0.15, 0.18), "scale": 0.85,
	},
	&"companion_agumon": {
		"role": Role.COMPANION, "display": "Agumon", "blurb": "Sunny orange hatchling dino — loyal field partner.",
		"color": Color(0.98, 0.55, 0.18), "accent": Color(0.98, 0.92, 0.75), "scale": 0.9,
	},
	&"companion_gatomon": {
		"role": Role.COMPANION, "display": "Gatomon", "blurb": "White angel-cat with a glowing holy ring.",
		"color": Color(0.96, 0.96, 0.98), "accent": Color(0.95, 0.82, 0.25), "scale": 0.8,
	},
	&"companion_gabumon": {
		"role": Role.COMPANION, "display": "Gabumon", "blurb": "Blue pelt-pup wrapped in warm fur armor.",
		"color": Color(0.45, 0.65, 0.95), "accent": Color(0.95, 0.88, 0.7), "scale": 0.88,
	},
	&"companion_biyomon": {
		"role": Role.COMPANION, "display": "Biyomon", "blurb": "Rose-pink songbird with cheerful crest.",
		"color": Color(0.95, 0.45, 0.55), "accent": Color(0.98, 0.85, 0.35), "scale": 0.75,
	},
	&"companion_gomamon": {
		"role": Role.COMPANION, "display": "Gomamon", "blurb": "Surf seal with orange tufts and beach grit.",
		"color": Color(0.92, 0.92, 0.95), "accent": Color(0.98, 0.55, 0.2), "scale": 0.85,
	},
	## --- Enemies (bad) ---
	&"enemy_junkmon": {
		"role": Role.ENEMY, "display": "Junkmon", "blurb": "Scrap-heap crawler of broken code.",
		"color": Color(0.55, 0.55, 0.5), "accent": Color(0.85, 0.55, 0.15), "scale": 0.85,
	},
	&"enemy_gazimon": {
		"role": Role.ENEMY, "display": "Gazimon", "blurb": "Purple fox-bat pest with a mean streak.",
		"color": Color(0.55, 0.28, 0.65), "accent": Color(0.95, 0.85, 0.3), "scale": 0.8,
	},
	&"enemy_impmon": {
		"role": Role.ENEMY, "display": "Impmon", "blurb": "Little shadow imp with mischief horns.",
		"color": Color(0.35, 0.12, 0.4), "accent": Color(0.95, 0.35, 0.2), "scale": 0.7,
	},
	&"enemy_koromon": {
		"role": Role.ENEMY, "display": "Koromon", "blurb": "Pink puff with oversized ears — still bites.",
		"color": Color(0.95, 0.55, 0.7), "accent": Color(0.98, 0.85, 0.9), "scale": 0.65,
	},
	&"enemy_chuumon": {
		"role": Role.ENEMY, "display": "Chuumon", "blurb": "Sneaky mouse thief of Bits and snacks.",
		"color": Color(0.75, 0.55, 0.4), "accent": Color(0.95, 0.9, 0.85), "scale": 0.55,
	},
	&"enemy_hagurumon": {
		"role": Role.ENEMY, "display": "Hagurumon", "blurb": "Spinning gear-sphere of rusty ticks.",
		"color": Color(0.7, 0.55, 0.25), "accent": Color(0.4, 0.4, 0.42), "scale": 0.75,
	},
	&"enemy_numemon": {
		"role": Role.ENEMY, "display": "Numemon", "blurb": "Slug of swamp data — slimy and stubborn.",
		"color": Color(0.45, 0.55, 0.35), "accent": Color(0.7, 0.75, 0.4), "scale": 0.9,
	},
	&"enemy_datamon": {
		"role": Role.ENEMY, "display": "Datamon", "blurb": "Cube-headed lab construct with laser glare.",
		"color": Color(0.55, 0.75, 0.85), "accent": Color(0.95, 0.35, 0.25), "scale": 0.95,
	},
	&"enemy_bakemon": {
		"role": Role.ENEMY, "display": "Bakemon", "blurb": "Sheet ghost of deleted files.",
		"color": Color(0.92, 0.92, 0.95), "accent": Color(0.15, 0.15, 0.18), "scale": 0.95,
	},
	&"enemy_frigimon": {
		"role": Role.ENEMY, "display": "Frigimon", "blurb": "Snow-puff bruiser with icy mittens.",
		"color": Color(0.9, 0.95, 1.0), "accent": Color(0.55, 0.75, 0.95), "scale": 1.05,
	},
	&"enemy_monzaemon": {
		"role": Role.ENEMY, "display": "Monzaemon", "blurb": "Oversized teddy with a sinister zipper smile.",
		"color": Color(0.85, 0.7, 0.4), "accent": Color(0.95, 0.35, 0.45), "scale": 1.2,
	},
	&"enemy_gotsumon": {
		"role": Role.ENEMY, "display": "Gotsumon", "blurb": "Rock-kid with pebble armor plates.",
		"color": Color(0.55, 0.5, 0.45), "accent": Color(0.7, 0.65, 0.55), "scale": 0.8,
	},
	&"enemy_icemon": {
		"role": Role.ENEMY, "display": "Icemon", "blurb": "Crystal sibling of stone — frozen edges.",
		"color": Color(0.65, 0.85, 1.0), "accent": Color(0.9, 0.97, 1.0), "scale": 0.85,
	},
	&"enemy_pumpkinmon": {
		"role": Role.ENEMY, "display": "Pumpkinmon", "blurb": "Jack-o lantern body with vine limbs.",
		"color": Color(0.95, 0.55, 0.12), "accent": Color(0.25, 0.55, 0.2), "scale": 1.1,
	},
	&"enemy_digitamamon": {
		"role": Role.ENEMY, "display": "Digitamamon", "blurb": "Egg-shell chef of chaotic recipes.",
		"color": Color(0.95, 0.92, 0.85), "accent": Color(0.35, 0.25, 0.2), "scale": 1.0,
	},
	## --- Bosses (bad) ---
	&"boss_andromon": {
		"role": Role.BOSS, "display": "Andromon", "blurb": "Chrome android guardian with laser core.",
		"color": Color(0.55, 0.6, 0.7), "accent": Color(0.95, 0.35, 0.25), "scale": 1.8,
	},
	&"boss_devimon": {
		"role": Role.BOSS, "display": "Devimon", "blurb": "Winged shadow demon of Pine Hollow nights.",
		"color": Color(0.2, 0.1, 0.28), "accent": Color(0.85, 0.2, 0.35), "scale": 1.9,
	},
	&"boss_orgemon": {
		"role": Role.BOSS, "display": "Orgemon", "blurb": "Ogre bruiser with a spiked club fist.",
		"color": Color(0.35, 0.65, 0.35), "accent": Color(0.85, 0.55, 0.2), "scale": 2.0,
	},
	&"boss_snimon": {
		"role": Role.BOSS, "display": "Snimon", "blurb": "Mantis blade insect of the corn belts.",
		"color": Color(0.45, 0.75, 0.35), "accent": Color(0.9, 0.9, 0.85), "scale": 1.85,
	},
	&"boss_meramon": {
		"role": Role.BOSS, "display": "Meramon", "blurb": "Living flame titan — heat-wave boss.",
		"color": Color(0.95, 0.4, 0.12), "accent": Color(1.0, 0.85, 0.25), "scale": 1.9,
	},
	&"boss_whamon": {
		"role": Role.BOSS, "display": "Whamon", "blurb": "Vast digital whale — tide boss of Mere.",
		"color": Color(0.35, 0.55, 0.85), "accent": Color(0.85, 0.9, 1.0), "scale": 2.4,
	},
}


static func has_creature(id: StringName) -> bool:
	return CREATURES.has(id)


static func creature_def(id: StringName) -> Dictionary:
	return CREATURES.get(id, {})


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in CREATURES.keys():
		out.append(k)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


static func ids_for_role(role: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in CREATURES.keys():
		if int(CREATURES[id].get("role", -1)) == role:
			out.append(id)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


static func companion_ids() -> Array[StringName]:
	return ids_for_role(Role.COMPANION)


static func enemy_ids() -> Array[StringName]:
	return ids_for_role(Role.ENEMY)


static func boss_ids() -> Array[StringName]:
	return ids_for_role(Role.BOSS)


static func display_name(id: StringName) -> String:
	return String(creature_def(id).get("display", id))
