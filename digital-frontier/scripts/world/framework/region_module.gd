class_name RegionModule
extends RefCounted
## Plugin contract for a playable region.
## Implement `build` + metadata; register with WorldCoordinator.
## GrasslandRegionModule is the reference implementation.


var id: StringName = &""
var label: String = ""
var biome: BiomeProfile = null
var music_track_id: StringName = &""
var weather_modifiers: Dictionary = {}
var neighbor_ids: PackedStringArray = PackedStringArray()


func get_id() -> StringName:
	return id


func get_biome() -> BiomeProfile:
	return biome


## Build authored + procedural content under `root`. Return contract dict:
## player_spawn, chests[], enterable_houses[], poi_centers{}, expansion_points[]
func build(_root: Node3D) -> Dictionary:
	push_warning("RegionModule.build not implemented for %s" % String(id))
	return {
		&"player_spawn": Vector3(0, 0.15, 0),
		&"chests": [],
		&"enterable_houses": [],
		&"poi_centers": {},
		&"expansion_points": [],
	}


func discovery_defs() -> Array[Dictionary]:
	return []


func to_dict() -> Dictionary:
	return {
		&"id": id,
		&"label": label,
		&"biome_id": biome.id if biome else &"",
		&"music_track_id": music_track_id,
		&"neighbors": Array(neighbor_ids),
	}
