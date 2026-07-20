class_name DFFormat
extends RefCounted
## Rich BBCode formatters for Field Unit sheets — cards, not plain dumps.


static func pack_sheet() -> String:
	var bits := InventoryManager.get_bits()
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.header_bb("PACK", WorldPalette.UI_ACCENT))
	lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "◆ %d Bits" % bits))
	lines.append("")
	var raw := InventoryManager.get_pack_text()
	var item_count := 0
	for line in raw.split("\n"):
		var t := line.strip_edges()
		if t.is_empty() or t.begins_with("Bits:") or t.begins_with("Pack empty"):
			continue
		## "Name × N"
		var parts := t.split(" × ")
		var name := parts[0]
		var meta := parts[1] if parts.size() > 1 else ""
		lines.append(DFStyle.card_bb(name, "In the Field Unit pack", false, "×%s" % meta if not meta.is_empty() else ""))
		item_count += 1
	if item_count == 0:
		lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "Pack empty — visit the Shop!"))
	return "\n".join(lines)


static func quest_sheet() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.header_bb("QUEST LOG", WorldPalette.UI_PURPLE))
	var ids: Array = QuestManager.get_active_quest_ids()
	var story: Array = []
	var explore: Array = []
	var creature: Array = []
	var side: Array = []
	for qid in ids:
		var data: QuestData = ResourceRegistry.get_quest(StringName(str(qid)))
		if data == null:
			side.append(qid)
			continue
		match data.quest_type:
			QuestData.QuestType.MAIN:
				story.append(qid)
			QuestData.QuestType.EXPLORATION:
				explore.append(qid)
			QuestData.QuestType.CREATURE:
				creature.append(qid)
			_:
				side.append(qid)
	if ids.is_empty():
		var status := QuestManager.get_quest_status_line()
		lines.append(DFStyle.card_bb(status, "Find the Park Guide or keep exploring", true, "●"))
	else:
		if not story.is_empty():
			lines.append(DFStyle.color_tag(WorldPalette.UI_PURPLE, "■ STORY"))
			for qid in story:
				lines.append(_quest_card(StringName(str(qid)), true))
			lines.append("")
		if not explore.is_empty():
			lines.append(DFStyle.color_tag(WorldPalette.UI_LIME, "■ EXPLORATION"))
			for qid in explore:
				lines.append(_quest_card(StringName(str(qid)), false))
			lines.append("")
		if not creature.is_empty():
			lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "■ CREATURE"))
			for qid in creature:
				lines.append(_quest_card(StringName(str(qid)), false))
			lines.append("")
		if not side.is_empty():
			lines.append(DFStyle.color_tag(WorldPalette.UI_CYAN, "■ SIDE / FIELD"))
			for qid in side:
				lines.append(_quest_card(StringName(str(qid)), false))
	lines.append("")
	## Completed quests — named list (capped for handheld).
	var done_ids: Array = []
	if QuestManager.has_method("get_completed_quest_ids"):
		done_ids = QuestManager.get_completed_quest_ids()
	var done := done_ids.size() if not done_ids.is_empty() else QuestManager.get_completed_count()
	lines.append(DFStyle.color_tag(WorldPalette.UI_LIME, "✓ COMPLETED  (%d)" % done))
	var shown := 0
	for qid in done_ids:
		if shown >= 5:
			lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "…and more"))
			break
		var qd: QuestData = ResourceRegistry.get_quest(StringName(str(qid)))
		var title := qd.display_name if qd else String(qid)
		var meta := QuestManager.get_quest_type_label(StringName(str(qid))) if QuestManager.has_method("get_quest_type_label") else "Done"
		lines.append(DFStyle.card_bb(title, "Cleared", false, meta))
		shown += 1
	if done == 0:
		lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "No quests cleared yet — the Frontier is waiting."))
	lines.append("")
	lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "Story purple · Explore green · Creature gold · Side cyan"))
	return "\n".join(lines)


static func _quest_card(qid: StringName, is_story: bool) -> String:
	var data: QuestData = ResourceRegistry.get_quest(qid)
	var title := data.display_name if data else String(qid)
	var objective := ""
	if QuestManager.has_method("get_objective_text"):
		objective = QuestManager.get_objective_text(qid)
	if objective.is_empty():
		objective = "In progress"
	var reward := ""
	if QuestManager.has_method("get_reward_summary"):
		reward = QuestManager.get_reward_summary(qid)
	if reward.is_empty():
		if data and data.reward_bits > 0:
			reward = "%d Bits" % data.reward_bits
		elif is_story:
			reward = "STORY"
		else:
			reward = QuestManager.get_quest_type_label(qid) if QuestManager.has_method("get_quest_type_label") else "ACTIVE"
	var body := objective
	if data and not data.description.is_empty():
		## One short line of context under the objective.
		var blurb := data.description
		if blurb.length() > 72:
			blurb = blurb.substr(0, 69) + "…"
		body = "%s\n%s" % [objective, blurb]
	return DFStyle.card_bb(title, body, true, reward)


static func collection_sheet() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.header_bb("COLLECTION DATABASE", WorldPalette.UI_CYAN))
	## Partner identity — same creature as Adventure.
	if CreatureManager.has_chosen_partner():
		lines.append(DFStyle.color_tag(WorldPalette.UI_ACCENT, "■ YOUR PARTNER"))
		var snap := CreatureManager.get_needs_snapshot()
		var hist: Dictionary = snap.get("battle_history", {})
		var body := "Lv.%d · %s · %s\nBond %d · Style %s · Battles %dW/%dL\n%s" % [
			int(snap.get("level", 1)),
			snap.get("stage_name", ""),
			snap.get("primary_trait_label", ""),
			int(snap.get("friendship", 0)),
			snap.get("battle_style", ""),
			int(hist.get("wins", 0)),
			int(hist.get("losses", 0)),
			snap.get("memory_summary", ""),
		]
		lines.append(DFStyle.card_bb(String(snap.get("display_name", "Partner")), body, true, "PARTNER"))
		lines.append("")
	var disc := CollectionManager.get_discovery_progress()
	lines.append(DFStyle.color_tag(WorldPalette.UI_LIME, "Locations  %d / %d" % [disc.x, disc.y]))
	var idx := CollectionManager.get_creature_index_progress()
	lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "Creature Index  %d / %d" % [idx.x, idx.y]))
	if CollectionManager.has_method("get_summary_line"):
		lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED.lightened(0.35), CollectionManager.get_summary_line()))
	lines.append("")
	lines.append(DFStyle.color_tag(WorldPalette.UI_ACCENT, "■ CREATURE INDEX"))
	for e in CollectionManager.get_creature_index_entries():
		if not e.get(&"discovered", false):
			lines.append(DFStyle.card_bb("????", "Signal locked — keep exploring", false, "???"))
			continue
		var meta := String(e.get(&"rarity_label", ""))
		var body2 := "%s · %s · seen ×%d" % [e.get(&"habitat", ""), e.get(&"temperament_label", ""), e.get(&"count", 0)]
		var wl := "W%d/L%d" % [e.get(&"battles_won", 0), e.get(&"battles_lost", 0)]
		lines.append(DFStyle.card_bb(String(e.get(&"name", "")), body2 + " · " + wl, false, meta))
	lines.append("")
	var raw := CollectionManager.get_journal_text()
	var section := ""
	for line in raw.split("\n"):
		var t := line.strip_edges()
		if t.is_empty():
			continue
		if t.begins_with("==") or t.begins_with("--"):
			section = t.replace("=", "").replace("-", "").strip_edges()
			if section.to_upper().contains("CREATURE INDEX"):
				continue  ## Already rendered above as cards.
			if not section.is_empty():
				lines.append("")
				lines.append(DFStyle.color_tag(WorldPalette.UI_ACCENT, "■ %s" % section.to_upper()))
			continue
		if section.to_upper().contains("CREATURE INDEX"):
			continue
		lines.append(DFStyle.card_bb(t, "", false, "◆"))
	return "\n".join(lines)


static func creature_index_sheet() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.header_bb("CREATURE INDEX", WorldPalette.UI_GOLD))
	var idx := CollectionManager.get_creature_index_progress()
	lines.append(DFStyle.color_tag(WorldPalette.UI_LIME, "Field log  %d / %d" % [idx.x, idx.y]))
	lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "Discover wild species · day, night, and weather change who appears."))
	lines.append("")
	for e in CollectionManager.get_creature_index_entries():
		if not e.get(&"discovered", false):
			lines.append(DFStyle.card_bb("????", "Keep walking — something new waits over the next hill", false, "LOCKED"))
			continue
		var when := ""
		var unix := int(e.get(&"first_unix", 0))
		if unix > 0:
			when = "First seen logged"
		var body := "%s · %s\n    %s · %s · encounters ×%d · battles %d/%d" % [
			e.get(&"habitat", ""),
			e.get(&"temperament_label", ""),
			e.get(&"blurb", ""),
			when,
			e.get(&"count", 0),
			e.get(&"battles_won", 0),
			e.get(&"battles_lost", 0),
		]
		lines.append(DFStyle.card_bb(String(e.get(&"name", "")), body, false, String(e.get(&"rarity_label", ""))))
	return "\n".join(lines)


static func bits_sheet() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.header_bb("BITS LEDGER", WorldPalette.UI_GOLD))
	lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "◆ Balance: %d Bits" % InventoryManager.get_bits()))
	lines.append("")
	var raw := InventoryManager.get_ledger_summary_text()
	for line in raw.split("\n"):
		var t := line.strip_edges()
		if t.is_empty() or t.begins_with("=="):
			continue
		var is_gain := t.contains("+") or t.to_lower().contains("gain")
		var col := WorldPalette.UI_LIME if is_gain else WorldPalette.UI_SHEET_TEXT
		lines.append(DFStyle.color_tag(col, "· " + t))
	lines.append("")
	lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "Earn Bits from chests, quests, and discoveries."))
	return "\n".join(lines)


static func map_blurb_sheet() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(DFStyle.header_bb("FIELD MAP", WorldPalette.UI_CYAN))
	var disc := CollectionManager.get_discovery_progress()
	var pct := 0
	if disc.y > 0:
		pct = int(100.0 * float(disc.x) / float(disc.y))
	lines.append(DFStyle.color_tag(WorldPalette.UI_LIME, "Exploration  %d%%" % pct))
	lines.append(DFStyle.color_tag(WorldPalette.UI_GOLD, "Discovered  %d / %d" % [disc.x, disc.y]))
	lines.append("")
	var blurb := WorldManager.get_map_blurb()
	for line in blurb.split("\n"):
		var t := line.strip_edges()
		if t.is_empty():
			continue
		lines.append(DFStyle.card_bb(t, "", false, "◎"))
	lines.append("")
	lines.append(DFStyle.color_tag(WorldPalette.UI_MUTED, "Grey icons = mystery · Color = visited"))
	return "\n".join(lines)
