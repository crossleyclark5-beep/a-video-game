class_name DiscoveryFramework
extends RefCounted
## Permanent discovery facade — locations, creatures, NPCs, lore, landmarks.
## Backed by WorldManager + CollectionManager; one API for future journals/quests.


enum Category {
	LOCATION,
	CREATURE,
	NPC,
	LANDMARK,
	PLANT,
	FISH,
	PHOTO,
	CAVE,
	LORE,
	SECRET,
}


static func category_id(cat: int) -> StringName:
	match cat:
		Category.LOCATION: return &"location"
		Category.CREATURE: return &"creature"
		Category.NPC: return &"npc"
		Category.LANDMARK: return &"landmark"
		Category.PLANT: return &"plant"
		Category.FISH: return &"fish"
		Category.PHOTO: return &"photo"
		Category.CAVE: return &"cave"
		Category.LORE: return &"lore"
		Category.SECRET: return &"secret"
		_: return &"location"


static func register_location(location_id: StringName, display_name: String = "") -> bool:
	## Returns true if this was a first-time discovery.
	var first := not WorldManager.is_location_discovered(location_id)
	if first:
		WorldManager.discover_location(location_id, display_name if not display_name.is_empty() else String(location_id))
	return first


static func is_discovered(location_id: StringName) -> bool:
	return WorldManager.is_location_discovered(location_id)


static func discovered_count() -> int:
	return WorldManager.get_discovery_count()


static func discovered_names() -> PackedStringArray:
	return WorldManager.get_discovered_names()


static func register_creature_sighting(payload: Dictionary, pos: Vector3 = Vector3.ZERO) -> void:
	CollectionManager.record_creature_sighting(payload, pos)


static func completion_snapshot() -> Dictionary:
	var discoverable_total := ResourceRegistry.get_all_discoverables().size()
	var col: Dictionary = CollectionManager.export_state() if CollectionManager.has_method("export_state") else {}
	return {
		&"locations_found": WorldManager.get_discovery_count(),
		&"locations_total": discoverable_total,
		&"names": Array(WorldManager.get_discovered_names()),
		&"creatures": col.get(&"creatures", col.get("creatures", {})),
		&"achievements": col.get(&"achievements", col.get("achievements", {})),
	}


static func journal_blurb() -> String:
	if CollectionManager.has_method("get_journal_text"):
		return String(CollectionManager.get_journal_text())
	var snap := completion_snapshot()
	return "Discoveries %d / %d" % [int(snap.get(&"locations_found", 0)), int(snap.get(&"locations_total", 0))]
