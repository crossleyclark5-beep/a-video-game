class_name CharacterOutfitCatalog
extends RefCounted
## Item Shop character roster visuals — licensed Kenney meshes + DF tints.
## Sketchfab Fortnite rips are rejected (Epic IP). Names mirror the requested
## shop fantasy; meshes are original CC0 blocky adventurers.

## id -> { mesh, tint, accent, prop, unlock, quest, blurb }
const OUTFITS: Dictionary = {
	&"char_jonesy": {
		"mesh": &"hero_a",
		"tint": Color(0.92, 0.78, 0.55),
		"accent": Color(0.25, 0.45, 0.85),
		"prop": &"cap",
		"unlock": &"starter",
		"quest": &"",
		"blurb": "Starter operative — your look at the start.",
	},
	&"char_ice_king": {
		"mesh": &"hero_b",
		"tint": Color(0.55, 0.82, 1.0),
		"accent": Color(0.85, 0.95, 1.0),
		"prop": &"crown",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Frost-crowned monarch of the digital winter.",
	},
	&"char_indiana": {
		"mesh": &"npc_explorer",
		"tint": Color(0.72, 0.48, 0.28),
		"accent": Color(0.35, 0.22, 0.12),
		"prop": &"hat",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Relic-running adventurer with a wide brim.",
	},
	&"char_8ball": {
		"mesh": &"hero_c",
		"tint": Color(0.12, 0.12, 0.14),
		"accent": Color(0.95, 0.95, 0.98),
		"prop": &"orb",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Slick black-and-white cue-ball swagger.",
	},
	&"char_prisoner": {
		"mesh": &"hero_alt",
		"tint": Color(0.95, 0.55, 0.18),
		"accent": Color(0.15, 0.15, 0.18),
		"prop": &"none",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Breakout orange — still got the field grit.",
	},
	&"char_black_knight": {
		"mesh": &"npc_guard",
		"tint": Color(0.14, 0.14, 0.18),
		"accent": Color(0.55, 0.15, 0.18),
		"prop": &"armor",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Onyx plate for the boldest sorties.",
	},
	&"char_peely": {
		"mesh": &"hero_b",
		"tint": Color(0.98, 0.88, 0.22),
		"accent": Color(0.45, 0.75, 0.25),
		"prop": &"peel",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Sunny peel energy — impossible to miss.",
	},
	&"char_marshmallow": {
		"mesh": &"hero_alt",
		"tint": Color(0.96, 0.96, 0.98),
		"accent": Color(0.75, 0.85, 1.0),
		"prop": &"soft",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Puffy soft-guard look for chill ops.",
	},
	&"char_master_chief": {
		"mesh": &"npc_guard",
		"tint": Color(0.35, 0.55, 0.32),
		"accent": Color(0.85, 0.75, 0.2),
		"prop": &"helm",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Chrome-green sentinel armor kit.",
	},
	&"char_dj_yonder": {
		"mesh": &"hero_c",
		"tint": Color(0.55, 0.25, 0.85),
		"accent": Color(0.2, 0.95, 0.85),
		"prop": &"headset",
		"unlock": &"shop",
		"quest": &"",
		"blurb": "Neon mixer vibes for the night circuit.",
	},
	&"char_dark_voyager": {
		"mesh": &"hero_a",
		"tint": Color(0.18, 0.12, 0.28),
		"accent": Color(0.55, 0.35, 0.95),
		"prop": &"visor",
		"unlock": &"earn",
		"quest": &"hollow_challenge",
		"blurb": "Earn: clear Hollow Challenge.",
	},
	&"char_omega": {
		"mesh": &"npc_story",
		"tint": Color(0.2, 0.22, 0.28),
		"accent": Color(0.95, 0.55, 0.15),
		"prop": &"armor",
		"unlock": &"earn",
		"quest": &"pine_threat",
		"blurb": "Earn: clear Pine Threat.",
	},
	&"char_raptor": {
		"mesh": &"npc_explorer",
		"tint": Color(0.28, 0.48, 0.22),
		"accent": Color(0.55, 0.35, 0.15),
		"prop": &"mask",
		"unlock": &"earn",
		"quest": &"wildlife_watch",
		"blurb": "Earn: complete Wildlife Watch.",
	},
	&"char_storm_trooper": {
		"mesh": &"npc_researcher",
		"tint": Color(0.92, 0.92, 0.95),
		"accent": Color(0.15, 0.15, 0.18),
		"prop": &"helm",
		"unlock": &"earn",
		"quest": &"park_explorer",
		"blurb": "Earn: complete Park Explorer.",
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
