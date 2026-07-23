class_name CharacterCatalog
extends RefCounted
## Curated character / creature prototypes — scales fit AssetStandardizer height targets.
## Kenney Blocky raw height ≈ 2.7m → catalog scale ≈ 0.63 yields ~1.7m adults.


const ROOT := "res://assets/models/external/characters/"

## id -> { path, scale, y, category, role_hint }
## Player / adult NPC: 95–105% of 1.7m. Children would use ~0.48–0.52.
const CHARACTERS: Dictionary = {
	&"hero_a": {"path": "humans/hero_a.glb", "scale": 0.63, "y": 0.0, "category": &"player", "role_hint": &"hero"},
	&"hero_b": {"path": "humans/hero_b.glb", "scale": 0.63, "y": 0.0, "category": &"player", "role_hint": &"hero"},
	&"hero_c": {"path": "humans/hero_c.glb", "scale": 0.62, "y": 0.0, "category": &"player", "role_hint": &"hero"},
	&"hero_alt": {"path": "humans/hero_alt.glb", "scale": 0.63, "y": 0.0, "category": &"player", "role_hint": &"hero"},
	&"npc_villager": {"path": "humans/npc_villager.glb", "scale": 0.61, "y": 0.0, "category": &"npc", "role_hint": &"villager"},
	&"npc_merchant": {"path": "humans/npc_merchant.glb", "scale": 0.62, "y": 0.0, "category": &"npc", "role_hint": &"merchant"},
	&"npc_explorer": {"path": "humans/npc_explorer.glb", "scale": 0.63, "y": 0.0, "category": &"npc", "role_hint": &"explorer"},
	&"npc_researcher": {"path": "humans/npc_researcher.glb", "scale": 0.60, "y": 0.0, "category": &"npc", "role_hint": &"researcher"},
	&"npc_story": {"path": "humans/npc_story.glb", "scale": 0.64, "y": 0.0, "category": &"npc", "role_hint": &"story"},
	&"npc_guard": {"path": "humans/npc_guard.glb", "scale": 0.65, "y": 0.0, "category": &"npc", "role_hint": &"guard"},
	&"digital_mite": {"path": "creatures/digital_mite.glb", "scale": 0.55, "y": 0.0, "category": &"creature", "role_hint": &"wildlife"},
	&"field_ranger": {"path": "creatures/field_ranger.glb", "scale": 0.7, "y": 0.0, "category": &"creature", "role_hint": &"special_npc"},
	&"field_ranger_b": {"path": "creatures/field_ranger_b.glb", "scale": 0.7, "y": 0.0, "category": &"creature", "role_hint": &"special_npc"},
}


static func has_character(id: StringName) -> bool:
	return CHARACTERS.has(id)


static func character_path(id: StringName) -> String:
	if not CHARACTERS.has(id):
		return ""
	return ROOT + String(CHARACTERS[id]["path"])


static func character_def(id: StringName) -> Dictionary:
	return CHARACTERS.get(id, {})


static func id_for_npc_role(role: int) -> StringName:
	match role:
		NpcCatalog.Role.MERCHANT:
			return &"npc_merchant"
		NpcCatalog.Role.EXPLORER:
			return &"npc_explorer"
		NpcCatalog.Role.RESEARCHER:
			return &"npc_researcher"
		NpcCatalog.Role.STORY:
			return &"npc_story"
		_:
			return &"npc_villager"


static func player_options() -> Array[StringName]:
	return [&"hero_a", &"hero_b", &"hero_c", &"hero_alt"]
