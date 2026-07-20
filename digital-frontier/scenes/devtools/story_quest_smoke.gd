extends Node
## NPC / quest / story smoke — memory, dialogue, quest types, story beats.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("STORY_QUEST_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 4:
		return
	_done = true
	var ok := true

	## NPC memory + disposition
	NPCManager.remember(&"park_villager", &"helped_once", NpcMemory.Kind.HELPED, "Helped villager", PackedStringArray(["help"]))
	if not NPCManager.has_memory(&"park_villager", &"helped_once"):
		push_error("npc memory missing")
		ok = false
	NPCManager.adjust_disposition(&"park_villager", 20.0)
	if NPCManager.get_disposition(&"park_villager") < 60.0:
		push_error("disposition not raised")
		ok = false
	var lines := NPCManager.get_talk_lines(&"park_villager", PackedStringArray(["Hi"]))
	if lines.is_empty():
		push_error("talk lines empty")
		ok = false
	print("villager_line0=", lines[0])

	## Roles + schedules
	if NpcCatalog.role_from_string("researcher") != NpcCatalog.Role.RESEARCHER:
		push_error("role parse failed")
		ok = false
	var points := NpcSchedule.waypoints(&"town_loop", NpcSchedule.Slot.AFTERNOON)
	if points.is_empty():
		push_error("schedule waypoints empty")
		ok = false

	## Dialogue class + choices API
	var dlg := DeviceDialogue.new()
	add_child(dlg)
	dlg.open(&"field_ranger", "Field Ranger", PackedStringArray(["Test line."]))
	dlg.set_choices(PackedStringArray(["Ask about Alpha", "Say goodbye"]))
	if not dlg.visible:
		push_error("dialogue not visible")
		ok = false
	dlg.close()
	dlg.queue_free()

	## Quest registry — memorable new quests
	for qid in [&"injured_signal", &"lost_trail", &"strange_static", &"village_shield"]:
		if not ResourceRegistry.has_id(&"quest", qid):
			push_error("missing quest %s" % String(qid))
			ok = false
	var injured: QuestData = ResourceRegistry.get_quest(&"injured_signal")
	if injured == null or injured.quest_type != QuestData.QuestType.CREATURE:
		push_error("injured_signal type wrong")
		ok = false
	var lost: QuestData = ResourceRegistry.get_quest(&"lost_trail")
	if lost == null or lost.quest_type != QuestData.QuestType.EXPLORATION:
		push_error("lost_trail type wrong")
		ok = false

	## Quest manager helpers + UI formatter
	QuestManager.ensure_starter_quest()
	if QuestManager.is_quest_active(&"first_steps"):
		QuestManager.complete_quest(&"first_steps")
	if not QuestManager.is_quest_active(&"grassland_call") and not QuestManager.is_quest_completed(&"grassland_call"):
		push_error("grassland_call not offered")
		ok = false
	## Force-complete grassland_call to drip side unlocks including new quests
	if QuestManager.is_quest_active(&"grassland_call"):
		QuestManager.complete_quest(&"grassland_call")
	## Pulse followups until a new memorable quest appears or spine continues
	var found_new := false
	for _i in 12:
		for qid2 in [&"injured_signal", &"lost_trail", &"strange_static", &"village_shield", &"park_explorer"]:
			if QuestManager.is_quest_active(qid2) or QuestManager.is_quest_completed(qid2):
				found_new = true
				break
		if found_new:
			break
		## Complete whatever side is active to unlock next drip
		var active: Array = QuestManager.get_active_quest_ids()
		var advanced := false
		for aq in active:
			var aqid := StringName(str(aq))
			var qd: QuestData = ResourceRegistry.get_quest(aqid)
			if qd and qd.quest_type != QuestData.QuestType.MAIN:
				QuestManager.complete_quest(aqid)
				advanced = true
				break
		if not advanced:
			break
	if not found_new:
		push_error("no side/explore quest unlocked after grassland_call")
		ok = false

	var sheet := DFFormat.quest_sheet()
	if sheet.find("QUEST LOG") < 0:
		push_error("quest sheet missing header")
		ok = false
	if QuestManager.has_method("get_reward_summary"):
		var reward := QuestManager.get_reward_summary(&"village_shield")
		if reward.find("Bits") < 0:
			push_error("reward summary missing bits")
			ok = false

	## Story catalog + director
	var beat_lines := StoryCatalog.beat_lines(&"frontier_whisper")
	if beat_lines.size() < 2:
		push_error("story beat too short")
		ok = false
	var story := StoryDirector.new()
	story.name = "SmokeStory"
	add_child(story)
	story.setup(null, null)
	story.queue_beat(&"frontier_whisper")
	## Flag should set when played — force play path
	if bool(WorldManager.get_world_flag(StoryCatalog.flag_for_beat(&"frontier_whisper"), false)):
		print("whisper already flagged")
	## Chapter cast lines for lost scout
	var scout_lines := ChapterCast.lines_for(&"lost_scout")
	if scout_lines.is_empty():
		push_error("lost scout lines empty")
		ok = false

	## Save round-trip NPC state
	var exported := NPCManager.export_state()
	NPCManager.import_state(exported)
	if not NPCManager.has_memory(&"park_villager", &"helped_once"):
		push_error("npc save/load lost memory")
		ok = false

	story.queue_free()

	if ok:
		print("STORY_QUEST_SMOKE_OK")
	else:
		print("STORY_QUEST_SMOKE_FAIL")
		get_tree().quit(1)
		return
	get_tree().quit(0)
