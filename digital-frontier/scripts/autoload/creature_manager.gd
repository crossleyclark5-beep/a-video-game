extends BaseManager
## Creature collection, party, and living companion needs.
##
## Expanded needs model (happiness / hunger / energy / friendship / health)
## powers the Home habitat. Templates live in CreatureData; this manager owns
## runtime values. Designed for multiple creatures, skins, and homes later.

enum Mood {
	EXCITED,
	HAPPY,
	CONTENT,
	BORED,
	SAD,
	IRRITABLE,
	TIRED,
}

const STARTER_CREATURE_ID := &"pixel_fox"

## Soft decay rates per real-time second while the game is open.
const DECAY_HUNGER := 0.35
const DECAY_ENERGY := 0.18
const DECAY_HAPPINESS := 0.08
const DECAY_HEALTH_WHEN_NEGLECTED := 0.05

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

var _captured: Dictionary = {}
var _party: PackedStringArray = PackedStringArray()
var _companion_species_id: StringName = STARTER_CREATURE_ID
var _companion_nickname: String = "Pixel Fox"

## Needs — 0 empty / depleted → 100 full / thriving.
## Hunger is "fullness" (high = fed), matching the original home loop.
var _hunger: float = 72.0
var _happiness: float = 70.0
var _energy: float = 80.0
var _friendship: float = 40.0
var _health: float = 95.0

var _care_initialized: bool = false
var _decay_enabled: bool = true


func _initialize_manager() -> void:
	_ensure_starter_companion()
	_log("CreatureManager initialized (companion=%s)" % _companion_species_id)


func _process(delta: float) -> void:
	if not _care_initialized or not _decay_enabled:
		return
	_apply_passive_decay(delta)


func set_decay_enabled(enabled: bool) -> void:
	_decay_enabled = enabled


# --- Companion getters ---

func get_companion_id() -> StringName:
	return _companion_species_id


func get_companion_nickname() -> String:
	return _companion_nickname


func get_hunger() -> float:
	return _hunger


func get_happiness() -> float:
	return _happiness


func get_energy() -> float:
	return _energy


func get_friendship() -> float:
	return _friendship


func get_health() -> float:
	return _health


## Legacy alias — older UI treated mood_value as a single meter.
func get_mood_value() -> float:
	return _happiness


func get_needs_snapshot() -> Dictionary:
	return {
		"creature_id": String(_companion_species_id),
		"display_name": _companion_nickname,
		"hunger": _hunger,
		"happiness": _happiness,
		"energy": _energy,
		"friendship": _friendship,
		"health": _health,
		"mood": get_mood_label(),
		"mood_value": _happiness,
		"adventure_ready": is_adventure_ready(),
		"readiness_score": get_readiness_score(),
	}


func get_mood() -> Mood:
	if _health < 30.0:
		return Mood.SAD
	if _energy < 25.0:
		return Mood.TIRED
	if _hunger < 20.0:
		return Mood.IRRITABLE
	if _happiness >= 85.0 and _energy > 55.0:
		return Mood.EXCITED
	if _happiness >= 65.0:
		return Mood.HAPPY
	if _happiness >= 45.0:
		return Mood.CONTENT
	if _happiness >= 25.0:
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
	if _hunger >= 80.0:
		return "Full"
	if _hunger >= 55.0:
		return "Okay"
	if _hunger >= 30.0:
		return "Peckish"
	if _hunger >= 10.0:
		return "Hungry"
	return "Starving"


func get_energy_label() -> String:
	if _energy >= 75.0:
		return "Rested"
	if _energy >= 45.0:
		return "Okay"
	if _energy >= 20.0:
		return "Sleepy"
	return "Exhausted"


func get_status_line() -> String:
	match get_mood():
		Mood.EXCITED:
			return "%s is buzzing with energy — ready for adventure!" % _companion_nickname
		Mood.HAPPY:
			return "%s looks happy and ready to explore." % _companion_nickname
		Mood.CONTENT:
			return "%s is calm. A little playtime wouldn't hurt." % _companion_nickname
		Mood.BORED:
			return "%s seems bored. Try playing together." % _companion_nickname
		Mood.SAD:
			return "%s looks down. Some care would help." % _companion_nickname
		Mood.IRRITABLE:
			return "%s is too hungry to focus. Feed them first." % _companion_nickname
		Mood.TIRED:
			return "%s can barely keep their eyes open. Time for bed." % _companion_nickname
		_:
			return "%s is waiting." % _companion_nickname


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
		_hunger * 0.20 + _happiness * 0.25 + _energy * 0.30 + _health * 0.15 + _friendship * 0.10,
		0.0,
		100.0,
	)


## Soft gate — adventure always allowed, but returns false when care is critical.
func is_adventure_ready() -> bool:
	return get_readiness_score() >= 35.0 and get_mood() != Mood.SAD


## Hint for companion AI — what the creature wants most right now.
func get_behavior_bias() -> StringName:
	if _energy < 28.0:
		return &"sleep"
	if _hunger < 35.0:
		return &"eat"
	if _happiness < 40.0:
		return &"play"
	if _energy > 70.0 and _happiness > 60.0:
		return &"playful"
	return &"idle"


# --- Care actions (return player-facing status strings for HUD) ---

func feed() -> String:
	_apply_care_deltas(CARE_FEED)
	_emit_care(&"feed")
	return "You filled the bowl. %s digs in happily!" % _companion_nickname


func play() -> String:
	_apply_care_deltas(CARE_PLAY)
	_emit_care(&"play")
	return "You played together. %s is happier!" % _companion_nickname


func rest() -> String:
	_apply_care_deltas(CARE_REST)
	_emit_care(&"rest")
	return "%s curled up and feels restored." % _companion_nickname


func train() -> String:
	_apply_care_deltas(CARE_TRAIN)
	_emit_care(&"train")
	return "A little training session. %s feels closer to you." % _companion_nickname


func get_party() -> PackedStringArray:
	return _party


func export_state() -> Dictionary:
	return {
		&"captured": _captured.duplicate(true),
		&"party": _party.duplicate(),
		&"companion_id": _companion_species_id,
		&"companion_nickname": _companion_nickname,
		&"companion_hunger": _hunger,
		&"companion_mood_value": _happiness,
		&"companion_happiness": _happiness,
		&"companion_energy": _energy,
		&"companion_friendship": _friendship,
		&"companion_health": _health,
		&"care_initialized": _care_initialized,
	}


func import_state(data: Dictionary) -> void:
	if data.has(&"captured"):
		_captured = data[&"captured"].duplicate(true)
	if data.has(&"party"):
		_party = data[&"party"].duplicate()
	if data.has(&"companion_id"):
		_companion_species_id = data[&"companion_id"]
	if data.has(&"companion_nickname"):
		_companion_nickname = data[&"companion_nickname"]
	if data.has(&"companion_hunger"):
		_hunger = float(data[&"companion_hunger"])
	if data.has(&"companion_happiness"):
		_happiness = float(data[&"companion_happiness"])
	elif data.has(&"companion_mood_value"):
		_happiness = float(data[&"companion_mood_value"])
	if data.has(&"companion_energy"):
		_energy = float(data[&"companion_energy"])
	if data.has(&"companion_friendship"):
		_friendship = float(data[&"companion_friendship"])
	if data.has(&"companion_health"):
		_health = float(data[&"companion_health"])
	if data.has(&"care_initialized"):
		_care_initialized = bool(data[&"care_initialized"])
	_clamp_all()
	_ensure_starter_companion()
	EventBus.companion_state_changed.emit()


func _ensure_starter_companion() -> void:
	if _care_initialized:
		return
	var data: CreatureData = ResourceRegistry.get_creature(STARTER_CREATURE_ID)
	if data != null and not data.display_name.is_empty():
		_companion_nickname = data.display_name
	_companion_species_id = STARTER_CREATURE_ID
	_care_initialized = true


func _apply_care_deltas(deltas: Dictionary) -> void:
	for key: String in deltas.keys():
		match key:
			"hunger":
				_hunger = clampf(_hunger + float(deltas[key]), 0.0, 100.0)
			"happiness":
				_happiness = clampf(_happiness + float(deltas[key]), 0.0, 100.0)
			"energy":
				_energy = clampf(_energy + float(deltas[key]), 0.0, 100.0)
			"friendship":
				_friendship = clampf(_friendship + float(deltas[key]), 0.0, 100.0)
			"health":
				_health = clampf(_health + float(deltas[key]), 0.0, 100.0)


func _emit_care(action: StringName) -> void:
	EventBus.companion_cared.emit(action)
	EventBus.companion_state_changed.emit()


func _apply_passive_decay(delta: float) -> void:
	_hunger = maxf(0.0, _hunger - DECAY_HUNGER * delta)
	_energy = maxf(0.0, _energy - DECAY_ENERGY * delta)
	var happiness_drain := DECAY_HAPPINESS * delta
	if _hunger < 25.0:
		happiness_drain *= 2.0
	_happiness = maxf(0.0, _happiness - happiness_drain)

	var neglect := 0
	if _hunger < 25.0:
		neglect += 1
	if _energy < 20.0:
		neglect += 1
	if _happiness < 25.0:
		neglect += 1
	if neglect >= 2:
		_health = maxf(0.0, _health - DECAY_HEALTH_WHEN_NEGLECTED * delta * float(neglect))

	if _hunger > 70.0 and _energy > 60.0 and _happiness > 60.0:
		_health = minf(100.0, _health + 0.02 * delta)
		_friendship = minf(100.0, _friendship + 0.01 * delta)


func _clamp_all() -> void:
	_hunger = clampf(_hunger, 0.0, 100.0)
	_happiness = clampf(_happiness, 0.0, 100.0)
	_energy = clampf(_energy, 0.0, 100.0)
	_friendship = clampf(_friendship, 0.0, 100.0)
	_health = clampf(_health, 0.0, 100.0)
