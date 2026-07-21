class_name CharacterOutfitCatalog
extends RefCounted
## Item Shop character roster visuals — Digital Frontier retro look-alikes.
## Sketchfab Fortnite rips are rejected (Epic IP). Each outfit maps to a custom
## pixel-toon silhouette kit (`CharacterLookalikeKit`) with Kenney fallback.

## id -> { mesh, tint, accent, prop, unlock, quest, blurb, style }
const OUTFITS: Dictionary = {
	&"char_jonesy": {
		"mesh": &"hero_a",
		"tint": Color(0.92, 0.78, 0.55),
		"accent": Color(0.25, 0.45, 0.85),
		"prop": &"cap",
		"unlock": &"starter",
		"quest": &"",
		"style": &"field_agent",
		"blurb": "Retro field agent — blue polo, DF cap, pack.",
	},
	&"char_ice_king": {
		"mesh": &"hero_b",
		"tint": Color(0.55, 0.82, 1.0),
		"accent": Color(0.85, 0.95, 1.0),
		"prop": &"crown",
		"unlock": &"shop",
		"quest": &"",
		"style": &"frost_monarch",
		"blurb": "Crystal crown + ice cape — winter sovereign.",
	},
	&"char_indiana": {
		"mesh": &"npc_explorer",
		"tint": Color(0.72, 0.48, 0.28),
		"accent": Color(0.35, 0.22, 0.12),
		"prop": &"hat",
		"unlock": &"shop",
		"quest": &"",
		"style": &"relic_runner",
		"blurb": "Fedora, leather, satchel — relic runner.",
	},
	&"char_8ball": {
		"mesh": &"hero_c",
		"tint": Color(0.12, 0.12, 0.14),
		"accent": Color(0.95, 0.95, 0.98),
		"prop": &"orb",
		"unlock": &"shop",
		"quest": &"",
		"style": &"cue_ball",
		"blurb": "Gloss black + white 8 medallion swagger.",
	},
	&"char_prisoner": {
		"mesh": &"hero_alt",
		"tint": Color(0.95, 0.55, 0.18),
		"accent": Color(0.15, 0.15, 0.18),
		"prop": &"none",
		"unlock": &"shop",
		"quest": &"",
		"style": &"breakout",
		"blurb": "Orange jumpsuit stripes — breakout grit.",
	},
	&"char_black_knight": {
		"mesh": &"npc_guard",
		"tint": Color(0.14, 0.14, 0.18),
		"accent": Color(0.55, 0.15, 0.18),
		"prop": &"armor",
		"unlock": &"shop",
		"quest": &"",
		"style": &"onyx_plate",
		"blurb": "Onyx plate, crimson plume & cape.",
	},
	&"char_peely": {
		"mesh": &"hero_b",
		"tint": Color(0.98, 0.88, 0.22),
		"accent": Color(0.45, 0.75, 0.25),
		"prop": &"peel",
		"unlock": &"shop",
		"quest": &"",
		"style": &"sunny_peel",
		"blurb": "Banana-hero silhouette — sunny peel energy.",
	},
	&"char_marshmallow": {
		"mesh": &"hero_alt",
		"tint": Color(0.96, 0.96, 0.98),
		"accent": Color(0.75, 0.85, 1.0),
		"prop": &"soft",
		"unlock": &"shop",
		"quest": &"",
		"style": &"soft_guard",
		"blurb": "Stacked soft-guard snow puff + scarf.",
	},
	&"char_master_chief": {
		"mesh": &"npc_guard",
		"tint": Color(0.35, 0.55, 0.32),
		"accent": Color(0.85, 0.75, 0.2),
		"prop": &"helm",
		"unlock": &"shop",
		"quest": &"",
		"style": &"chrome_sentinel",
		"blurb": "Chunky olive armor + gold visor.",
	},
	&"char_dj_yonder": {
		"mesh": &"hero_c",
		"tint": Color(0.55, 0.25, 0.85),
		"accent": Color(0.2, 0.95, 0.85),
		"prop": &"headset",
		"unlock": &"shop",
		"quest": &"",
		"style": &"neon_mixer",
		"blurb": "Neon headset + speaker pack mixer.",
	},
	&"char_dark_voyager": {
		"mesh": &"hero_a",
		"tint": Color(0.18, 0.12, 0.28),
		"accent": Color(0.55, 0.35, 0.95),
		"prop": &"visor",
		"unlock": &"earn",
		"quest": &"hollow_challenge",
		"style": &"void_voyager",
		"blurb": "Earn · void suit + purple visor.",
	},
	&"char_omega": {
		"mesh": &"npc_story",
		"tint": Color(0.2, 0.22, 0.28),
		"accent": Color(0.95, 0.55, 0.15),
		"prop": &"armor",
		"unlock": &"earn",
		"quest": &"pine_threat",
		"style": &"apex_protocol",
		"blurb": "Earn · dark armor with orange veins.",
	},
	&"char_raptor": {
		"mesh": &"npc_explorer",
		"tint": Color(0.28, 0.48, 0.22),
		"accent": Color(0.55, 0.35, 0.15),
		"prop": &"mask",
		"unlock": &"earn",
		"quest": &"wildlife_watch",
		"style": &"ridge_scout",
		"blurb": "Earn · camo hood + utility vest.",
	},
	&"char_storm_trooper": {
		"mesh": &"npc_researcher",
		"tint": Color(0.92, 0.92, 0.95),
		"accent": Color(0.15, 0.15, 0.18),
		"prop": &"helm",
		"unlock": &"earn",
		"quest": &"park_explorer",
		"style": &"star_patrol",
		"blurb": "Earn · white plate star-patrol kit.",
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


static func ids_for_quest(quest_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in OUTFITS.keys():
		if OUTFITS[id].get("quest", &"") == quest_id:
			out.append(id)
	return out
