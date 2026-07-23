extends BaseManager
## NPC runtime — disposition, memory, schedules, talk counts.
##
## Static identity may live in NPCData / LivingWorldCatalog; this manager
## tracks per-save changes so the world reacts to the player.

var _npc_states: Dictionary = {}  ## npc_id -> Dictionary
var _day_phase: int = WorldAtmosphere.Phase.AFTERNOON


func _initialize_manager() -> void:
	if not EventBus.npc_dialogue_ended.is_connected(_on_dialogue_ended):
		EventBus.npc_dialogue_ended.connect(_on_dialogue_ended)
	if not EventBus.day_phase_changed.is_connected(_on_day_phase_changed):
		EventBus.day_phase_changed.connect(_on_day_phase_changed)
	_log("NPCManager initialized (memory + schedules)")


func get_day_phase() -> int:
	return _day_phase


func _on_day_phase_changed(phase: int) -> void:
	_day_phase = phase


func get_npc_state(npc_id: StringName) -> Dictionary:
	var key := String(npc_id)
	if not _npc_states.has(key):
		_npc_states[key] = _default_state(npc_id)
	return _npc_states[key]


func _default_state(npc_id: StringName) -> Dictionary:
	var role := _infer_role(npc_id)
	return {
		&"talk_count": 0,
		&"disposition": 50.0,
		&"memories": [],
		&"role": role,
		&"schedule_id": String(NpcCatalog.default_schedule(role)),
		&"last_slot": -1,
		&"met": false,
	}


func _infer_role(npc_id: StringName) -> int:
	match npc_id:
		&"road_merchant", &"fuel_clerk":
			return NpcCatalog.Role.MERCHANT
		&"meadow_researcher":
			return NpcCatalog.Role.RESEARCHER
		&"field_ranger", &"lost_scout":
			return NpcCatalog.Role.EXPLORER
		&"park_guide":
			return NpcCatalog.Role.STORY
		&"park_kid", &"park_elder", &"park_villager":
			return NpcCatalog.Role.VILLAGER
		&"park_guard":
			return NpcCatalog.Role.EXPLORER
		&"road_carter":
			return NpcCatalog.Role.MERCHANT
		_:
			return NpcCatalog.Role.VILLAGER


func get_role(npc_id: StringName) -> int:
	var st := get_npc_state(npc_id)
	return int(st.get(&"role", st.get("role", NpcCatalog.Role.VILLAGER)))


func get_schedule_id(npc_id: StringName) -> StringName:
	var st := get_npc_state(npc_id)
	return StringName(str(st.get(&"schedule_id", st.get("schedule_id", "town_loop"))))


func get_disposition(npc_id: StringName) -> float:
	var st := get_npc_state(npc_id)
	return float(st.get(&"disposition", st.get("disposition", 50.0)))


func adjust_disposition(npc_id: StringName, delta: float) -> void:
	var st := get_npc_state(npc_id)
	var d := clampf(float(st.get(&"disposition", 50.0)) + delta, 0.0, 100.0)
	st[&"disposition"] = d
	_npc_states[String(npc_id)] = st
	EventBus.npc_state_changed.emit(npc_id)


func get_memories(npc_id: StringName) -> Array:
	var st := get_npc_state(npc_id)
	var mem = st.get(&"memories", st.get("memories", []))
	return mem if mem is Array else []


func has_memory(npc_id: StringName, memory_id: StringName) -> bool:
	return NpcMemory.has_id(get_memories(npc_id), memory_id)


func remember(
	npc_id: StringName,
	memory_id: StringName,
	kind: NpcMemory.Kind,
	label: String,
	tags: PackedStringArray = PackedStringArray(),
) -> void:
	var st := get_npc_state(npc_id)
	var mem: Array = st.get(&"memories", [])
	if not mem is Array:
		mem = []
	st[&"memories"] = NpcMemory.push(mem, NpcMemory.make(memory_id, kind, label, tags))
	_npc_states[String(npc_id)] = st
	EventBus.npc_state_changed.emit(npc_id)


func broadcast_memory(
	memory_id: StringName,
	kind: NpcMemory.Kind,
	label: String,
	tags: PackedStringArray = PackedStringArray(),
) -> void:
	for npc_id in [&"park_guide", &"field_ranger", &"meadow_researcher", &"park_villager", &"road_merchant", &"fuel_clerk", &"lost_scout"]:
		remember(npc_id, memory_id, kind, label, tags)


func broadcast_story_memory(beat_id: StringName) -> void:
	remember(
		&"park_guide",
		StringName("story_%s" % String(beat_id)),
		NpcMemory.Kind.STORY,
		StoryCatalog.beat_title(beat_id),
		PackedStringArray(["story", String(beat_id)]),
	)
	remember(
		&"field_ranger",
		StringName("story_%s" % String(beat_id)),
		NpcMemory.Kind.STORY,
		StoryCatalog.beat_title(beat_id),
		PackedStringArray(["story", String(beat_id)]),
	)


func note_quest_completed_for_cast(quest_id: StringName) -> void:
	var data: QuestData = ResourceRegistry.get_quest(quest_id) if ResourceRegistry.has_id(&"quest", quest_id) else null
	var npc := &""
	if data:
		npc = data.turn_in_npc_id if data.turn_in_npc_id != &"" else data.start_npc_id
	if npc != &"":
		remember(
			npc,
			&"quest_done",
			NpcMemory.Kind.QUEST,
			"Completed: %s" % (data.display_name if data else String(quest_id)),
			PackedStringArray(["quest", String(quest_id)]),
		)
		adjust_disposition(npc, 8.0)


func get_talk_lines(npc_id: StringName, fallback: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	## Prefer quest-aware ChapterCast, then memory reactions, then fallback.
	var lines := ChapterCast.lines_for(npc_id)
	if lines.is_empty():
		lines = fallback.duplicate()
	var mem_lines := NpcCatalog.memory_lines(npc_id, get_memories(npc_id))
	if not mem_lines.is_empty():
		## Keep handheld short — prepend at most one memory line.
		var merged := PackedStringArray()
		merged.append(mem_lines[0])
		for i in mini(2, lines.size()):
			merged.append(lines[i])
		lines = merged
	## Disposition flavor — one short nudge.
	var disp := get_disposition(npc_id)
	if disp >= 75.0 and lines.size() < 3:
		lines.append("Always glad to see you and your partner.")
	elif disp <= 30.0 and lines.size() < 3:
		lines.append("…Hmm. Prove you’re worth the trouble.")
	if lines.is_empty():
		lines = PackedStringArray(["…"])
	## Hard cap for handheld readability.
	while lines.size() > 3:
		lines.remove_at(lines.size() - 1)
	return lines


func export_state() -> Dictionary:
	return _npc_states.duplicate(true)


func import_state(data: Dictionary) -> void:
	_npc_states = data.duplicate(true)


func reset_state() -> void:
	_npc_states.clear()


func _on_dialogue_ended(npc_id: StringName) -> void:
	if npc_id == &"story" or npc_id == &"":
		return
	var st := get_npc_state(npc_id)
	st[&"talk_count"] = int(st.get(&"talk_count", 0)) + 1
	st[&"met"] = true
	_npc_states[String(npc_id)] = st
	remember(
		npc_id,
		&"talked_recently",
		NpcMemory.Kind.TALK,
		"Spoke with the traveler",
		PackedStringArray(["talk"]),
	)
	adjust_disposition(npc_id, 1.5)
