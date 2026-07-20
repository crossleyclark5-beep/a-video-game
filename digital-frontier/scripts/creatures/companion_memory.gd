class_name CompanionMemory
extends RefCounted
## Lightweight memory entries stored on CreatureInstance.
## Kept small for handheld saves — capped list, newest first.


const MAX_MEMORIES := 24

enum Kind {
	FIRST_ADVENTURE,
	BATTLE,
	DISCOVERY,
	STORY,
	CARE,
	EVOLUTION,
	BOSS,
	FRIENDSHIP,
	CUSTOM,
}


static func kind_id(kind: Kind) -> StringName:
	match kind:
		Kind.FIRST_ADVENTURE:
			return &"first_adventure"
		Kind.BATTLE:
			return &"battle"
		Kind.DISCOVERY:
			return &"discovery"
		Kind.STORY:
			return &"story"
		Kind.CARE:
			return &"care"
		Kind.EVOLUTION:
			return &"evolution"
		Kind.BOSS:
			return &"boss"
		Kind.FRIENDSHIP:
			return &"friendship"
		_:
			return &"custom"


static func make(id: StringName, kind: Kind, label: String, tags: PackedStringArray = PackedStringArray()) -> Dictionary:
	return {
		&"id": String(id),
		&"kind": String(kind_id(kind)),
		&"label": label,
		&"tags": Array(tags),
		&"unix": int(Time.get_unix_time_from_system()),
	}


static func push(memories: Array, entry: Dictionary) -> Array:
	var out: Array = memories.duplicate()
	var eid := str(entry.get(&"id", entry.get("id", "")))
	## Deduplicate by id — refresh label/time if revisited.
	for i in out.size():
		var row: Dictionary = out[i]
		if str(row.get(&"id", row.get("id", ""))) == eid:
			out.remove_at(i)
			break
	out.push_front(entry)
	while out.size() > MAX_MEMORIES:
		out.pop_back()
	return out


static func has_id(memories: Array, memory_id: StringName) -> bool:
	var want := String(memory_id)
	for row in memories:
		if row is Dictionary and str(row.get(&"id", row.get("id", ""))) == want:
			return true
	return false


static func recent_labels(memories: Array, limit: int = 3) -> PackedStringArray:
	var out := PackedStringArray()
	for i in mini(limit, memories.size()):
		var row: Dictionary = memories[i]
		out.append(str(row.get(&"label", row.get("label", "…"))))
	return out


static func summary_line(memories: Array) -> String:
	if memories.is_empty():
		return "No shared memories yet — go explore together."
	var labels := recent_labels(memories, 2)
	if labels.size() == 1:
		return "Remembers: %s" % labels[0]
	return "Remembers: %s · %s" % [labels[0], labels[1]]
