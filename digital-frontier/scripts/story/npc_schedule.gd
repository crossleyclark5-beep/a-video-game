class_name NpcSchedule
extends RefCounted
## Day-phase schedule waypoints — towns feel lived-in without heavy AI.


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


## Returns relative offsets from home for the schedule id + slot.
static func waypoints(schedule_id: StringName, slot: int) -> Array[Vector3]:
	match String(schedule_id):
		"town_loop":
			return _town_loop(slot)
		"market_beat":
			return _market_beat(slot)
		"field_patrol":
			return _field_patrol(slot)
		"research_walk":
			return _research_walk(slot)
		"story_anchor":
			## Important cast stays near home — tiny idle drift only.
			return [Vector3(0, 0, 0), Vector3(1.2, 0, 0.8), Vector3(-1.0, 0, 1.0)]
		_:
			return [Vector3(0, 0, 0), Vector3(2.5, 0, 1.5), Vector3(-2.0, 0, 2.0)]


static func _town_loop(slot: int) -> Array[Vector3]:
	match slot:
		Slot.MORNING:
			return [Vector3(0, 0, 0), Vector3(4, 0, 2), Vector3(2, 0, 5)]
		Slot.EVENING:
			return [Vector3(-3, 0, 1), Vector3(0, 0, 0), Vector3(3, 0, -2)]
		Slot.NIGHT:
			return [Vector3(0, 0, 0), Vector3(1.5, 0, -1)]
		_:
			return [Vector3(3, 0, 3), Vector3(-3, 0, 2), Vector3(0, 0, -4), Vector3(4, 0, -1)]


static func _market_beat(slot: int) -> Array[Vector3]:
	match slot:
		Slot.NIGHT:
			return [Vector3(0, 0, 0)]
		Slot.MORNING:
			return [Vector3(5, 0, 0), Vector3(8, 0, 2), Vector3(3, 0, -3)]
		_:
			return [Vector3(6, 0, 1), Vector3(4, 0, 4), Vector3(9, 0, -1)]


static func _field_patrol(slot: int) -> Array[Vector3]:
	match slot:
		Slot.NIGHT:
			return [Vector3(0, 0, 0), Vector3(2, 0, 3)]
		_:
			return [Vector3(0, 0, 6), Vector3(-5, 0, 8), Vector3(5, 0, 10), Vector3(0, 0, 4)]


static func _research_walk(slot: int) -> Array[Vector3]:
	match slot:
		Slot.MORNING:
			return [Vector3(3, 0, -2), Vector3(6, 0, 0), Vector3(2, 0, 3)]
		Slot.NIGHT:
			return [Vector3(0, 0, 0)]
		_:
			return [Vector3(4, 0, 2), Vector3(-2, 0, 4), Vector3(5, 0, -3)]
