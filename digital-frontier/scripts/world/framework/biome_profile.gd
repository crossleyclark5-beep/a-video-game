class_name BiomeProfile
extends RefCounted
## Plugin contract for a biome — terrain, life, weather, presentation.
## Grassland is the reference; future biomes supply their own profile.


var id: StringName = &"grassland"
var label: String = "Grassland"
var palette_sky: Color = Color(0.55, 0.75, 0.95)
var palette_grass: Color = Color(0.35, 0.65, 0.32)
var music_track_id: StringName = &"grassland_day"
var ambient_sfx_id: StringName = &"wind_soft"
var weather_bias: Dictionary = {}  ## weather_id -> weight multiplier
var lighting_phase_tint: Dictionary = {}
var dressing_rules: Dictionary = {}
var species_table: Callable = Callable()  ## () -> Array[Dictionary]
var npc_table: Callable = Callable()
var aquatic_table: Callable = Callable()


static func grassland() -> BiomeProfile:
	var p := BiomeProfile.new()
	p.id = &"grassland"
	p.label = "Grassland"
	p.palette_sky = WorldPalette.SKY_DAY
	p.palette_grass = WorldPalette.GRASS
	p.music_track_id = &"grassland_day"
	p.ambient_sfx_id = &"wind_soft"
	p.weather_bias = {&"clear": 1.0, &"rain": 0.9, &"fog": 0.8, &"storm": 0.7}
	p.dressing_rules = BiomeDressingRules.grassland()
	p.species_table = Callable(EcosystemCatalog, "grassland_species")
	p.npc_table = Callable(LivingWorldCatalog, "grassland_npcs")
	p.aquatic_table = Callable(LivingWorldCatalog, "grassland_aquatics")
	return p


func wildlife_defs() -> Array[Dictionary]:
	if species_table.is_valid():
		return species_table.call()
	return []


func npc_defs() -> Array[Dictionary]:
	if npc_table.is_valid():
		return npc_table.call()
	return []


func aquatic_defs() -> Array[Dictionary]:
	if aquatic_table.is_valid():
		return aquatic_table.call()
	return []


func to_dict() -> Dictionary:
	return {
		&"id": id,
		&"label": label,
		&"music_track_id": music_track_id,
		&"ambient_sfx_id": ambient_sfx_id,
		&"weather_bias": weather_bias.duplicate(),
	}
