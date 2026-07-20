extends BaseManager
## Creature collection, party, and living companion ownership.
##
## Active companion is a CreatureInstance (data-driven). Species templates
## live in CreatureData. Home + adventure share the same instance state.

signal companion_memory_recorded(memory_id: StringName)
signal companion_battle_recorded(won: bool)
signal companion_evolved(path_id: StringName, stage: int)

enum Mood {
	EXCITED,
	HAPPY,
	CONTENT,
	BORED,
	SAD,
	IRRITABLE,
	TIRED,
}

const STARTER_CREATURE_ID := &"emberling"
## First-boot partner choices — each a distinct personality / path / strengths.
const STARTER_OPTIONS: Array[StringName] = [&"emberling", &"sparkbit", &"tidepup"]

const CARE_FEED := {
	"hunger": 28.0,
	"happiness": 6.0,
	"friendship": 2.0,
	"health": 1.0,
}
const CARE_PLAY := {
	"happiness": 18.0,
	"energy": -8.0,
	"friendship": 5.0,
	"hunger": -4.0,
}
const CARE_REST := {
	"energy": 32.0,
	"happiness": 4.0,
	"health": 3.0,
}
const CARE_TRAIN := {
	"friendship": 8.0,
	"energy": -12.0,
	"happiness": 10.0,
	"hunger": -6.0,
}
const CARE_PET := {
	"happiness": 10.0,
	"friendship": 6.0,
	"energy": -2.0,
}
const CARE_HEAL := {
	"health": 35.0,
	"energy": 8.0,
	"happiness": 4.0,
	"friendship": 2.0,
}

## XP grants for home care / future adventure hooks.
const XP_FEED := 3
const XP_PLAY := 5
const XP_REST := 2
const XP_TRAIN := 8
const XP_PET := 4
const XP_HEAL := 4
const XP_TALK := 2
const XP_COMFORT := 4
const XP_CELEBRATE := 3

const CARE_TALK := {
	"happiness": 5.0,
	"friendship": 4.0,
	"energy": -1.0,
}
const CARE_COMFORT := {
	"happiness": 14.0,
	"friendship": 8.0,
	"energy": 6.0,
	"health": 2.0,
}
const CARE_CELEBRATE := {
	"happiness": 16.0,
	"friendship": 7.0,
	"energy": -4.0,
}

var _captured: Dictionary = {}  ## instance_id -> CreatureInstance.to_dict()
var _party: PackedStringArray = PackedStringArray()
var _active: CreatureInstance = null
var _care_initialized: bool = false
var _decay_enabled: bool = true
var _partner_chosen: bool = false
var _pending_celebrate: bool = false
var _adventure_session_started: bool = false


func _initialize_manager() -> void:
	## Partner is chosen on first boot — do not auto-assign until then (or save load).
	_log("CreatureManager initialized (partner pending)")


func has_chosen_partner() -> bool:
	return _partner_chosen and _active != null


func get_starter_options() -> Array[CreatureData]:
	var out: Array[CreatureData] = []
	for sid in STARTER_OPTIONS:
		var data: CreatureData = ResourceRegistry.get_creature(sid)
		if data:
			out.append(data)
	return out


func select_partner(species_id: StringName, nickname: String = "") -> bool:
	var data: CreatureData = ResourceRegistry.get_creature(species_id)
	if data == null:
		return false
	var nick := nickname.strip_edges()
	if nick.is_empty():
		nick = data.display_name
	_active = CreatureInstance.create_from_species(data, nick)
	_care_initialized = true
	_partner_chosen = true
	_captured.clear()
	_party = PackedStringArray()
	_sync_captured_active()
	_party.append(String(_active.instance_id))
	record_memory(
		&"partner_bonded",
		CompanionMemory.Kind.FRIENDSHIP,
		"Bonded with %s" % nick,
		PackedStringArray(["partner", String(species_id)]),
	)
	EventBus.creature_captured.emit(species_id)
	EventBus.companion_state_changed.emit()
	EventBus.sfx_play_requested.emit(&"partner_select", Vector3.ZERO)
	_log("Partner chosen: %s (%s · %s)" % [nick, String(species_id), get_primary_trait_label()])
	return true


func rename_companion(new_name: String) -> bool:
	if _active == null:
		return false
	var nick := new_name.strip_edges()
	if nick.is_empty() or nick.length() > 16:
		return false
	_active.nickname = nick
	_sync_captured_active()
	EventBus.companion_state_changed.emit()
	return true


func get_primary_trait() -> StringName:
	if _active == null:
		return &"curious"
	return _active.get_primary_trait()


func get_primary_trait_label() -> String:
	return CompanionPersonality.trait_label(get_primary_trait())


func get_battle_style() -> StringName:
	return _active.get_battle_style() if _active else &"balanced"


func get_strike_power() -> float:
	return _active.get_strike_power() if _active else 10.0


func get_memories() -> Array:
	return _active.memories.duplicate(true) if _active else []


func get_memory_summary() -> String:
	return CompanionMemory.summary_line(_active.memories if _active else [])


func get_battle_history() -> Dictionary:
	return _active.battle_history.duplicate(true) if _active else {}


func get_training_style() -> StringName:
	return _active.training_style if _active else &"care"


func record_memory(memory_id: StringName, kind: CompanionMemory.Kind, label: String, tags: PackedStringArray = PackedStringArray()) -> void:
	if _active == null:
		return
	var entry := CompanionMemory.make(memory_id, kind, label, tags)
	_active.add_memory(entry)
	_sync_captured_active()
	companion_memory_recorded.emit(memory_id)
	EventBus.companion_state_changed.emit()


func mark_first_adventure() -> void:
	if _active == null or _active.first_adventure_done:
		return
	_active.first_adventure_done = true
	record_memory(
		&"first_adventure",
		CompanionMemory.Kind.FIRST_ADVENTURE,
		"First steps into the Digital Frontier together",
		PackedStringArray(["adventure", "milestone"]),
	)
	grant_adventure_bond(3.0, "")


func note_adventure_deploy() -> void:
	## Called when leaving Home for Adventure — same creature continues.
	_adventure_session_started = true
	mark_first_adventure()
	if _active:
		_active.record_training(&"explore", 1)
		_sync_captured_active()


func record_companion_battle(won: bool, enemy_id: StringName = &"", is_boss: bool = false) -> void:
	if _active == null:
		return
	_active.record_battle_result(won, enemy_id, is_boss)
	_pending_celebrate = won
	_sync_captured_active()
	companion_battle_recorded.emit(won)
	if won:
		var label := "Won a battle together"
		var kind := CompanionMemory.Kind.BATTLE
		if is_boss:
			label = "Defeated a boss together"
			kind = CompanionMemory.Kind.BOSS
			record_memory(StringName("boss_%s" % String(enemy_id)), kind, label, PackedStringArray(["boss", String(enemy_id)]))
		elif _active.get_battles_won() == 1 or _active.get_battles_won() % 5 == 0:
			record_memory(StringName("battle_win_%d" % _active.get_battles_won()), kind, label, PackedStringArray(["battle"]))
		grant_adventure_bond(1.5 if not is_boss else 4.0, "")
	EventBus.companion_state_changed.emit()
	check_evolution_after_growth()


func record_companion_strike() -> void:
	if _active == null:
		return
	_active.record_strike()
	_sync_captured_active()


func consume_celebrate_pending() -> bool:
	if not _pending_celebrate:
		return false
	_pending_celebrate = false
	return true


func set_decay_enabled(enabled: bool) -> void:
	_decay_enabled = enabled


func _process(delta: float) -> void:
	if not _care_initialized or not _decay_enabled or _active == null:
		return
	_active.apply_passive_decay(delta)


# --- Active companion access ---

func get_active_instance() -> CreatureInstance:
	return _active


func get_companion_id() -> StringName:
	return _active.species_id if _active else STARTER_CREATURE_ID


func get_companion_instance_id() -> StringName:
	return _active.instance_id if _active else &""


func get_companion_nickname() -> String:
	return _active.nickname if _active else "Companion"


func get_level() -> int:
	return _active.level if _active else 1


func get_experience() -> int:
	return _active.experience if _active else 0


func get_xp_progress() -> float:
	return _active.get_xp_progress() if _active else 0.0


func get_skin_id() -> StringName:
	return _active.skin_id if _active else &"default"


func get_evolution_stage() -> int:
	return _active.evolution_stage if _active else 0


func get_stage_display_name() -> String:
	var species := get_species_data()
	if species == null:
		return get_companion_nickname()
	if _active and _active.evolution_path_id != &"":
		var path: EvolutionPathData = ResourceRegistry.get_evolution_path(_active.evolution_path_id)
		if path and not path.form_display_name.is_empty() and path.to_stage == _active.evolution_stage:
			return path.form_display_name
	var stage := get_evolution_stage()
	if stage >= 0 and stage < species.stage_display_names.size():
		return String(species.stage_display_names[stage])
	return species.display_name if not species.display_name.is_empty() else get_companion_nickname()


func can_evolve() -> bool:
	return not get_available_evolution_paths().is_empty() or _can_legacy_evolve()


func _can_legacy_evolve() -> bool:
	if _active == null:
		return false
	if not ResourceRegistry.get_evolution_paths_for(_active.species_id, _active.evolution_stage).is_empty():
		return false
	var species := get_species_data()
	if species == null:
		return false
	var next := _active.evolution_stage + 1
	if next > species.max_evolution_stage:
		return false
	var idx := _active.evolution_stage
	var need_level := 99
	var need_friend := 100.0
	if idx < species.evolve_level_thresholds.size():
		need_level = int(species.evolve_level_thresholds[idx])
	if idx < species.evolve_friendship_thresholds.size():
		need_friend = float(species.evolve_friendship_thresholds[idx])
	return get_level() >= need_level and get_friendship() >= need_friend


func get_available_evolution_paths() -> Array:
	if _active == null:
		return []
	var paths: Array = ResourceRegistry.get_evolution_paths_for(_active.species_id, _active.evolution_stage)
	var qualifying: Array = []
	for path in paths:
		if path is EvolutionPathData and _path_requirements_met(path as EvolutionPathData):
			qualifying.append(path)
	return qualifying


func _path_requirements_met(path: EvolutionPathData) -> bool:
	if get_level() < path.need_level:
		return false
	if get_friendship() < path.need_friendship:
		return false
	if path.need_battles_won > 0 and _active.get_battles_won() < path.need_battles_won:
		return false
	if path.need_training_style != &"":
		var counts: Dictionary = _active.training_counts
		var style_n := int(counts.get(String(path.need_training_style), 0))
		var best_n := 0
		for k in counts.keys():
			best_n = maxi(best_n, int(counts[k]))
		if style_n < best_n:
			return false
	if path.need_trait != &"" and _active.get_personality(String(path.need_trait), 0.0) < path.need_trait_min:
		return false
	if path.need_memory_id != &"" and not _active.has_memory(path.need_memory_id):
		return false
	if path.need_world_flag != &"" and not bool(WorldManager.get_world_flag(path.need_world_flag, false)):
		return false
	return true


func try_evolve(preferred_path_id: StringName = &"") -> Dictionary:
	var paths := get_available_evolution_paths()
	var chosen: EvolutionPathData = null
	if preferred_path_id != &"":
		for p in paths:
			if p is EvolutionPathData and (p as EvolutionPathData).id == preferred_path_id:
				chosen = p as EvolutionPathData
				break
	if chosen == null and not paths.is_empty():
		chosen = paths[0] as EvolutionPathData
	if chosen != null:
		return _apply_evolution_path(chosen)
	if not _can_legacy_evolve():
		return {"evolved": false, "stage": get_evolution_stage(), "name": get_stage_display_name(), "message": "", "path_id": &""}
	_active.evolution_stage += 1
	for key in _active.stats.keys():
		_active.stats[key] = float(_active.stats[key]) * 1.12 + 1.0
	_active.happiness = minf(100.0, _active.happiness + 12.0)
	_active.friendship = minf(100.0, _active.friendship + 8.0)
	_sync_captured_active()
	var new_name := get_stage_display_name()
	EventBus.companion_state_changed.emit()
	DeviceService.notify_event(&"achievement")
	EventBus.sfx_play_requested.emit(&"evolve", Vector3.ZERO)
	var msg := "%s evolved into %s!" % [get_companion_nickname(), new_name]
	EventBus.ui_notification_requested.emit(msg, 3.2)
	record_memory(
		StringName("evolved_stage_%d" % _active.evolution_stage),
		CompanionMemory.Kind.EVOLUTION,
		"Evolved into %s" % new_name,
		PackedStringArray(["evolution"]),
	)
	companion_evolved.emit(&"", _active.evolution_stage)
	return {"evolved": true, "stage": _active.evolution_stage, "name": new_name, "message": msg, "path_id": &""}


func _apply_evolution_path(path: EvolutionPathData) -> Dictionary:
	_active.evolution_stage = path.to_stage
	_active.evolution_path_id = path.id
	for key in _active.stats.keys():
		var bias := float(path.stat_bias.get(key, 1.0))
		_active.stats[key] = float(_active.stats[key]) * (1.12 * bias) + 1.0
	_active.happiness = minf(100.0, _active.happiness + 14.0)
	_active.friendship = minf(100.0, _active.friendship + 10.0)
	_sync_captured_active()
	var new_name := path.form_display_name if not path.form_display_name.is_empty() else get_stage_display_name()
	EventBus.companion_state_changed.emit()
	DeviceService.notify_event(&"achievement")
	EventBus.sfx_play_requested.emit(&"evolve", Vector3.ZERO)
	var msg := "%s evolved into %s!" % [get_companion_nickname(), new_name]
	if not path.blurb.is_empty():
		msg += "  %s" % path.blurb
	EventBus.ui_notification_requested.emit(msg, 3.6)
	record_memory(
		StringName("evolved_%s" % String(path.id)),
		CompanionMemory.Kind.EVOLUTION,
		"Became %s" % new_name,
		PackedStringArray(["evolution", String(path.id)]),
	)
	companion_evolved.emit(path.id, _active.evolution_stage)
	return {"evolved": true, "stage": _active.evolution_stage, "name": new_name, "message": msg, "path_id": path.id}


func check_evolution_after_growth() -> void:
	if can_evolve():
		try_evolve()


func get_stats() -> Dictionary:
	return _active.stats.duplicate() if _active else {}


func get_personality_snapshot() -> Dictionary:
	return _active.personality.duplicate() if _active else {}


func get_hunger() -> float:
	return _active.hunger if _active else 0.0


func get_happiness() -> float:
	return _active.happiness if _active else 0.0


func get_energy() -> float:
	return _active.energy if _active else 0.0


func get_friendship() -> float:
	return _active.friendship if _active else 0.0


func get_health() -> float:
	return _active.health if _active else 0.0


func get_mood_value() -> float:
	return get_happiness()


func get_needs_snapshot() -> Dictionary:
	return {
		"creature_id": String(get_companion_id()),
		"instance_id": String(get_companion_instance_id()),
		"display_name": get_companion_nickname(),
		"stage_name": get_stage_display_name(),
		"level": get_level(),
		"experience": get_experience(),
		"xp_progress": get_xp_progress(),
		"hunger": get_hunger(),
		"happiness": get_happiness(),
		"energy": get_energy(),
		"friendship": get_friendship(),
		"health": get_health(),
		"mood": get_mood_label(),
		"mood_value": get_happiness(),
		"skin_id": String(get_skin_id()),
		"evolution_stage": get_evolution_stage(),
		"can_evolve": can_evolve(),
		"stats": get_stats(),
		"personality": get_personality_snapshot(),
		"primary_trait": String(get_primary_trait()),
		"primary_trait_label": get_primary_trait_label(),
		"battle_style": String(get_battle_style()),
		"training_style": String(get_training_style()),
		"battle_history": get_battle_history(),
		"memory_summary": get_memory_summary(),
		"adventure_ready": is_adventure_ready(),
		"readiness_score": get_readiness_score(),
	}


func get_mood() -> Mood:
	if get_health() < 30.0:
		return Mood.SAD
	if get_energy() < 25.0:
		return Mood.TIRED
	if get_hunger() < 20.0:
		return Mood.IRRITABLE
	if get_happiness() >= 85.0 and get_energy() > 55.0:
		return Mood.EXCITED
	if get_happiness() >= 65.0:
		return Mood.HAPPY
	if get_happiness() >= 45.0:
		return Mood.CONTENT
	if get_happiness() >= 25.0:
		return Mood.BORED
	return Mood.SAD


func get_mood_label() -> String:
	match get_mood():
		Mood.EXCITED: return "Excited"
		Mood.HAPPY: return "Happy"
		Mood.CONTENT: return "Content"
		Mood.BORED: return "Bored"
		Mood.SAD: return "Sad"
		Mood.IRRITABLE: return "Irritable"
		Mood.TIRED: return "Tired"
		_: return "Unknown"


func get_hunger_label() -> String:
	if get_hunger() >= 80.0:
		return "Full"
	if get_hunger() >= 55.0:
		return "Okay"
	if get_hunger() >= 30.0:
		return "Peckish"
	if get_hunger() >= 10.0:
		return "Hungry"
	return "Starving"


func get_energy_label() -> String:
	if get_energy() >= 75.0:
		return "Rested"
	if get_energy() >= 45.0:
		return "Okay"
	if get_energy() >= 20.0:
		return "Sleepy"
	return "Exhausted"


func get_status_line() -> String:
	var name := get_companion_nickname()
	var form := get_stage_display_name()
	var trait_l := get_primary_trait_label()
	match get_mood():
		Mood.EXCITED:
			return "%s (Lv.%d · %s · %s) is buzzing — ready!" % [name, get_level(), form, trait_l]
		Mood.HAPPY:
			return "%s looks happy. %s" % [name, get_memory_summary()]
		Mood.CONTENT:
			return "%s is calm (%s). A little playtime wouldn't hurt." % [name, trait_l]
		Mood.BORED:
			return "%s seems bored. Try talking or playing." % name
		Mood.SAD:
			return "%s looks down. Comfort them." % name
		Mood.IRRITABLE:
			return "%s is too hungry to focus. Feed them first." % name
		Mood.TIRED:
			return "%s can barely keep their eyes open. Comfort or rest." % name
		_:
			return "%s is waiting." % name


func get_detailed_status() -> String:
	var snap := get_needs_snapshot()
	var stats: Dictionary = snap.get("stats", {})
	var hist: Dictionary = snap.get("battle_history", {})
	return "%s  ·  Lv.%d  ·  %s  ·  %s\nHunger %s · Energy %s · Bond %d\nATK %d  DEF %d  SPD %d\nBattles %dW/%dL  ·  %s\n%s" % [
		snap.get("display_name", "?"),
		int(snap.get("level", 1)),
		snap.get("mood", "?"),
		snap.get("primary_trait_label", "?"),
		get_hunger_label(),
		get_energy_label(),
		int(snap.get("friendship", 0)),
		int(stats.get("attack", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("speed", 0)),
		int(hist.get("wins", 0)),
		int(hist.get("losses", 0)),
		snap.get("battle_style", "balanced"),
		snap.get("memory_summary", ""),
	]


func get_mood_color() -> Color:
	match get_mood():
		Mood.EXCITED: return Color(0.45, 0.95, 0.85)
		Mood.HAPPY: return Color(0.35, 0.82, 0.78)
		Mood.CONTENT: return Color(0.55, 0.72, 0.95)
		Mood.BORED: return Color(0.65, 0.65, 0.55)
		Mood.SAD: return Color(0.45, 0.5, 0.7)
		Mood.IRRITABLE: return Color(0.9, 0.45, 0.35)
		Mood.TIRED: return Color(0.55, 0.5, 0.75)
		_: return Color(0.5, 0.5, 0.5)


func get_readiness_score() -> float:
	return clampf(
		get_hunger() * 0.20
		+ get_happiness() * 0.25
		+ get_energy() * 0.30
		+ get_health() * 0.15
		+ get_friendship() * 0.10,
		0.0,
		100.0,
	)


func is_adventure_ready() -> bool:
	return get_readiness_score() >= 35.0 and get_mood() != Mood.SAD


func get_behavior_bias() -> StringName:
	if _active:
		return _active.get_behavior_bias()
	return &"idle"


func get_walk_speed_multiplier() -> float:
	return _active.get_walk_speed_multiplier() if _active else 1.0


# --- Care / interaction ---

func feed() -> String:
	return _care(&"feed", CARE_FEED, XP_FEED, "You filled the bowl. %s digs in happily!", &"care")


func play() -> String:
	return _care(&"play", CARE_PLAY, XP_PLAY, "You played together. %s is happier!", &"care")


func rest() -> String:
	return _care(&"rest", CARE_REST, XP_REST, "%s curled up and feels restored.", &"care")


func train() -> String:
	return _care(&"train", CARE_TRAIN, XP_TRAIN, "Training complete. %s feels stronger and closer.", &"train")


func pet() -> String:
	return _care(&"pet", CARE_PET, XP_PET, "%s leans into your hand. Bond grows.", &"care")


func heal() -> String:
	return _care(&"heal", CARE_HEAL, XP_HEAL, "A soft digital glow. %s feels mended.", &"care")


func talk() -> String:
	if _active == null:
		return "No companion nearby."
	var line: String = CompanionPersonality.talk_line(_active.personality, get_mood_label(), &"idle")
	var msg := _care(&"talk", CARE_TALK, XP_TALK, "%s listens closely." % get_companion_nickname(), &"care")
	msg = "%s: \"%s\"" % [get_companion_nickname(), line]
	if get_friendship() >= 50.0 and not _active.has_memory(&"deep_talk"):
		record_memory(&"deep_talk", CompanionMemory.Kind.CARE, "A quiet talk that meant something", PackedStringArray(["care", "bond"]))
	return msg


func comfort() -> String:
	if _active == null:
		return "No companion nearby."
	var line: String = CompanionPersonality.talk_line(_active.personality, get_mood_label(), &"comfort")
	_care(&"comfort", CARE_COMFORT, XP_COMFORT, "%s feels safer." % get_companion_nickname(), &"care")
	return "%s: \"%s\"" % [get_companion_nickname(), line]


func celebrate() -> String:
	if _active == null:
		return "No companion nearby."
	_pending_celebrate = false
	var line: String = CompanionPersonality.talk_line(_active.personality, get_mood_label(), &"victory")
	_care(&"celebrate", CARE_CELEBRATE, XP_CELEBRATE, "%s celebrates!" % get_companion_nickname(), &"care")
	return "%s: \"%s\"" % [get_companion_nickname(), line]


func interact() -> String:
	## Digi-pet Interact — context-aware: comfort when low, celebrate after wins, else talk.
	if _active == null:
		return "No companion nearby."
	if _pending_celebrate:
		return celebrate()
	if get_mood() == Mood.SAD or get_mood() == Mood.TIRED or get_happiness() < 35.0:
		return comfort()
	return talk()


func get_adventure_status_line() -> String:
	return "%s  Lv.%d  ·  %s  ·  %s  ·  Bond %d%%" % [
		get_stage_display_name(),
		get_level(),
		get_primary_trait_label(),
		get_mood_label(),
		int(get_friendship()),
	]


func get_partner_quip(context: StringName = &"idle") -> String:
	if _active == null:
		return "…"
	return CompanionPersonality.talk_line(_active.personality, get_mood_label(), context)


func grant_adventure_experience(amount: int) -> Dictionary:
	## Hook for world gameplay — same creature continues across modes.
	if _active == null or amount <= 0:
		return {}
	var result := _active.add_experience(amount)
	_sync_captured_active()
	EventBus.companion_state_changed.emit()
	if bool(result.get("leveled_up", false)):
		DeviceService.notify_event(&"achievement")
		EventBus.ui_notification_requested.emit(
			"%s reached Lv.%d!" % [get_companion_nickname(), get_level()],
			2.8,
		)
		check_evolution_after_growth()
	return result


func grant_adventure_bond(amount: float, reason: String = "") -> void:
	## Friendship + tiny happiness from exploring together.
	if _active == null or amount == 0.0:
		return
	_active.apply_care(&"adventure", {
		"friendship": amount,
		"happiness": amount * 0.35,
	})
	_active.record_training(&"explore", 1)
	_sync_captured_active()
	EventBus.companion_state_changed.emit()
	if not reason.is_empty():
		EventBus.ui_notification_requested.emit("%s — bond +%.0f" % [reason, amount], 1.8)
	check_evolution_after_growth()


func get_active_ability_ids() -> PackedStringArray:
	var species := get_species_data()
	if species == null:
		return PackedStringArray()
	return species.ability_ids


func get_species_data() -> CreatureData:
	if _active == null:
		return ResourceRegistry.get_creature(STARTER_CREATURE_ID)
	return _active.get_species()


func get_party() -> PackedStringArray:
	return _party


func get_collection_count() -> int:
	return _captured.size()


func export_state() -> Dictionary:
	_sync_captured_active()
	return {
		&"captured": _captured.duplicate(true),
		&"party": _party.duplicate(),
		&"active_instance_id": String(get_companion_instance_id()),
		## Legacy flat keys for older readers / migration.
		&"companion_id": get_companion_id(),
		&"companion_nickname": get_companion_nickname(),
		&"companion_hunger": get_hunger(),
		&"companion_mood_value": get_happiness(),
		&"companion_happiness": get_happiness(),
		&"companion_energy": get_energy(),
		&"companion_friendship": get_friendship(),
		&"companion_health": get_health(),
		&"care_initialized": _care_initialized,
		&"partner_chosen": _partner_chosen,
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return

	if data.has(&"captured"):
		_captured = data[&"captured"].duplicate(true)
	if data.has(&"party"):
		_party = data[&"party"].duplicate()

	var active_id := StringName(str(data.get(&"active_instance_id", data.get("active_instance_id", ""))))
	if active_id != &"" and _captured.has(String(active_id)):
		_active = CreatureInstance.from_dict(_captured[String(active_id)])
	elif active_id != &"" and _captured.has(active_id):
		_active = CreatureInstance.from_dict(_captured[active_id])
	elif not _captured.is_empty():
		var first_key = _captured.keys()[0]
		_active = CreatureInstance.from_dict(_captured[first_key])
	elif data.has(&"companion_id") or data.has("companion_id"):
		## Migrate legacy flat companion fields into a new instance.
		_migrate_legacy_flat(data)

	if data.has(&"care_initialized"):
		_care_initialized = bool(data[&"care_initialized"])
	if data.has(&"partner_chosen") or data.has("partner_chosen"):
		_partner_chosen = bool(data.get(&"partner_chosen", data.get("partner_chosen", false)))
	elif _active != null:
		## Older saves with a companion count as chosen.
		_partner_chosen = true
		_care_initialized = true

	if _active != null:
		_care_initialized = true
		_partner_chosen = true
		_sync_captured_active()
	EventBus.companion_state_changed.emit()


func _migrate_legacy_flat(data: Dictionary) -> void:
	var species_id := StringName(str(data.get(&"companion_id", data.get("companion_id", STARTER_CREATURE_ID))))
	var species: CreatureData = ResourceRegistry.get_creature(species_id)
	if species == null:
		species = ResourceRegistry.get_creature(STARTER_CREATURE_ID)
	if species == null:
		return
	var nick := str(data.get(&"companion_nickname", data.get("companion_nickname", species.display_name)))
	_active = CreatureInstance.create_from_species(species, nick)
	if data.has(&"companion_hunger"):
		_active.hunger = float(data[&"companion_hunger"])
	if data.has(&"companion_happiness"):
		_active.happiness = float(data[&"companion_happiness"])
	elif data.has(&"companion_mood_value"):
		_active.happiness = float(data[&"companion_mood_value"])
	if data.has(&"companion_energy"):
		_active.energy = float(data[&"companion_energy"])
	if data.has(&"companion_friendship"):
		_active.friendship = float(data[&"companion_friendship"])
	if data.has(&"companion_health"):
		_active.health = float(data[&"companion_health"])
	_active.clamp_needs()
	_sync_captured_active()


func _ensure_starter_companion() -> void:
	## Kept for legacy callers / smoke tests — prefers chosen partner.
	if _active != null:
		_care_initialized = true
		_partner_chosen = true
		_sync_captured_active()
		return
	if not _partner_chosen:
		return
	var data: CreatureData = ResourceRegistry.get_creature(STARTER_CREATURE_ID)
	if data == null:
		data = ResourceRegistry.get_creature(&"sparkbit")
	if data == null:
		data = ResourceRegistry.get_creature(&"tidepup")
	if data == null:
		push_warning("CreatureManager: no starter species found")
		return
	_active = CreatureInstance.create_from_species(data)
	_care_initialized = true
	_partner_chosen = true
	_sync_captured_active()
	if _party.is_empty():
		_party.append(String(_active.instance_id))


func _care(action: StringName, base_deltas: Dictionary, xp: int, message_fmt: String, training: StringName = &"care") -> String:
	if _active == null:
		return "No companion nearby."
	var deltas := base_deltas.duplicate()
	var species := _active.get_species()
	if species and species.care_affinities.has(String(action)):
		var mult := float(species.care_affinities[String(action)])
		for key: String in deltas.keys():
			deltas[key] = float(deltas[key]) * mult
	_active.apply_care(action, deltas)
	_active.record_training(training, 1)
	var level_info := _active.add_experience(xp)
	_sync_captured_active()
	_emit_care(action)
	var msg := message_fmt
	if message_fmt.find("%s") >= 0:
		msg = message_fmt % get_companion_nickname()
	if level_info.get("leveled_up", false):
		msg += "  Level up! Now Lv.%d." % int(level_info.get("new_level", get_level()))
	check_evolution_after_growth()
	return msg


func _emit_care(action: StringName) -> void:
	EventBus.companion_cared.emit(action)
	EventBus.companion_state_changed.emit()


func _sync_captured_active() -> void:
	if _active == null:
		return
	_captured[String(_active.instance_id)] = _active.to_dict()
