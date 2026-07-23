class_name CharacterOutfitCatalog
extends RefCounted
## Item Shop character roster — DF retro look-alikes with healthy unlock progression.
## Majority buyable; some gated by story / quests / Bits / achievements.

## unlock: starter | shop | earn | gate
## gate_flag: world flag required before shop purchase
## gate_bits: lifetime Bits earned required
## quest: earn unlock on quest complete
const OUTFITS: Dictionary = {
	&"char_jonesy": {
		"mesh": &"hero_a",
		"tint": Color(0.92, 0.78, 0.55),
		"accent": Color(0.25, 0.45, 0.85),
		"prop": &"cap",
		"unlock": &"starter",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"field_agent",
		"blurb": "Starter — retro field agent.",
	},
	&"char_indiana": {
		"mesh": &"npc_explorer",
		"tint": Color(0.72, 0.48, 0.28),
		"accent": Color(0.35, 0.22, 0.12),
		"prop": &"hat",
		"unlock": &"shop",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"relic_runner",
		"blurb": "Shop — fedora relic runner.",
	},
	&"char_8ball": {
		"mesh": &"hero_c",
		"tint": Color(0.12, 0.12, 0.14),
		"accent": Color(0.95, 0.95, 0.98),
		"prop": &"orb",
		"unlock": &"shop",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"cue_ball",
		"blurb": "Shop — cue-ball swagger.",
	},
	&"char_prisoner": {
		"mesh": &"hero_alt",
		"tint": Color(0.95, 0.55, 0.18),
		"accent": Color(0.15, 0.15, 0.18),
		"prop": &"none",
		"unlock": &"shop",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"breakout",
		"blurb": "Shop — breakout orange.",
	},
	&"char_peely": {
		"mesh": &"hero_b",
		"tint": Color(0.98, 0.88, 0.22),
		"accent": Color(0.45, 0.75, 0.25),
		"prop": &"peel",
		"unlock": &"shop",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"sunny_peel",
		"blurb": "Shop — sunny peel hero.",
	},
	&"char_marshmallow": {
		"mesh": &"hero_alt",
		"tint": Color(0.96, 0.96, 0.98),
		"accent": Color(0.75, 0.85, 1.0),
		"prop": &"soft",
		"unlock": &"shop",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"soft_guard",
		"blurb": "Shop — soft-guard puff.",
	},
	&"char_dj_yonder": {
		"mesh": &"hero_c",
		"tint": Color(0.55, 0.25, 0.85),
		"accent": Color(0.2, 0.95, 0.85),
		"prop": &"headset",
		"unlock": &"shop",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"neon_mixer",
		"blurb": "Shop — neon mixer.",
	},
	&"char_ice_king": {
		"mesh": &"hero_b",
		"tint": Color(0.55, 0.82, 1.0),
		"accent": Color(0.85, 0.95, 1.0),
		"prop": &"crown",
		"unlock": &"gate",
		"quest": &"",
		"gate_flag": &"",
		"gate_bits": 600,
		"style": &"frost_monarch",
		"blurb": "Gate — earn 600 Bits lifetime, then buy.",
	},
	&"char_black_knight": {
		"mesh": &"npc_guard",
		"tint": Color(0.14, 0.14, 0.18),
		"accent": Color(0.55, 0.15, 0.18),
		"prop": &"armor",
		"unlock": &"gate",
		"quest": &"",
		"gate_flag": &"boss_hollow_warden_down",
		"gate_bits": 0,
		"style": &"onyx_plate",
		"blurb": "Gate — clear Hollow Warden, then buy.",
	},
	&"char_master_chief": {
		"mesh": &"npc_guard",
		"tint": Color(0.35, 0.55, 0.32),
		"accent": Color(0.85, 0.75, 0.2),
		"prop": &"helm",
		"unlock": &"gate",
		"quest": &"",
		"gate_flag": &"mini_boss_glitch_alpha_down",
		"gate_bits": 0,
		"style": &"chrome_sentinel",
		"blurb": "Gate — defeat Glitch Alpha, then buy.",
	},
	&"char_dark_voyager": {
		"mesh": &"hero_a",
		"tint": Color(0.18, 0.12, 0.28),
		"accent": Color(0.55, 0.35, 0.95),
		"prop": &"visor",
		"unlock": &"earn",
		"quest": &"hollow_challenge",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"void_voyager",
		"blurb": "Earn · Hollow Challenge.",
	},
	&"char_omega": {
		"mesh": &"npc_story",
		"tint": Color(0.2, 0.22, 0.28),
		"accent": Color(0.95, 0.55, 0.15),
		"prop": &"armor",
		"unlock": &"earn",
		"quest": &"pine_threat",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"apex_protocol",
		"blurb": "Earn · Pine Threat.",
	},
	&"char_raptor": {
		"mesh": &"npc_explorer",
		"tint": Color(0.28, 0.48, 0.22),
		"accent": Color(0.55, 0.35, 0.15),
		"prop": &"mask",
		"unlock": &"earn",
		"quest": &"wildlife_watch",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"ridge_scout",
		"blurb": "Earn · Wildlife Watch.",
	},
	&"char_storm_trooper": {
		"mesh": &"npc_researcher",
		"tint": Color(0.92, 0.92, 0.95),
		"accent": Color(0.15, 0.15, 0.18),
		"prop": &"helm",
		"unlock": &"earn",
		"quest": &"park_explorer",
		"gate_flag": &"",
		"gate_bits": 0,
		"style": &"star_patrol",
		"blurb": "Earn · Park Explorer.",
	},
}

const STARTER_ID := &"char_jonesy"
const EQUIP_SLOT := &"character"


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in OUTFITS.keys():
		out.append(k)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


static func has_outfit(id: StringName) -> bool:
	return OUTFITS.has(id)


static func outfit_def(id: StringName) -> Dictionary:
	return OUTFITS.get(id, {})


static func mesh_for(id: StringName) -> StringName:
	var d := outfit_def(id)
	return d.get("mesh", &"hero_a") as StringName


static func unlock_mode(id: StringName) -> StringName:
	var d := outfit_def(id)
	return d.get("unlock", &"shop") as StringName


static func earn_quest(id: StringName) -> StringName:
	var d := outfit_def(id)
	return d.get("quest", &"") as StringName


static func gate_flag(id: StringName) -> StringName:
	var d := outfit_def(id)
	return d.get("gate_flag", &"") as StringName


static func gate_bits(id: StringName) -> int:
	var d := outfit_def(id)
	return int(d.get("gate_bits", 0))


static func ids_for_quest(quest_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in OUTFITS.keys():
		if OUTFITS[id].get("quest", &"") == quest_id:
			out.append(id)
	return out
