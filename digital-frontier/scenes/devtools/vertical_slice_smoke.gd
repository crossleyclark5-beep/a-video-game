extends Node
## Vertical slice smoke — chapter spine data, dialogue, director, park shop.


var _frames: int = 0
var _done: bool = false
var _world: Node = null


func _ready() -> void:
	print("VERTICAL_SLICE_SMOKE_START")
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
	if _frames < 12:
		return
	_done = true
	var ok := true
	for qid in [&"grassland_call", &"pine_threat", &"hollow_challenge"]:
		if not ResourceRegistry.has_id(&"quest", qid):
			push_error("missing quest %s" % String(qid))
			ok = false
	var chapter := _world.find_child("ChapterDirector", true, false)
	if chapter == null:
		push_error("ChapterDirector missing")
		ok = false
	var living := _world.find_child("LivingWorld", true, false)
	if living:
		var hostiles := living.get_node_or_null("Hostiles")
		if hostiles == null or hostiles.get_node_or_null("GlitchAlpha") == null:
			## May already be defeated in save — only require if flag clear.
			if not bool(WorldManager.get_world_flag(&"mini_boss_glitch_alpha_down", false)):
				push_error("GlitchAlpha missing")
				ok = false
		if hostiles and hostiles.get_node_or_null("HollowWarden") == null:
			if not bool(WorldManager.get_world_flag(&"boss_hollow_warden_down", false)):
				push_error("HollowWarden missing")
				ok = false
	var fuel_shop := _world.find_child("FuelShopCounter", true, false)
	if fuel_shop == null:
		push_error("Fuel shop counter missing")
		ok = false
	var trail := _world.find_child("Lore_ranger_trail_cache", true, false)
	if trail == null:
		push_error("Ranger trail lore missing")
		ok = false
	var lines := ChapterCast.lines_for(&"park_guide")
	if lines.is_empty():
		push_error("ChapterCast park_guide empty")
		ok = false
	## Dialogue class loads
	var dlg := DeviceDialogue.new()
	if dlg == null:
		push_error("DeviceDialogue failed")
		ok = false
	else:
		dlg.queue_free()
	QuestManager.ensure_starter_quest()
	if not QuestManager.is_quest_active(&"first_steps") and not QuestManager.is_quest_completed(&"first_steps"):
		push_error("starter quest not running")
		ok = false
	## Simulate spine: complete first_steps → grassland_call should start
	if QuestManager.is_quest_active(&"first_steps"):
		QuestManager.complete_quest(&"first_steps")
	if not QuestManager.is_quest_active(&"grassland_call") and not QuestManager.is_quest_completed(&"grassland_call"):
		push_error("grassland_call not offered after first_steps")
		ok = false
	var status := QuestManager.get_quest_status_line()
	if status.find("Grassland") < 0 and status.find("Field Ranger") < 0 and status.find("Talk") < 0:
		push_error("status line missing main quest: %s" % status)
		ok = false
	print("VERTICAL_SLICE_SMOKE_OK" if ok else "VERTICAL_SLICE_SMOKE_FAIL")
	get_tree().quit(0 if ok else 1)
