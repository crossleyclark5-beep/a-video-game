class_name ProfileCatalog
extends RefCounted
## Local multi-user profile definitions for the Field Unit.
## Offline only — no cloud accounts. NFC can read profile_id later.


const MAX_PROFILES := 8
const INDEX_PATH := "user://saves/profiles.json"
const PROFILES_DIR := "user://saves/profiles/"
const NAME_MAX_LEN := 10

## Handheld-friendly avatar glyphs (no image assets required).
const AVATARS: Array[Dictionary] = [
	{"id": &"ember", "glyph": "▲", "label": "Ember", "color": Color(0.95, 0.45, 0.28)},
	{"id": &"spark", "glyph": "✦", "label": "Spark", "color": Color(0.95, 0.85, 0.35)},
	{"id": &"tide", "glyph": "◈", "label": "Tide", "color": Color(0.35, 0.65, 0.95)},
	{"id": &"leaf", "glyph": "♣", "label": "Leaf", "color": Color(0.35, 0.8, 0.45)},
	{"id": &"star", "glyph": "★", "label": "Star", "color": Color(0.95, 0.75, 0.4)},
	{"id": &"moon", "glyph": "☾", "label": "Moon", "color": Color(0.65, 0.55, 0.95)},
	{"id": &"hex", "glyph": "⬡", "label": "Hex", "color": Color(0.55, 0.85, 0.9)},
	{"id": &"pixel", "glyph": "■", "label": "Pixel", "color": Color(0.9, 0.55, 0.75)},
]

const NAME_PRESETS: PackedStringArray = [
	"Alex", "Sam", "Riley", "Jordan", "Kai", "Nova", "Quinn", "Reese",
	"Morgan", "Casey", "Sky", "Rowan",
]


static func avatar_def(avatar_id: StringName) -> Dictionary:
	for a in AVATARS:
		if a["id"] == avatar_id:
			return a
	return AVATARS[0]


static func avatar_glyph(avatar_id: StringName) -> String:
	return str(avatar_def(avatar_id).get("glyph", "▲"))


static func avatar_color(avatar_id: StringName) -> Color:
	return avatar_def(avatar_id).get("color", Color(0.95, 0.45, 0.28)) as Color


static func avatar_label(avatar_id: StringName) -> String:
	return str(avatar_def(avatar_id).get("label", "Ember"))


static func make_profile_id() -> String:
	var t := int(Time.get_unix_time_from_system())
	var r := randi() % 0xffff
	return "p_%x_%04x" % [t, r]


static func empty_summary() -> Dictionary:
	return {
		&"partner_species": "",
		&"partner_nickname": "",
		&"partner_level": 0,
		&"partner_stage": 0,
		&"playtime_seconds": 0.0,
		&"bits": 50,
		&"quests_completed": 0,
		&"discoveries": 0,
		&"achievements": 0,
		&"completion_pct": 0,
	}


static func compute_completion_pct(quests_done: int, discoveries: int, achievements: int, has_partner: bool) -> int:
	var q_total: int = maxi(ResourceRegistry.get_all_quests().size(), 1)
	var d_total: int = maxi(ResourceRegistry.get_all_discoverables().size(), 1)
	var a_total: int = maxi(ResourceRegistry.get_all_achievements().size(), 1)
	var score := 0.0
	score += clampf(float(quests_done) / float(q_total), 0.0, 1.0) * 35.0
	score += clampf(float(discoveries) / float(d_total), 0.0, 1.0) * 35.0
	score += clampf(float(achievements) / float(a_total), 0.0, 1.0) * 20.0
	score += 10.0 if has_partner else 0.0
	return clampi(int(round(score)), 0, 100)


static func format_playtime(seconds: float) -> String:
	var total := int(seconds)
	var h: int = int(total / 3600.0)
	var m: int = int((total % 3600) / 60.0)
	if h > 0:
		return "%dh %02dm" % [h, m]
	return "%dm" % m
