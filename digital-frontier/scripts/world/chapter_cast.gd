class_name ChapterCast
extends RefCounted
## Quest-state dialogue for Grassland Chapter One — short, reactive, handheld.


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
		&"park_kid":
			return _park_kid()
		&"park_elder":
			return _park_elder()
		&"fuel_clerk":
			return _fuel_clerk()
		&"road_merchant":
			return PackedStringArray([
				"Rumors cost extra. Salves don’t.",
				"Market Mile opens wider once the roads feel safe.",
			])
		_:
			return PackedStringArray()


static func _fuel_clerk() -> PackedStringArray:
	if QuestManager.is_quest_active(&"pine_threat") and QuestManager.get_quest_stage(&"pine_threat") == 1:
		return PackedStringArray([
			"Heading for Alpha? Field Salve. Non-negotiable.",
			"Buy what you need — then take the north trail. Y when it’s close.",
		])
	if bool(WorldManager.get_world_flag(&"chapter_grassland_cleared", false)):
		return PackedStringArray([
			"Hero discount today. Don’t tell corporate.",
			"Your partner’s looking sharper. Growth suits you both.",
		])
	return PackedStringArray([
		"Bits spend fine here — Field Salve’ll get you back on your feet.",
		"Heard growls from Pine Hollow. Stock up if you’re heading north.",
	])


static func _park_kid() -> PackedStringArray:
	if bool(WorldManager.get_world_flag(&"chapter_grassland_cleared", false)):
		return PackedStringArray([
			"You beat the tree monster?! Tell me everything!",
		])
	return PackedStringArray([
		"Race you to the gazebo!",
		"Mom says don’t pet Glitchmites. Duh.",
	])


static func _park_elder() -> PackedStringArray:
	if bool(WorldManager.get_world_flag(&"chapter_grassland_cleared", false)):
		return PackedStringArray([
			"The pines sing softer tonight. Thank you, traveler.",
		])
	if QuestManager.is_quest_active(&"hollow_challenge"):
		return PackedStringArray([
			"The Hollow isn’t a place. It’s a lock.",
			"Light the seals. Face what’s been waiting.",
		])
	return PackedStringArray([
		"I’ve watched these pines for sixty seasons.",
		"When the Hollow goes quiet, listen harder.",
	])


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
	if bool(WorldManager.get_world_flag(&"reputation_park_hero", false)):
		return PackedStringArray([
			"Park hero! The kids ask about you every morning.",
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
	if bool(WorldManager.get_world_flag(&"chapter_grassland_cleared", false)):
		return PackedStringArray([
			"Chapter one — complete! The Grassland breathes easier because of you.",
			"Rest at Home. Celebrate with your partner. The Frontier’s still listening.",
		])
	if QuestManager.is_quest_active(&"first_steps"):
		return PackedStringArray([
			"Welcome to Pleasant Park — first stop on the Digital Frontier!",
			"Find the welcome sign, open a chest, then talk to me again.",
			"Your partner learns when you explore. Stick together!",
		])
	if QuestManager.is_quest_active(&"grassland_call"):
		return PackedStringArray([
			"The Field Ranger waits on the north path.",
			"Stock Field Salve at the Fuel Stop before you push farther.",
		])
	if QuestManager.is_quest_active(&"pine_threat"):
		var st := QuestManager.get_quest_stage(&"pine_threat")
		if st == 0:
			return PackedStringArray(["Follow the cyan marker to the ranger trail cache."])
		if st == 1:
			return PackedStringArray(["Talk to the Fuel Clerk — prep before you fight Alpha."])
		return PackedStringArray(["Glitch Alpha nests on the north trail. Y when close!"])
	if QuestManager.is_quest_active(&"hollow_challenge"):
		return PackedStringArray([
			"Pine Hollow’s Root Gate opens for those who cleared Alpha.",
			"Light the seals. Face the Warden. Write chapter one.",
		])
	return PackedStringArray([
		"Nice exploring! Care for your creature at Home between adventures.",
		"Rare chests sparkle blue. Legendary ones glow orange — peek behind the fuel stop!",
	])


static func _field_ranger() -> PackedStringArray:
	if bool(WorldManager.get_world_flag(&"chapter_grassland_cleared", false)):
		return PackedStringArray([
			"You did it. The pines are quiet again.",
			"Keep the Index growing — the Frontier’s bigger than one chapter.",
		])
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
			"Hit the trail cache, stock salve at Fuel Stop, then take it down.",
			"Y when enemies are close. Your partner fights with you.",
		])
	if QuestManager.is_quest_active(&"pine_threat"):
		var st := QuestManager.get_quest_stage(&"pine_threat")
		if st == 0:
			return PackedStringArray(["Find my trail cache on the road north — then prep at Fuel Stop."])
		if st == 1:
			return PackedStringArray(["Talk to the Fuel Clerk. Don’t fight Alpha empty-handed."])
		return PackedStringArray(["Alpha’s on the north trail. End it — the Root Gate will listen."])
	if QuestManager.is_quest_active(&"hollow_challenge"):
		return PackedStringArray([
			"The Warden isn’t a bigger mite — old code in living wood.",
			"Open the Root Gate. Light both seals. Watch its phases.",
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
	if bool(WorldManager.get_world_flag(&"chapter_grassland_cleared", false)):
		return PackedStringArray([
			"Your Index after the Warden fight? Fascinating data.",
			"Side studies never end — that’s field research.",
		])
	return PackedStringArray([
		"Rabbits flee at eight meters — fascinating!",
		"Record every species. The Index is an adventure itself.",
	])
