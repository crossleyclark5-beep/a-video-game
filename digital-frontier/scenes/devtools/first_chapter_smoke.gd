extends Node
## First chapter smoke — spine stages, sanctum, guidance, evolution paths.


var _frames: int = 0
var _done: bool = false
var _world: Node = null


func _ready() -> void:
	print("FIRST_CHAPTER_SMOKE_START")
	if not CreatureManager.select_partner(&"emberling", "ChapterSpark"):
		push_error("partner select failed")
		get_tree().quit(1)
		return
	var packed: PackedScene = load("res://scenes/world/game_world.tscn") as PackedScene
	if packed == null:
		push_error("missing game_world")
		get_tree().quit(1)
		return
	_world = packed.instantiate()
	add_child(_world)


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 14:
		return
	_done = true
	var ok := true

	## Directors
	var chapter := _world.find_child("ChapterDirector", true, false)
	if chapter == null:
		push_error("ChapterDirector missing")
		ok = false
	var story := _world.find_child("StoryDirector", true, false)
	if story == null:
		push_error("StoryDirector missing")
		ok = false
	var guidance := _world.find_child("ChapterGuidance", true, false)
	if guidance == null:
		push_error("ChapterGuidance missing")
		ok = false

	## Sanctum
	var living := _world.find_child("LivingWorld", true, false)
	var sanctum: Node = null
	if living:
		sanctum = living.get_node_or_null("PineHollowSanctum")
	if sanctum == null:
		push_error("PineHollowSanctum missing")
		ok = false
	else:
		if sanctum.get_node_or_null("RootGate") == null:
			push_error("RootGate missing")
			ok = false
		if sanctum.get_node_or_null("Seals") == null:
			push_error("Seals missing")
			ok = false
		if sanctum.get_node_or_null("Arena") == null:
			push_error("Arena missing")
			ok = false

	## Town life
	if living:
		var npcs := living.get_node_or_null("WorldNpcs")
		if npcs:
			var kid := false
			var elder := false
			for c in npcs.get_children():
				if c is WorldNpcActor:
					var id: StringName = (c as WorldNpcActor).npc_id
					if id == &"park_kid":
						kid = true
					if id == &"park_elder":
						elder = true
			if not kid:
				push_error("park_kid missing")
				ok = false
			if not elder:
				push_error("park_elder missing")
				ok = false

	## Spine quest data
	var pine: QuestData = ResourceRegistry.get_quest(&"pine_threat")
	if pine == null or pine.stages.size() < 3:
		push_error("pine_threat stages incomplete")
		ok = false
	var hollow: QuestData = ResourceRegistry.get_quest(&"hollow_challenge")
	if hollow == null or hollow.stages.size() < 3:
		push_error("hollow_challenge stages incomplete")
		ok = false
	else:
		var stage1: Dictionary = hollow.stages[1]
		if str(stage1.get("target_id", "")) != "hollow_root_gate":
			push_error("hollow_challenge missing root gate stage")
			ok = false

	## Evolution chapter paths
	if not ResourceRegistry.has_id(&"evolution", &"emberling_chapter_one"):
		## Registry may index by get_id from EvolutionPathData
		var found := false
		for p in ResourceRegistry.get_evolution_paths_for(&"emberling", 0):
			if p is EvolutionPathData and (p as EvolutionPathData).id == &"emberling_chapter_one":
				found = true
				if (p as EvolutionPathData).need_world_flag != &"chapter_grassland_cleared":
					push_error("chapter evo flag wrong")
					ok = false
		if not found:
			push_error("emberling_chapter_one path missing")
			ok = false

	## Gate blocked before Alpha
	WorldManager.set_world_flag(&"mini_boss_glitch_alpha_down", false)
	WorldManager.set_world_flag(&"hollow_root_gate_open", false)
	if sanctum and sanctum.has_method("try_open_gate"):
		var opened: bool = sanctum.call("try_open_gate", false)
		if opened:
			push_error("gate opened without Alpha down")
			ok = false
	WorldManager.set_world_flag(&"mini_boss_glitch_alpha_down", true)
	if sanctum and sanctum.has_method("try_open_gate"):
		var opened2: bool = sanctum.call("try_open_gate", false)
		if not opened2:
			push_error("gate failed after Alpha down")
			ok = false
		if not bool(WorldManager.get_world_flag(&"hollow_root_gate_open", false)):
			push_error("gate flag not set")
			ok = false

	## Chapter clear + evo ceremony path availability
	WorldManager.set_world_flag(&"chapter_grassland_cleared", true)
	var inst := CreatureManager.get_active_instance()
	inst.level = 6
	inst.friendship = 50.0
	inst.battle_history = {"wins": 2, "losses": 0, "strikes": 0, "bosses_defeated": 1}
	if not CreatureManager.can_evolve():
		## May still qualify via chapter path
		var paths: Array = CreatureManager.get_available_evolution_paths()
		if paths.is_empty():
			push_error("no evolution paths after chapter flag")
			ok = false
		else:
			print("evo_paths=", paths.size())
	else:
		print("can_evolve=true")

	## Cast lines react to clear
	var guide := ChapterCast.lines_for(&"park_guide")
	if guide.is_empty() or guide[0].find("Chapter") < 0 and guide[0].find("complete") < 0 and guide[0].find("breathes") < 0:
		## Soft check — post-clear lines should mention chapter
		var joined := " ".join(guide)
		if joined.find("Chapter") < 0 and joined.find("breathes") < 0:
			push_error("park_guide post-clear lines weak: %s" % joined)
			ok = false

	if ok:
		print("FIRST_CHAPTER_SMOKE_OK")
	else:
		print("FIRST_CHAPTER_SMOKE_FAIL")
		get_tree().quit(1)
		return
	get_tree().quit(0)
