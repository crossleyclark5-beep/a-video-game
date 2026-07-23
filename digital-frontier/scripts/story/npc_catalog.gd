class_name NpcCatalog
extends RefCounted
## Role personalities, schedule ids, and reaction dialogue for world NPCs.


enum Role {
	VILLAGER,
	MERCHANT,
	RESEARCHER,
	EXPLORER,
	STORY,
}


static func role_from_string(raw: String) -> int:
	match raw.to_lower():
		"merchant":
			return Role.MERCHANT
		"researcher":
			return Role.RESEARCHER
		"explorer", "ranger":
			return Role.EXPLORER
		"story", "quest_giver", "important":
			return Role.STORY
		_:
			return Role.VILLAGER


static func role_label(role: int) -> String:
	match role:
		Role.MERCHANT:
			return "Merchant"
		Role.RESEARCHER:
			return "Researcher"
		Role.EXPLORER:
			return "Explorer"
		Role.STORY:
			return "Story"
		_:
			return "Villager"


static func role_glyph(role: int) -> String:
	match role:
		Role.MERCHANT:
			return "M"
		Role.RESEARCHER:
			return "R"
		Role.EXPLORER:
			return "E"
		Role.STORY:
			return "★"
		_:
			return "V"


static func role_color(role: int) -> Color:
	match role:
		Role.MERCHANT:
			return Color(0.9, 0.6, 0.25)
		Role.RESEARCHER:
			return Color(0.4, 0.6, 0.95)
		Role.EXPLORER:
			return Color(0.3, 0.7, 0.4)
		Role.STORY:
			return WorldPalette.UI_PURPLE
		_:
			return Color(0.75, 0.55, 0.65)


static func default_schedule(role: int) -> StringName:
	match role:
		Role.MERCHANT:
			return &"market_beat"
		Role.RESEARCHER:
			return &"research_walk"
		Role.EXPLORER:
			return &"field_patrol"
		Role.STORY:
			return &"story_anchor"
		_:
			return &"town_loop"


static func personality_blurb(role: int) -> String:
	match role:
		Role.MERCHANT:
			return "Always counting Bits — and rumors."
		Role.RESEARCHER:
			return "Curious first, cautious second."
		Role.EXPLORER:
			return "Maps before meals."
		Role.STORY:
			return "Carries the Frontier’s heavier secrets."
		_:
			return "Knows every porch light in town."


## Extra reaction lines when the NPC remembers something about the player.
static func memory_lines(npc_id: StringName, memories: Array) -> PackedStringArray:
	var out := PackedStringArray()
	if NpcMemory.has_id(memories, &"helped_once"):
		out.append("You helped me before — I haven’t forgotten.")
	if NpcMemory.has_id(memories, &"boss_warden"):
		out.append("After the Warden fell, the air feels lighter.")
	if NpcMemory.has_id(memories, &"boss_alpha"):
		out.append("That Alpha fight still has folks talking.")
	if NpcMemory.has_id(memories, &"quest_done"):
		out.append("Thanks again for finishing that job.")
	if NpcMemory.has_id(memories, &"discovered_hollow"):
		out.append("So you found Pine Hollow yourself… brave.")
	if NpcMemory.has_id(memories, &"camp_cleared"):
		out.append("That nest you cleared stayed quiet — wildlife's coming back.")
	match npc_id:
		&"park_villager":
			if NpcMemory.has_id(memories, &"village_safe"):
				out.append("The park feels safer with you around. Really.")
		&"meadow_researcher":
			if NpcMemory.has_id(memories, &"index_help"):
				out.append("Your Index notes keep my charts honest.")
		&"lost_scout":
			if NpcMemory.has_id(memories, &"rescued"):
				out.append("I owe you a trail marker — and a snack.")
		&"field_ranger":
			if NpcMemory.has_id(memories, &"camp_cleared"):
				out.append("Appreciate the patrol help. Nests don't stay empty forever.")
		&"park_kid":
			out.append("Wanna see how fast I can run to the fountain?")
	return out
