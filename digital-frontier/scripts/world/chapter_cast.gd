class_name ChapterCast
extends RefCounted
## Quest-state dialogue for the Grassland vertical slice.


static func lines_for(npc_id: StringName) -> PackedStringArray:
	match npc_id:
		&"park_guide":
			return _park_guide()
		&"field_ranger":
			return _field_ranger()
		&"meadow_researcher":
			return _meadow_researcher()
		&"lost_scout":
			return _lost_scout()
		&"park_villager":
			return _park_villager()
		&"fuel_clerk":
			return PackedStringArray([
				"Bits spend fine here — Field Salve’ll get you back on your feet.",
				"Heard growls from Pine Hollow. Stock up if you’re heading north.",
			])
		&"road_merchant":
			return PackedStringArray([
				"Rumors cost extra. Salves don’t.",
				"Market Mile opens wider once the roads feel safe.",
			])
		_:
			return PackedStringArray()


static func _lost_scout() -> PackedStringArray:
	if QuestManager.is_quest_active(&"lost_trail"):
		return PackedStringArray([
			"You found me… I followed lights with no footprints.",
			"Tell the Ranger — something’s herding travelers north.",
		])
	if NPCManager.has_memory(&"lost_scout", &"rescued"):
		return PackedStringArray([
			"Still catching my breath. Those lights… weren’t friendly.",
			"Pine Hollow isn’t just a landmark. It’s a door.",
		])
	return PackedStringArray([
		"Am I still on the map? The markers lied to me.",
	])


static func _park_villager() -> PackedStringArray:
	if QuestManager.is_quest_active(&"village_shield"):
		return PackedStringArray([
			"Glitchmites keep nosing the park fences!",
			"Clear a few near town, then come tell me we’re safe.",
		])
	if NPCManager.has_memory(&"park_villager", &"village_safe"):
		return PackedStringArray([
			"Kids are playing outside again. That’s because of you.",
		])
	return PackedStringArray([
		"Pleasant Park feels safer with you around.",
		"My cousin saw a moose near Pine Hollow!",
	])


static func _park_guide() -> PackedStringArray:
	if QuestManager.is_quest_active(&"first_steps"):
		return PackedStringArray([
			"Welcome to Pleasant Park — first stop on the Digital Frontier!",
			"Tap the welcome sign, open a chest, then talk to me again.",
			"Your partner learns when you explore. Stick together!",
		])
	if QuestManager.is_quest_active(&"grassland_call"):
		return PackedStringArray([
			"The Field Ranger needs you by the north path.",
			"Something’s wrong near Pine Hollow — take Field Salve from the Fuel Stop.",
		])
	if QuestManager.is_quest_active(&"pine_threat"):
		return PackedStringArray([
			"That Glitch Alpha’s been scaring wildlife. Clear it, then push to the pines.",
		])
	if QuestManager.is_quest_active(&"hollow_challenge"):
		return PackedStringArray([
			"The Hollow Warden waits in Pine Hollow. Prepare, then face it.",
			"You’re writing the first chapter of this Field Unit’s story.",
		])
	if QuestManager.is_quest_completed(&"hollow_challenge"):
		return PackedStringArray([
			"Chapter one — complete! The Grassland breathes easier because of you.",
			"Rest at Home, check the Shop, then chase side trails whenever you like.",
		])
	return PackedStringArray([
		"Nice exploring! Care for your creature at Home between adventures.",
		"Rare chests sparkle blue. Legendary ones glow orange — peek behind the fuel stop!",
	])


static func _field_ranger() -> PackedStringArray:
	if QuestManager.is_quest_active(&"lost_trail"):
		return PackedStringArray([
			"A scout went missing on the Pine Hollow road.",
			"Find them, then report back — something’s wrong with the trail.",
		])
	if QuestManager.is_quest_active(&"strange_static"):
		return PackedStringArray([
			"Read the warning stone near Hollow, then clear hostiles nearby.",
			"Strange static. Not weather. Not wildlife.",
		])
	if QuestManager.is_quest_active(&"grassland_call"):
		return PackedStringArray([
			"Field Ranger reporting. Glitch Alpha nests toward Pine Hollow.",
			"Defeat it — the Hollow itself is stirring.",
		])
	if QuestManager.is_quest_active(&"pine_threat"):
		return PackedStringArray([
			"Find Glitch Alpha north of town. It won’t wait politely.",
		])
	if QuestManager.is_quest_active(&"hollow_challenge"):
		return PackedStringArray([
			"The Warden isn’t a bigger mite — old code in living wood.",
			"Stock salve. Watch its phases.",
		])
	if QuestManager.is_quest_completed(&"hollow_challenge"):
		return PackedStringArray([
			"You did it. The pines are quiet again.",
			"Keep the Index growing — the Frontier’s bigger than one chapter.",
		])
	return PackedStringArray([
		"Keep to the roads until your partner is battle-ready.",
		"Glitchmites nest beyond the meadow — train hard!",
	])


static func _meadow_researcher() -> PackedStringArray:
	if QuestManager.is_quest_active(&"injured_signal"):
		return PackedStringArray([
			"A creature-signal flickered near the ranger trail — hurt, scared.",
			"Find the trail cache, bring Field Salve notes, then talk to me.",
		])
	if QuestManager.is_quest_active(&"wildlife_watch") or QuestManager.is_quest_active(&"index_novice"):
		return PackedStringArray([
			"Wildlife migrates with the digital tide — log everything!",
			"Morning birds, night moths… each hour changes who you’ll meet.",
		])
	if QuestManager.is_quest_completed(&"hollow_challenge"):
		return PackedStringArray([
			"Your Index after the Warden fight? Fascinating data.",
			"Side studies never end — that’s field research.",
		])
	return PackedStringArray([
		"Rabbits flee at eight meters — fascinating!",
		"Record every species. The Index is an adventure itself.",
	])
