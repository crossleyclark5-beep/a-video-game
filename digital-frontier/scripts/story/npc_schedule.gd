class_name NpcSchedule
extends RefCounted
## Day-phase schedule waypoints — towns feel lived-in without heavy AI.
## Each slot answers: wake → work → wander → home → sleep.


enum Slot {
	MORNING,
	AFTERNOON,
	EVENING,
	NIGHT,
}


static func slot_from_phase(phase: int) -> int:
	match phase:
		WorldAtmosphere.Phase.MORNING:
			return Slot.MORNING
		WorldAtmosphere.Phase.EVENING:
			return Slot.EVENING
		WorldAtmosphere.Phase.NIGHT:
			return Slot.NIGHT
		_:
			return Slot.AFTERNOON


static func slot_label(slot: int) -> String:
	match slot:
		Slot.MORNING:
			return "morning"
		Slot.EVENING:
			return "evening"
		Slot.NIGHT:
			return "night"
		_:
			return "afternoon"


## Human-readable beat for HUD / debug — reinforces believable routines.
static func activity_label(schedule_id: StringName, slot: int) -> String:
	match String(schedule_id):
		"market_beat":
			match slot:
				Slot.MORNING: return "opening shop"
				Slot.AFTERNOON: return "trading"
				Slot.EVENING: return "closing stall"
				_: return "asleep"
		"field_patrol":
			match slot:
				Slot.NIGHT: return "night watch"
				Slot.EVENING: return "return patrol"
				_: return "patrolling"
		"guard_patrol":
			match slot:
				Slot.NIGHT: return "gate watch"
				_: return "town patrol"
		"child_play":
			match slot:
				Slot.NIGHT, Slot.EVENING: return "home for dinner"
				_: return "playing outside"
		"research_walk":
			match slot:
				Slot.NIGHT: return "lab notes"
				_: return "field study"
		"merchant_road":
			match slot:
				Slot.NIGHT: return "camped on road"
				_: return "traveling between towns"
		"story_anchor":
			return "waiting nearby"
		_:
			match slot:
				Slot.MORNING: return "leaving home"
				Slot.AFTERNOON: return "around town"
				Slot.EVENING: return "heading home"
				_: return "sleeping"


## Returns relative offsets from home for the schedule id + slot.
static func waypoints(schedule_id: StringName, slot: int) -> Array[Vector3]:
	match String(schedule_id):
		"town_loop":
			return _town_loop(slot)
		"market_beat":
			return _market_beat(slot)
		"field_patrol":
			return _field_patrol(slot)
		"guard_patrol":
			return _guard_patrol(slot)
		"child_play":
			return _child_play(slot)
		"research_walk":
			return _research_walk(slot)
		"merchant_road":
			return _merchant_road(slot)
		"story_anchor":
			## Important cast stays near home — tiny idle drift only.
			return [Vector3(0, 0, 0), Vector3(1.2, 0, 0.8), Vector3(-1.0, 0, 1.0)]
		_:
			return [Vector3(0, 0, 0), Vector3(2.5, 0, 1.5), Vector3(-2.0, 0, 2.0)]


## Shelter offset when raining — porch / awning near home.
static func shelter_offset(schedule_id: StringName) -> Vector3:
	match String(schedule_id):
		"field_patrol", "guard_patrol":
			return Vector3(2.5, 0, -1.5)  ## Still near route, under cover.
		"merchant_road":
			return Vector3(0, 0, 0)  ## Wagon canopy = home.
		"child_play":
			return Vector3(-1.5, 0, 1.0)
		_:
			return Vector3(0.8, 0, -1.2)


static func seeks_shelter_in_rain(schedule_id: StringName) -> bool:
	## Guards / road merchants tough it out more often.
	match String(schedule_id):
		"guard_patrol", "field_patrol":
			return false
		"story_anchor":
			return false
		_:
			return true


static func sleeps_at_night(schedule_id: StringName) -> bool:
	match String(schedule_id):
		"guard_patrol", "field_patrol":
			return false  ## Night watch.
		"story_anchor":
			return false
		_:
			return true


static func _town_loop(slot: int) -> Array[Vector3]:
	match slot:
		Slot.MORNING:
			## Wake → door → street.
			return [Vector3(0, 0, 0), Vector3(3, 0, 1), Vector3(5, 0, 4), Vector3(2, 0, 6)]
		Slot.AFTERNOON:
			## Shops / plaza chatter.
			return [Vector3(4, 0, 3), Vector3(-3, 0, 4), Vector3(0, 0, -5), Vector3(5, 0, -2), Vector3(-4, 0, -1)]
		Slot.EVENING:
			## Sit outside → dinner path home.
			return [Vector3(-2, 0, 2), Vector3(1, 0, 3), Vector3(0, 0, 0), Vector3(2, 0, -1)]
		Slot.NIGHT:
			## Lights off — stay home.
			return [Vector3(0, 0, 0), Vector3(0.6, 0, -0.4)]
		_:
			return [Vector3(3, 0, 3), Vector3(-3, 0, 2)]


static func _market_beat(slot: int) -> Array[Vector3]:
	match slot:
		Slot.MORNING:
			## Open shop.
			return [Vector3(0, 0, 0), Vector3(5, 0, 0), Vector3(8, 0, 2), Vector3(6, 0, -2)]
		Slot.AFTERNOON:
			return [Vector3(6, 0, 1), Vector3(4, 0, 4), Vector3(9, 0, -1), Vector3(7, 0, 3)]
		Slot.EVENING:
			## Close shop → home.
			return [Vector3(5, 0, 0), Vector3(2, 0, 1), Vector3(0, 0, 0)]
		Slot.NIGHT:
			return [Vector3(0, 0, 0)]
		_:
			return [Vector3(6, 0, 1), Vector3(4, 0, 4)]


static func _field_patrol(slot: int) -> Array[Vector3]:
	match slot:
		Slot.MORNING:
			return [Vector3(0, 0, 4), Vector3(-6, 0, 8), Vector3(4, 0, 10), Vector3(0, 0, 6)]
		Slot.AFTERNOON:
			return [Vector3(5, 0, 8), Vector3(-5, 0, 12), Vector3(0, 0, 14), Vector3(6, 0, 6)]
		Slot.EVENING:
			return [Vector3(2, 0, 5), Vector3(-2, 0, 3), Vector3(0, 0, 1)]
		Slot.NIGHT:
			## Shorter night watch loops.
			return [Vector3(0, 0, 3), Vector3(3, 0, 5), Vector3(-3, 0, 4), Vector3(0, 0, 2)]
		_:
			return [Vector3(0, 0, 6), Vector3(-5, 0, 8)]


static func _guard_patrol(slot: int) -> Array[Vector3]:
	match slot:
		Slot.NIGHT:
			return [Vector3(8, 0, 0), Vector3(8, 0, 8), Vector3(0, 0, 8), Vector3(-8, 0, 8), Vector3(-8, 0, 0), Vector3(0, 0, 0)]
		Slot.MORNING:
			return [Vector3(6, 0, 0), Vector3(6, 0, 6), Vector3(0, 0, 6), Vector3(0, 0, 0)]
		_:
			return [Vector3(7, 0, 2), Vector3(2, 0, 7), Vector3(-6, 0, 4), Vector3(-2, 0, -5), Vector3(5, 0, -3)]


static func _child_play(slot: int) -> Array[Vector3]:
	match slot:
		Slot.MORNING, Slot.AFTERNOON:
			return [Vector3(3, 0, 2), Vector3(-2, 0, 4), Vector3(4, 0, 5), Vector3(1, 0, 1), Vector3(-3, 0, 2)]
		Slot.EVENING:
			## Walk home before dark.
			return [Vector3(2, 0, 2), Vector3(1, 0, 0), Vector3(0, 0, 0)]
		Slot.NIGHT:
			return [Vector3(0, 0, 0)]
		_:
			return [Vector3(2, 0, 2)]


static func _research_walk(slot: int) -> Array[Vector3]:
	match slot:
		Slot.MORNING:
			return [Vector3(3, 0, -2), Vector3(6, 0, 0), Vector3(2, 0, 3), Vector3(5, 0, 4)]
		Slot.AFTERNOON:
			return [Vector3(4, 0, 2), Vector3(-2, 0, 4), Vector3(5, 0, -3), Vector3(7, 0, 1)]
		Slot.EVENING:
			return [Vector3(2, 0, 1), Vector3(0, 0, 0)]
		Slot.NIGHT:
			return [Vector3(0, 0, 0)]
		_:
			return [Vector3(4, 0, 2)]


static func _merchant_road(slot: int) -> Array[Vector3]:
	## Longer leash implied by WorldNpcActor for this schedule.
	match slot:
		Slot.NIGHT:
			return [Vector3(0, 0, 0), Vector3(1.5, 0, 0.5)]
		Slot.MORNING:
			return [Vector3(12, 0, 0), Vector3(22, 0, 4), Vector3(30, 0, -2)]
		Slot.EVENING:
			return [Vector3(18, 0, 2), Vector3(8, 0, 0), Vector3(0, 0, 0)]
		_:
			return [Vector3(16, 0, 3), Vector3(28, 0, -4), Vector3(35, 0, 2), Vector3(20, 0, 6)]
