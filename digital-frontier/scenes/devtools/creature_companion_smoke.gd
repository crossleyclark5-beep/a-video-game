extends Node
## Creature companion system smoke — identity, personality, memory, evolution paths.


var _frames: int = 0
var _done: bool = false


func _ready() -> void:
	print("CREATURE_COMPANION_SMOKE_START")


func _process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames < 4:
		return
	_done = true
	var ok := true

	if not CreatureManager.select_partner(&"emberling", "Sparkfriend"):
		push_error("select_partner failed")
		ok = false
	if CreatureManager.get_companion_nickname() != "Sparkfriend":
		push_error("nickname mismatch")
		ok = false
	var trait_id := CreatureManager.get_primary_trait()
	if trait_id == &"":
		push_error("primary trait empty")
		ok = false
	print("primary_trait=", CompanionPersonality.trait_label(trait_id))
	print("battle_style=", CreatureManager.get_battle_style())

	var talk := CreatureManager.talk()
	if talk.is_empty():
		push_error("talk empty")
		ok = false
	var comfort := CreatureManager.comfort()
	if comfort.is_empty():
		push_error("comfort empty")
		ok = false

	CreatureManager.note_adventure_deploy()
	if not CreatureManager.get_active_instance().first_adventure_done:
		push_error("first adventure flag missing")
		ok = false
	if CreatureManager.get_memories().is_empty():
		push_error("memories empty after bond/adventure")
		ok = false
	print("memory=", CreatureManager.get_memory_summary())

	CreatureManager.record_companion_battle(true, &"glitchmite", false)
	CreatureManager.record_companion_battle(true, &"glitchmite", false)
	CreatureManager.record_companion_battle(true, &"glitch_alpha", true)
	var hist := CreatureManager.get_battle_history()
	if int(hist.get("wins", 0)) < 3:
		push_error("battle wins not recorded")
		ok = false
	if int(hist.get("bosses_defeated", 0)) < 1:
		push_error("boss battle not recorded")
		ok = false

	## Evolution registry
	var paths: Array = ResourceRegistry.get_evolution_paths_for(&"emberling", 0)
	if paths.is_empty():
		push_error("emberling evolution paths missing")
		ok = false
	else:
		print("evolution_paths=", paths.size())

	## Force level/friendship for path check
	var inst := CreatureManager.get_active_instance()
	inst.level = 10
	inst.friendship = 80.0
	inst.training_style = &"battle"
	inst.training_counts = {"care": 1, "train": 1, "explore": 1, "battle": 8}
	inst.personality["brave"] = 80.0
	var avail := CreatureManager.get_available_evolution_paths()
	if avail.is_empty():
		## Still may qualify classic — ensure can_evolve
		if not CreatureManager.can_evolve():
			push_error("no evolution available after setup")
			ok = false
	var evo := CreatureManager.try_evolve()
	if not bool(evo.get("evolved", false)):
		push_error("evolve failed")
		ok = false
	else:
		print("evolved_into=", evo.get("name", "?"), " path=", evo.get("path_id", &""))

	## Strike power uses stats
	var power := CreatureManager.get_strike_power()
	if power < 5.0:
		push_error("strike power too low")
		ok = false

	## Save round-trip
	var exported := CreatureManager.export_state()
	CreatureManager.import_state(exported)
	if CreatureManager.get_companion_nickname() != "Sparkfriend":
		push_error("save/load nickname lost")
		ok = false
	if CreatureManager.get_memories().is_empty():
		push_error("save/load memories lost")
		ok = false

	## Adventure actor class loads
	var actor := AdventureCompanionActor.new()
	if actor == null:
		push_error("AdventureCompanionActor failed")
		ok = false
	else:
		actor.queue_free()

	print("CREATURE_COMPANION_SMOKE_OK" if ok else "CREATURE_COMPANION_SMOKE_FAIL")
	get_tree().quit(0 if ok else 1)
