class_name GrasslandRegionModule
extends RegionModule
## Reference RegionModule — wraps GrasslandRegionBuilder without rewriting it.


func _init() -> void:
	id = &"grassland"
	label = "Grassland Region"
	biome = BiomeProfile.grassland()
	music_track_id = biome.music_track_id
	weather_modifiers = {&"storm_hostile_bonus": 2}
	neighbor_ids = PackedStringArray(["storm_prairie", "pine_coast"])  ## Future stubs.


func build(root: Node3D) -> Dictionary:
	## Delegate to the existing builder — framework owns registration, not geometry.
	return GrasslandRegionBuilder.build(root)


func discovery_defs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in ResourceRegistry.get_all_discoverables():
		if d is DiscoverableData:
			var dd := d as DiscoverableData
			## Grassland chapter includes park + surrounding hub discoverables.
			out.append({
				&"id": dd.id,
				&"name": dd.display_name,
				&"region_id": dd.region_id,
				&"category": dd.category,
				&"secret": dd.is_secret,
			})
	return out
