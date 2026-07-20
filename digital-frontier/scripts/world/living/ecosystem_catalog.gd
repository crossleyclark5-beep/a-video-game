class_name EcosystemCatalog
extends RefCounted
## Digital Frontier wild species — rarity, behavior, day/night, weather, biome.
## Grassland is fully live; other biomes expose stubs for future regions.


enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY, MYTHICAL }
enum Temperament { PASSIVE, DEFENSIVE, AGGRESSIVE, PACK, PREDATOR }
enum Biome { GRASSLAND, FOREST, MOUNTAIN, DESERT, OCEAN, SWAMP, ICE }


static func rarity_label(r: int) -> String:
	match r:
		Rarity.UNCOMMON: return "Uncommon"
		Rarity.RARE: return "Rare"
		Rarity.LEGENDARY: return "Legendary"
		Rarity.MYTHICAL: return "Mythical"
		_: return "Common"


static func temperament_label(t: int) -> String:
	match t:
		Temperament.DEFENSIVE: return "Defensive"
		Temperament.AGGRESSIVE: return "Aggressive"
		Temperament.PACK: return "Pack"
		Temperament.PREDATOR: return "Predator"
		_: return "Passive"


## Active windows use WorldAtmosphere.Phase ints: 0 morning, 1 afternoon, 2 evening, 3 night.
## Empty array = all phases.
static func grassland_species() -> Array[Dictionary]:
	return [
		_sp(&"cotton_rabbit", "Cotton Rabbit", "Soft meadow hopper — first friend of many explorers.",
			Rarity.COMMON, Temperament.PASSIVE, Biome.GRASSLAND,
			Color(0.92, 0.88, 0.82), 0.55, 3.8, 9.0, 3,
			[0, 1], [], false, 0, 0, 0),
		_sp(&"hex_squirrel", "Hex Squirrel", "Chatters in oak belts and steals shiny Bits.",
			Rarity.COMMON, Temperament.DEFENSIVE, Biome.FOREST,
			Color(0.72, 0.48, 0.28), 0.45, 4.2, 8.0, 2,
			[0, 1, 2], [], false, 0, 0, 0),
		_sp(&"meadow_bird", "Meadow Bird", "Morning song maps the grassland roads.",
			Rarity.COMMON, Temperament.PASSIVE, Biome.GRASSLAND,
			Color(0.35, 0.55, 0.95), 0.4, 5.5, 12.0, 3,
			[0, 1], [], true, 0, 0, 0),
		_sp(&"park_deer", "Park Deer", "Grazes clearings; bolts if the Field Unit beeps too loud.",
			Rarity.UNCOMMON, Temperament.DEFENSIVE, Biome.GRASSLAND,
			Color(0.7, 0.48, 0.28), 1.05, 4.5, 14.0, 2,
			[0, 1], [&"rain_hide"], false, 0, 0, 0),
		_sp(&"timber_moose", "Timber Moose", "Lone giant of Pine Hollow evenings.",
			Rarity.RARE, Temperament.PASSIVE, Biome.FOREST,
			Color(0.45, 0.32, 0.22), 1.35, 3.2, 16.0, 1,
			[1, 2], [], false, 0, 0, 0),
		_sp(&"glow_kit", "Glow Kit", "Dusk fox-kit whose tail paints soft cyan trails.",
			Rarity.UNCOMMON, Temperament.PASSIVE, Biome.GRASSLAND,
			Color(0.95, 0.55, 0.35), 0.65, 4.0, 10.0, 2,
			[2, 3], [&"fog_boost"], false, 0, 0, 0),
		_sp(&"lunamoth", "Lunamoth", "Night wings over Mirror Mere — rare and gentle.",
			Rarity.RARE, Temperament.PASSIVE, Biome.GRASSLAND,
			Color(0.75, 0.85, 1.0), 0.5, 3.5, 11.0, 1,
			[3], [&"fog_boost"], true, 0, 0, 0),
		_sp(&"pack_pup", "Pack Pup", "Travels in threes; warns friends with a chirp.",
			Rarity.UNCOMMON, Temperament.PACK, Biome.GRASSLAND,
			Color(0.85, 0.75, 0.55), 0.7, 4.1, 11.0, 2,
			[0, 1, 2], [], false, 0, 0, 0),
		_sp(&"glitchmite", "Glitchmite", "Static pest that nests beyond meadow roads.",
			Rarity.COMMON, Temperament.AGGRESSIVE, Biome.GRASSLAND,
			Color(0.85, 0.25, 0.55), 0.7, 3.4, 11.0, 3,
			[1, 2, 3], [&"storm_boost"], false, 28, 6, 8),
		_sp(&"byte_bat", "Byte Bat", "Night flyer; loves fog banks and cave mouths.",
			Rarity.UNCOMMON, Temperament.AGGRESSIVE, Biome.MOUNTAIN,
			Color(0.35, 0.2, 0.55), 0.6, 4.0, 12.0, 2,
			[3], [&"fog_boost", &"storm_boost"], true, 22, 5, 10),
		_sp(&"scrub_wolf", "Scrub Wolf", "Pack predator that patrols prairie overlooks.",
			Rarity.UNCOMMON, Temperament.PREDATOR, Biome.GRASSLAND,
			Color(0.45, 0.45, 0.5), 1.0, 4.6, 14.0, 2,
			[2, 3], [&"storm_boost"], false, 42, 9, 18),
		_sp(&"thorn_boar", "Thorn Boar", "Guards berry thickets; charges when threatened.",
			Rarity.RARE, Temperament.AGGRESSIVE, Biome.FOREST,
			Color(0.55, 0.35, 0.22), 1.15, 3.6, 10.0, 1,
			[1, 2], [&"rain_hide"], false, 55, 11, 24),
		_sp(&"phantom_hare", "Phantom Hare", "Mythical dusk mirage — vanishes if you blink.",
			Rarity.MYTHICAL, Temperament.DEFENSIVE, Biome.GRASSLAND,
			Color(0.7, 0.9, 1.0), 0.6, 5.8, 18.0, 1,
			[2, 3], [&"fog_boost"], false, 0, 0, 0),
		_sp(&"ridge_goat", "Ridge Goat", "Mountain stub — sure-footed on west ridges.",
			Rarity.UNCOMMON, Temperament.PASSIVE, Biome.MOUNTAIN,
			Color(0.8, 0.78, 0.7), 0.9, 3.3, 12.0, 1,
			[0, 1], [], false, 0, 0, 0),
	]


static func biome_stub_species(biome: Biome) -> Array[Dictionary]:
	## Future region hooks — not spawned in Grassland unless biome matches.
	match biome:
		Biome.DESERT:
			return [_sp(&"sand_skitter", "Sand Skitter", "Heat-adapted desert runner.", Rarity.COMMON, Temperament.DEFENSIVE, Biome.DESERT, Color(0.9, 0.75, 0.4), 0.5, 4.5, 10.0, 2, [1], [], false, 0, 0, 0)]
		Biome.OCEAN:
			return [_sp(&"tide_drifter", "Tide Drifter", "Ocean floater for future coasts.", Rarity.COMMON, Temperament.PASSIVE, Biome.OCEAN, Color(0.4, 0.7, 0.9), 0.7, 2.0, 8.0, 2, [0, 1], [], false, 0, 0, 0)]
		Biome.SWAMP:
			return [_sp(&"mire_wisp", "Mire Wisp", "Poison-glow swamp haunt.", Rarity.RARE, Temperament.AGGRESSIVE, Biome.SWAMP, Color(0.4, 0.7, 0.35), 0.55, 3.0, 9.0, 1, [3], [&"fog_boost"], false, 35, 8, 16)]
		Biome.ICE:
			return [_sp(&"frost_puff", "Frost Puff", "Cold-resistant ice plains fluff.", Rarity.UNCOMMON, Temperament.PASSIVE, Biome.ICE, Color(0.85, 0.92, 1.0), 0.6, 2.8, 10.0, 2, [0, 1], [], false, 0, 0, 0)]
		_:
			return []


static func grassland_boss() -> Dictionary:
	return {
		"id": &"hollow_warden",
		"label": "Hollow Warden",
		"blurb": "Ancient pine guardian. Not a bigger Glitchmite — a rooted storm of bark and code.",
		"color": Color(0.25, 0.45, 0.28),
		"accent": Color(0.95, 0.75, 0.2),
		"scale": 2.2,
		"speed": 2.8,
		"hp": 180,
		"damage": 14,
		"bits": 120,
		"home": "pine_hollow",
	}


static func pick_for_conditions(
	entries: Array[Dictionary],
	phase: int,
	weather: StringName,
	rng: RandomNumberGenerator,
	hostile_bias: bool = false,
) -> Dictionary:
	var pool: Array[Dictionary] = []
	for e in entries:
		if not _phase_ok(e, phase):
			continue
		if not _weather_ok(e, weather):
			continue
		var temper: int = int(e.get("temperament", Temperament.PASSIVE))
		var is_hostile := temper == Temperament.AGGRESSIVE or temper == Temperament.PREDATOR
		if hostile_bias and not is_hostile:
			continue
		if not hostile_bias and is_hostile:
			continue
		## Rarity weight: common heavy, mythical rare.
		var w := int(e.get("weight", 1))
		match int(e.get("rarity", Rarity.COMMON)):
			Rarity.UNCOMMON: w = maxi(1, w)
			Rarity.RARE: w = maxi(1, int(ceil(float(w) * 0.55)))
			Rarity.LEGENDARY: w = 1
			Rarity.MYTHICAL: w = 1 if rng.randf() < 0.35 else 0
		if w <= 0:
			continue
		## Storm boosts hostiles.
		if weather == &"storm" and is_hostile:
			w += 2
		## Fog boosts rare tags.
		if weather == &"fog" and e.get("tags", []).has(&"fog_boost"):
			w += 2
		for _i in w:
			pool.append(e)
	if pool.is_empty():
		return {}
	return pool[rng.randi_range(0, pool.size() - 1)]


static func _phase_ok(e: Dictionary, phase: int) -> bool:
	var phases: Array = e.get("phases", [])
	if phases.is_empty():
		return true
	return phases.has(phase)


static func _weather_ok(e: Dictionary, weather: StringName) -> bool:
	var tags: Array = e.get("tags", [])
	if weather == &"rain" and tags.has(&"rain_hide"):
		## Still can appear, but rarer — handled by weight skip chance.
		return true
	return true


static func _sp(
	id: StringName, label: String, blurb: String,
	rarity: int, temperament: int, biome: int,
	color: Color, scale_v: float, speed: float, flee: float, weight: int,
	phases: Array, tags: Array, flying: bool,
	hp: int, damage: int, bits: int,
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"blurb": blurb,
		"rarity": rarity,
		"temperament": temperament,
		"biome": biome,
		"color": color,
		"scale": scale_v,
		"speed": speed,
		"flee": flee,
		"weight": weight,
		"phases": phases,
		"tags": tags,
		"flying": flying,
		"hp": hp,
		"damage": damage,
		"bits": bits,
		"habitat": _biome_name(biome),
	}


static func _biome_name(b: int) -> String:
	match b:
		Biome.FOREST: return "Forest"
		Biome.MOUNTAIN: return "Mountain"
		Biome.DESERT: return "Desert"
		Biome.OCEAN: return "Ocean"
		Biome.SWAMP: return "Swamp"
		Biome.ICE: return "Ice"
		_: return "Grassland"


static func find_species(id: StringName) -> Dictionary:
	for e in grassland_species():
		if e.get("id", &"") == id:
			return e
	var boss := grassland_boss()
	if boss.get("id", &"") == id:
		return boss
	return {}
