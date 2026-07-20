class_name NpcMemory
extends RefCounted
## Per-NPC memory entries — capped for handheld saves.


const MAX_MEMORIES := 16

enum Kind {
	TALK,
	HELPED,
	QUEST,
	DISCOVERY,
	BOSS,
	STORY,
	CUSTOM,
}


static func kind_id(kind: Kind) -> StringName:
	match kind:
		Kind.TALK:
			return &"talk"
		Kind.HELPED:
			return &"helped"
		Kind.QUEST:
			return &"quest"
		Kind.DISCOVERY:
			return &"discovery"
		Kind.BOSS:
			return &"boss"
		Kind.STORY:
			return &"story"
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


static func recent_labels(memories: Array, limit: int = 2) -> PackedStringArray:
	var out := PackedStringArray()
	for i in mini(limit, memories.size()):
		var row: Dictionary = memories[i]
		out.append(str(row.get(&"label", row.get("label", ""))))
	return out
