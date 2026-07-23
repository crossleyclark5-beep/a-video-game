class_name LivingWorldCatalog
extends RefCounted
## Biome-aware spawn definitions for wildlife, hostiles, NPCs, and aquatics.
## Grassland is fully populated; other biomes are stubs for future regions.


enum Kind { WILDLIFE, HOSTILE, NPC, AQUATIC }


static func grassland_wildlife() -> Array[Dictionary]:
	return [
		{"id": &"rabbit", "label": "Cotton Rabbit", "color": Color(0.92, 0.88, 0.82), "scale": 0.55, "speed": 3.8, "flee": 9.0, "weight": 3},
		{"id": &"squirrel", "label": "Hex Squirrel", "color": Color(0.72, 0.48, 0.28), "scale": 0.45, "speed": 4.2, "flee": 8.0, "weight": 2},
		{"id": &"bird", "label": "Meadow Bird", "color": Color(0.35, 0.55, 0.95), "scale": 0.4, "speed": 5.5, "flee": 12.0, "weight": 2, "flying": true},
		{"id": &"deer", "label": "Park Deer", "color": Color(0.7, 0.48, 0.28), "scale": 1.05, "speed": 4.5, "flee": 14.0, "weight": 2},
		{"id": &"moose", "label": "Timber Moose", "color": Color(0.45, 0.32, 0.22), "scale": 1.35, "speed": 3.2, "flee": 16.0, "weight": 1},
	]


static func grassland_hostiles() -> Array[Dictionary]:
	return [
		{"id": &"glitchmite", "label": "Glitchmite", "color": Color(0.85, 0.25, 0.55), "scale": 0.7, "speed": 3.4, "hp": 28, "damage": 6, "aggro": 11.0, "bits": 8, "weight": 3},
		{"id": &"bytebat", "label": "Byte Bat", "color": Color(0.35, 0.2, 0.55), "scale": 0.6, "speed": 4.0, "hp": 22, "damage": 5, "aggro": 12.0, "bits": 10, "weight": 2, "flying": true},
		{"id": &"scrubwolf", "label": "Scrub Wolf", "color": Color(0.45, 0.45, 0.5), "scale": 1.0, "speed": 4.6, "hp": 42, "damage": 9, "aggro": 14.0, "bits": 18, "weight": 2},
		{"id": &"thornboar", "label": "Thorn Boar", "color": Color(0.55, 0.35, 0.22), "scale": 1.15, "speed": 3.6, "hp": 55, "damage": 11, "aggro": 10.0, "bits": 24, "weight": 1},
	]


static func grassland_npcs() -> Array[Dictionary]:
	return [
		{
			"id": &"field_ranger",
			"label": "Field Ranger",
			"color": Color(0.25, 0.55, 0.35),
			"role": "explorer",
			"schedule": "field_patrol",
			"lines": PackedStringArray([
				"Keep to the roads until your partner is battle-ready.",
				"Glitchmites nest beyond the meadow — train hard!",
			]),
			"quest_offer": &"field_patrol",
		},
		{
			"id": &"meadow_researcher",
			"label": "Meadow Researcher",
			"color": Color(0.4, 0.55, 0.85),
			"role": "researcher",
			"schedule": "research_walk",
			"lines": PackedStringArray([
				"Wildlife migrates with the digital tide.",
				"Rabbits flee at eight meters — fascinating!",
			]),
			"quest_offer": &"wildlife_watch",
		},
		{
			"id": &"road_merchant",
			"label": "Traveling Merchant",
			"color": Color(0.85, 0.55, 0.25),
			"role": "merchant",
			"schedule": "market_beat",
			"lines": PackedStringArray([
				"Bits for brave explorers — Market Mile has more stock.",
				"Don't feed Glitchmites. Trust me.",
			]),
			"quest_offer": &"",
		},
		{
			"id": &"park_villager",
			"label": "Park Villager",
			"color": Color(0.7, 0.45, 0.55),
			"role": "villager",
			"schedule": "town_loop",
			"lines": PackedStringArray([
				"Pleasant Park feels safer with you around.",
				"My cousin saw a moose near Pine Hollow!",
			]),
			"quest_offer": &"village_shield",
		},
		{
			"id": &"lost_scout",
			"label": "Lost Scout",
			"color": Color(0.55, 0.65, 0.4),
			"role": "explorer",
			"schedule": "story_anchor",
			"pinned": true,
			"lines": PackedStringArray([
				"I… thought the trail markers were lying.",
				"Lights without footprints. Heading north.",
			]),
			"quest_offer": &"",
		},
		{
			"id": &"park_kid",
			"label": "Park Kid",
			"color": Color(0.95, 0.7, 0.45),
			"role": "villager",
			"schedule": "child_play",
			"weight": 2,
			"lines": PackedStringArray([
				"Race you to the fountain!",
				"Mom said be home before the lamps blink.",
			]),
			"quest_offer": &"",
		},
		{
			"id": &"park_guard",
			"label": "Park Guard",
			"color": Color(0.35, 0.4, 0.55),
			"role": "explorer",
			"schedule": "guard_patrol",
			"weight": 2,
			"lines": PackedStringArray([
				"Keep the roads clear — mites push in after dark.",
				"Shift change at dusk. Don't make me chase you.",
			]),
			"quest_offer": &"",
		},
		{
			"id": &"road_carter",
			"label": "Road Carter",
			"color": Color(0.7, 0.5, 0.3),
			"role": "merchant",
			"schedule": "merchant_road",
			"weight": 1,
			"lines": PackedStringArray([
				"Mile to Grove, Grove to Mere — Bits don't walk themselves.",
				"Rain slows the wagon. Fog slows the mind.",
			]),
			"quest_offer": &"",
		},
	]


static func find_npc(id: StringName) -> Dictionary:
	for e in grassland_npcs():
		if e.get("id", &"") == id:
			return e
	return {}


static func grassland_aquatics() -> Array[Dictionary]:
	return [
		{"id": &"silverfin", "label": "Silverfin", "color": Color(0.75, 0.85, 0.95), "scale": 0.45, "speed": 2.4, "hostile": false, "weight": 3},
		{"id": &"ripple_koi", "label": "Ripple Koi", "color": Color(0.95, 0.55, 0.35), "scale": 0.55, "speed": 1.8, "hostile": false, "weight": 2},
		{"id": &"byte_eel", "label": "Byte Eel", "color": Color(0.35, 0.75, 0.55), "scale": 0.7, "speed": 2.8, "hostile": true, "hp": 30, "damage": 7, "bits": 14, "weight": 1},
	]


static func pick_weighted(entries: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var total := 0
	for e in entries:
		total += int(e.get("weight", 1))
	if total <= 0:
		return {}
	var roll := rng.randi_range(1, total)
	var acc := 0
	for e in entries:
		acc += int(e.get("weight", 1))
		if roll <= acc:
			return e
	return entries[0] if not entries.is_empty() else {}
