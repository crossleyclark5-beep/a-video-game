extends BaseManager
## Creature collection, party, and living companion ownership.
##
## Active companion is a CreatureInstance (data-driven). Species templates
## live in CreatureData. Home + adventure share the same instance state.

enum Mood {
	EXCITED,
	HAPPY,
	CONTENT,
	BORED,
	SAD,
	IRRITABLE,
	TIRED,
}

const STARTER_CREATURE_ID := &"sparkbit"

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

## XP grants for home care / future adventure hooks.
const XP_FEED := 3
const XP_PLAY := 5
const XP_REST := 2
const XP_TRAIN := 8
const XP_PET := 4

var _captured: Dictionary = {}  ## instance_id -> CreatureInstance.to_dict()
var _party: PackedStringArray = PackedStringArray()
var _active: CreatureInstance = null
var _care_initialized: bool = false
var _decay_enabled: bool = true


func _initialize_manager() -> void:
	_ensure_starter_companion()
	_log("CreatureManager initialized (companion=%s)" % get_companion_nickname())


func _process(delta: float) -> void:
	if not _care_initialized or not _decay_enabled or _active == null:
		return
	_active.apply_passive_decay(delta)


func set_decay_enabled(enabled: bool) -> void:
	_decay_enabled = enabled


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
		"stats": get_stats(),
		"personality": get_personality_snapshot(),
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
	match get_mood():
		Mood.EXCITED:
			return "%s (Lv.%d) is buzzing — ready for adventure!" % [name, get_level()]
		Mood.HAPPY:
			return "%s looks happy and ready to explore." % name
		Mood.CONTENT:
			return "%s is calm. A little playtime wouldn't hurt." % name
		Mood.BORED:
			return "%s seems bored. Try playing or petting them." % name
		Mood.SAD:
			return "%s looks down. Some care would help." % name
		Mood.IRRITABLE:
			return "%s is too hungry to focus. Feed them first." % name
		Mood.TIRED:
			return "%s can barely keep their eyes open. Time for bed." % name
		_:
			return "%s is waiting." % name


func get_detailed_status() -> String:
	var snap := get_needs_snapshot()
	var stats: Dictionary = snap.get("stats", {})
	return "%s  ·  Lv.%d  ·  %s\nHunger %s · Energy %s · Bond %d\nATK %d  DEF %d  SPD %d" % [
		snap.get("display_name", "?"),
		int(snap.get("level", 1)),
		snap.get("mood", "?"),
		get_hunger_label(),
		get_energy_label(),
		int(snap.get("friendship", 0)),
		int(stats.get("attack", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("speed", 0)),
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
	return _care(&"feed", CARE_FEED, XP_FEED, "You filled the bowl. %s digs in happily!")


func play() -> String:
	return _care(&"play", CARE_PLAY, XP_PLAY, "You played together. %s is happier!")


func rest() -> String:
	return _care(&"rest", CARE_REST, XP_REST, "%s curled up and feels restored.")


func train() -> String:
	return _care(&"train", CARE_TRAIN, XP_TRAIN, "Training complete. %s feels stronger and closer.")


func pet() -> String:
	return _care(&"pet", CARE_PET, XP_PET, "%s leans into your hand. Bond grows.")


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
	return result


func grant_adventure_bond(amount: float, reason: String = "") -> void:
	## Friendship + tiny happiness from exploring together.
	if _active == null or amount == 0.0:
		return
	_active.apply_care(&"adventure", {
		"friendship": amount,
		"happiness": amount * 0.35,
	})
	_sync_captured_active()
	EventBus.companion_state_changed.emit()
	if not reason.is_empty():
		EventBus.ui_notification_requested.emit("%s — bond +%.0f" % [reason, amount], 1.8)


func get_adventure_status_line() -> String:
	return "%s  Lv.%d  ·  %s  ·  Bond %d%%" % [
		get_companion_nickname(),
		get_level(),
		get_mood_label(),
		int(get_friendship()),
	]


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
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		_ensure_starter_companion()
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
	else:
		## Migrate legacy flat companion fields into a new instance.
		_migrate_legacy_flat(data)

	if data.has(&"care_initialized"):
		_care_initialized = bool(data[&"care_initialized"])
	_ensure_starter_companion()
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
	if _active != null:
		_care_initialized = true
		_sync_captured_active()
		return
	var data: CreatureData = ResourceRegistry.get_creature(STARTER_CREATURE_ID)
	if data == null:
		data = ResourceRegistry.get_creature(&"pixel_fox")
	if data == null:
		push_warning("CreatureManager: no starter species found")
		return
	_active = CreatureInstance.create_from_species(data)
	_care_initialized = true
	_sync_captured_active()
	if _party.is_empty():
		_party.append(String(_active.instance_id))


func _care(action: StringName, base_deltas: Dictionary, xp: int, message_fmt: String) -> String:
	if _active == null:
		return "No companion nearby."
	var deltas := base_deltas.duplicate()
	var species := _active.get_species()
	if species and species.care_affinities.has(String(action)):
		var mult := float(species.care_affinities[String(action)])
		for key: String in deltas.keys():
			deltas[key] = float(deltas[key]) * mult
	_active.apply_care(action, deltas)
	var level_info := _active.add_experience(xp)
	_sync_captured_active()
	_emit_care(action)
	var msg := message_fmt % get_companion_nickname()
	if level_info.get("leveled_up", false):
		msg += "  Level up! Now Lv.%d." % int(level_info.get("new_level", get_level()))
	return msg


func _emit_care(action: StringName) -> void:
	EventBus.companion_cared.emit(action)
	EventBus.companion_state_changed.emit()


func _sync_captured_active() -> void:
	if _active == null:
		return
	_captured[String(_active.instance_id)] = _active.to_dict()
