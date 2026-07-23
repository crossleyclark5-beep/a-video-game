class_name WorldSimMemory
extends RefCounted
## Persistent small-event memory — cleared camps, quiet dens, traveler notes.
## Backed by WorldManager flags so the world does not instantly reset.


const FLAG_CLEARED_PREFIX := "sim_cleared_"
const FLAG_EVENT_PREFIX := "sim_event_"
const DEFAULT_CLEAR_TTL_SEC := 480.0  ## ~one day cycle at default atmosphere pace


static func mark_cleared_zone(zone_id: StringName, ttl_sec: float = DEFAULT_CLEAR_TTL_SEC) -> void:
	var key := StringName(FLAG_CLEARED_PREFIX + String(zone_id))
	var until := Time.get_ticks_msec() / 1000.0 + ttl_sec
	WorldManager.set_world_flag(key, until)


static func is_zone_cleared(zone_id: StringName) -> bool:
	var key := StringName(FLAG_CLEARED_PREFIX + String(zone_id))
	var until := float(WorldManager.get_world_flag(key, 0.0))
	if until <= 0.0:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now >= until:
		WorldManager.set_world_flag(key, 0.0)
		return false
	return true


static func zone_id_for_position(pos: Vector3, cell_m: float = 48.0) -> StringName:
	var cx := int(floor(pos.x / cell_m))
	var cz := int(floor(pos.z / cell_m))
	return StringName("z_%d_%d" % [cx, cz])


static func mark_cleared_at(pos: Vector3, ttl_sec: float = DEFAULT_CLEAR_TTL_SEC) -> void:
	mark_cleared_zone(zone_id_for_position(pos), ttl_sec)


static func is_position_cleared(pos: Vector3) -> bool:
	return is_zone_cleared(zone_id_for_position(pos))


static func remember_event(event_id: StringName, payload: Variant = true) -> void:
	WorldManager.set_world_flag(StringName(FLAG_EVENT_PREFIX + String(event_id)), payload)


static func has_event(event_id: StringName) -> bool:
	return bool(WorldManager.get_world_flag(StringName(FLAG_EVENT_PREFIX + String(event_id)), false))


static func note_hostile_cleared(pos: Vector3, species_id: StringName) -> void:
	mark_cleared_at(pos)
	remember_event(&"recent_hostile_clear", String(species_id))
	## Nearby NPCs may comment later.
	NPCManager.remember(
		&"field_ranger",
		&"camp_cleared",
		NpcMemory.Kind.HELPED,
		"You cleared a nest near the roads.",
		PackedStringArray(["camp"]),
	)
	NPCManager.remember(
		&"park_villager",
		&"village_safe",
		NpcMemory.Kind.HELPED,
		"The park feels quieter after those fights.",
	)
