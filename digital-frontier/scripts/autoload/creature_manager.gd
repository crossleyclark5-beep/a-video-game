extends BaseManager
## Creature collection, party, and living companion state.
##
## Companion care (mood / hunger) powers the Home screen loop.
## Templates live in CreatureData; this manager owns runtime values.

enum Mood {
	EXCITED,
	HAPPY,
	CONTENT,
	BORED,
	SAD,
	IRRITABLE,
}

const STARTER_CREATURE_ID := &"pixel_fox"
const HUNGER_DRAIN_PER_SECOND := 0.35  ## ~5 min from full(100) to empty if idle
const MOOD_DRAIN_PER_SECOND := 0.15
const FEED_HUNGER_RESTORE := 35.0
const PLAY_MOOD_RESTORE := 30.0
const REST_MOOD_RESTORE := 15.0
const REST_HUNGER_COST := 5.0

var _captured: Dictionary = {}
var _party: PackedStringArray = PackedStringArray()
var _companion_species_id: StringName = STARTER_CREATURE_ID
var _companion_nickname: String = "Pixel Fox"
var _companion_hunger: float = 70.0  ## 0 empty → 100 full
var _companion_mood_value: float = 75.0  ## 0 low → 100 high; maps to Mood
var _care_initialized: bool = false


func _initialize_manager() -> void:
	_ensure_starter_companion()
	_log("CreatureManager initialized (companion=%s)" % _companion_species_id)


func _process(delta: float) -> void:
	if not _care_initialized:
		return
	# Gentle real-time drain so care matters between short sessions.
	_companion_hunger = maxf(0.0, _companion_hunger - HUNGER_DRAIN_PER_SECOND * delta)
	var mood_drain := MOOD_DRAIN_PER_SECOND * delta
	if _companion_hunger < 25.0:
		mood_drain *= 2.0  ## Hungry creatures get grumpy faster
	_companion_mood_value = maxf(0.0, _companion_mood_value - mood_drain)


func _ensure_starter_companion() -> void:
	if _care_initialized:
		return
	var data: CreatureData = ResourceRegistry.get_creature(STARTER_CREATURE_ID)
	if data != null and not data.display_name.is_empty():
		_companion_nickname = data.display_name
	_companion_species_id = STARTER_CREATURE_ID
	_care_initialized = true


# --- Companion getters ---

func get_companion_id() -> StringName:
	return _companion_species_id


func get_companion_nickname() -> String:
	return _companion_nickname


func get_hunger() -> float:
	return _companion_hunger


func get_mood_value() -> float:
	return _companion_mood_value


func get_mood() -> Mood:
	# Hunger can force irritable even if mood meter is mid-range.
	if _companion_hunger < 20.0:
		return Mood.IRRITABLE
	if _companion_mood_value >= 85.0:
		return Mood.EXCITED
	if _companion_mood_value >= 65.0:
		return Mood.HAPPY
	if _companion_mood_value >= 45.0:
		return Mood.CONTENT
	if _companion_mood_value >= 25.0:
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
		_: return "Unknown"


func get_hunger_label() -> String:
	if _companion_hunger >= 80.0:
		return "Full"
	if _companion_hunger >= 55.0:
		return "Okay"
	if _companion_hunger >= 30.0:
		return "Peckish"
	if _companion_hunger >= 10.0:
		return "Hungry"
	return "Starving"


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
		_:
			return "%s is waiting." % _companion_nickname


func get_mood_color() -> Color:
	match get_mood():
		Mood.EXCITED: return Color(0.35, 0.95, 0.75)
		Mood.HAPPY: return Color(0.31, 0.82, 0.76)
		Mood.CONTENT: return Color(0.45, 0.7, 0.85)
		Mood.BORED: return Color(0.65, 0.65, 0.55)
		Mood.SAD: return Color(0.45, 0.5, 0.7)
		Mood.IRRITABLE: return Color(0.9, 0.45, 0.35)
		_: return Color(0.5, 0.5, 0.5)


## Soft gate — adventure always allowed, but returns false when care is critical.
func is_adventure_ready() -> bool:
	return _companion_hunger >= 15.0 and get_mood() != Mood.SAD


# --- Care actions ---

func feed() -> String:
	_companion_hunger = minf(100.0, _companion_hunger + FEED_HUNGER_RESTORE)
	_companion_mood_value = minf(100.0, _companion_mood_value + 8.0)
	EventBus.companion_cared.emit(&"feed")
	EventBus.companion_state_changed.emit()
	return "You shared a snack. %s looks satisfied!" % _companion_nickname


func play() -> String:
	_companion_mood_value = minf(100.0, _companion_mood_value + PLAY_MOOD_RESTORE)
	_companion_hunger = maxf(0.0, _companion_hunger - 4.0)
	EventBus.companion_cared.emit(&"play")
	EventBus.companion_state_changed.emit()
	return "You played together. %s is happier!" % _companion_nickname


func rest() -> String:
	_companion_mood_value = minf(100.0, _companion_mood_value + REST_MOOD_RESTORE)
	_companion_hunger = maxf(0.0, _companion_hunger - REST_HUNGER_COST)
	EventBus.companion_cared.emit(&"rest")
	EventBus.companion_state_changed.emit()
	return "%s took a short rest and feels better." % _companion_nickname


func get_party() -> PackedStringArray:
	return _party


func export_state() -> Dictionary:
	return {
		&"captured": _captured.duplicate(true),
		&"party": _party.duplicate(),
		&"companion_id": _companion_species_id,
		&"companion_nickname": _companion_nickname,
		&"companion_hunger": _companion_hunger,
		&"companion_mood_value": _companion_mood_value,
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
		_companion_hunger = float(data[&"companion_hunger"])
	if data.has(&"companion_mood_value"):
		_companion_mood_value = float(data[&"companion_mood_value"])
	if data.has(&"care_initialized"):
		_care_initialized = bool(data[&"care_initialized"])
	_ensure_starter_companion()
