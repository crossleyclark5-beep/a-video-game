class_name RegionMapCatalog
extends RefCounted
## Handheld map markers for the Grassland Region.
## Major POIs stay visible as mystery icons until discovered; secrets hide until found.

enum IconKind {
	TOWN,
	FARM,
	CINEMA,
	SPRING,
	LANDMARK,
	SECRET,
	WATER,
	MOUNTAIN,
	VIEWPOINT,
	CAVE,
	ROAD,
}


static func region_bounds() -> Rect2:
	## XZ plane as Rect2(x, z, width, depth).
	var mn := GrasslandLayout.REGION_MIN
	var mx := GrasslandLayout.REGION_MAX
	return Rect2(mn.x, mn.z, mx.x - mn.x, mx.z - mn.z)


static func major_markers() -> Array[Dictionary]:
	## Always drawn (mystery style until discovery_id is found).
	return [
		{
			"id": &"pleasant_park",
			"discovery_id": &"park_welcome",
			"pos": GrasslandLayout.PLEASANT_PARK,
			"kind": IconKind.TOWN,
			"label": "Pleasant Park",
			"mystery_label": "Town",
		},
		{
			"id": &"grease_grove",
			"discovery_id": &"grease_grove_welcome",
			"pos": GrasslandLayout.GREASE_GROVE,
			"kind": IconKind.LANDMARK,
			"label": "Grease Grove",
			"mystery_label": "Plaza",
		},
		{
			"id": &"mirror_mere",
			"discovery_id": &"mirror_mere_welcome",
			"pos": GrasslandLayout.MIRROR_MERE,
			"kind": IconKind.WATER,
			"label": "Mirror Mere",
			"mystery_label": "Lake",
		},
		{
			"id": &"market_mile",
			"discovery_id": &"market_mile_welcome",
			"pos": GrasslandLayout.MARKET_MILE,
			"kind": IconKind.TOWN,
			"label": "Market Mile",
			"mystery_label": "Shops",
		},
		{
			"id": &"salty_springs",
			"discovery_id": &"salty_springs_welcome",
			"pos": GrasslandLayout.SALTY_SPRINGS,
			"kind": IconKind.SPRING,
			"label": "Salty Springs",
			"mystery_label": "Hill Town",
		},
		{
			"id": &"risky_reels",
			"discovery_id": &"risky_reels_welcome",
			"pos": GrasslandLayout.RISKY_REELS,
			"kind": IconKind.CINEMA,
			"label": "Risky Reels",
			"mystery_label": "Drive-In",
		},
		{
			"id": &"fatal_fields",
			"discovery_id": &"fatal_fields_welcome",
			"pos": GrasslandLayout.FATAL_FIELDS,
			"kind": IconKind.FARM,
			"label": "Fatal Fields",
			"mystery_label": "Farm",
		},
	]


static func landmark_markers() -> Array[Dictionary]:
	## Shown as mystery (non-secret) or hidden (secret) until discovered.
	return [
		{
			"id": &"creek_bridge",
			"discovery_id": &"creek_bridge",
			"pos": Vector3(1280.0, 0.0, -1200.0),
			"kind": IconKind.WATER,
			"label": "Creek Bridge",
			"mystery_label": "Water",
			"secret": false,
		},
		{
			"id": &"hillside_cave",
			"discovery_id": &"hillside_cave",
			"pos": Vector3(668.0, 0.0, 804.0),
			"kind": IconKind.CAVE,
			"label": "Hillside Cave",
			"mystery_label": "Cave",
			"secret": true,
		},
		{
			"id": &"prairie_overlook",
			"discovery_id": &"prairie_overlook",
			"pos": Vector3(705.0, 0.0, 3100.0),
			"kind": IconKind.VIEWPOINT,
			"label": "Prairie Overlook",
			"mystery_label": "Overlook",
			"secret": false,
		},
		{
			"id": &"movie_billboard",
			"discovery_id": &"movie_billboard",
			"pos": Vector3(2280.0, 0.0, -2200.0),
			"kind": IconKind.LANDMARK,
			"label": "Faded Billboard",
			"mystery_label": "Sign",
			"secret": false,
		},
		{
			"id": &"secret_shack",
			"discovery_id": &"secret_shack",
			"pos": Vector3(-90.0, 0.0, 220.0),
			"kind": IconKind.SECRET,
			"label": "Hidden Shack",
			"mystery_label": "???",
			"secret": true,
		},
		{
			"id": &"west_ridge",
			"discovery_id": &"west_ridge",
			"pos": Vector3(-420.0, 0.0, 80.0),
			"kind": IconKind.MOUNTAIN,
			"label": "West Ridge",
			"mystery_label": "Ridge",
			"secret": false,
		},
		{
			"id": &"north_pass",
			"discovery_id": &"north_pass",
			"pos": Vector3(900.0, 0.0, -900.0),
			"kind": IconKind.MOUNTAIN,
			"label": "North Pass",
			"mystery_label": "Pass",
			"secret": false,
		},
		{
			"id": &"south_bluffs",
			"discovery_id": &"south_bluffs",
			"pos": Vector3(520.0, 0.0, 4900.0),
			"kind": IconKind.MOUNTAIN,
			"label": "South Bluffs",
			"mystery_label": "Bluffs",
			"secret": false,
		},
		{
			"id": &"pine_hollow",
			"discovery_id": &"pine_hollow",
			"pos": Vector3(420.0, 0.0, 520.0),
			"kind": IconKind.LANDMARK,
			"label": "Pine Hollow",
			"mystery_label": "Woods",
			"secret": false,
		},
		{
			"id": &"meadow_clearing",
			"discovery_id": &"meadow_clearing",
			"pos": Vector3(1780.0, 0.0, -1680.0),
			"kind": IconKind.VIEWPOINT,
			"label": "Meadow Clearing",
			"mystery_label": "Clearing",
			"secret": false,
		},
	]


static func terrain_features() -> Array[Dictionary]:
	## Static map paint (not discovery-gated).
	return [
		{"kind": IconKind.WATER, "pos": GrasslandLayout.MIRROR_MERE, "radius": 48.0},
		{"kind": IconKind.WATER, "pos": Vector3(1280.0, 0.0, -1200.0), "radius": 28.0},
		{"kind": IconKind.WATER, "pos": Vector3(490.0, 0.0, 4552.0), "radius": 36.0},
		{"kind": IconKind.MOUNTAIN, "pos": Vector3(-420.0, 0.0, 80.0), "radius": 55.0},
		{"kind": IconKind.MOUNTAIN, "pos": Vector3(900.0, 0.0, -900.0), "radius": 70.0},
		{"kind": IconKind.MOUNTAIN, "pos": Vector3(520.0, 0.0, 4900.0), "radius": 80.0},
	]


static func road_polylines() -> Array:
	return [
		GrasslandLayout.path_park_to_salty(),
		GrasslandLayout.path_park_to_reels(),
		GrasslandLayout.path_park_to_fields(),
		GrasslandLayout.path_park_to_mere(),
		GrasslandLayout.path_park_to_mile(),
		GrasslandLayout.path_park_to_grove(),
	]


static func is_discovered(marker: Dictionary) -> bool:
	var did: StringName = marker.get("discovery_id", marker.get("id", &""))
	if did == &"":
		return true
	return WorldManager.is_location_discovered(did)


static func should_draw_marker(marker: Dictionary) -> bool:
	if bool(marker.get("secret", false)) and not is_discovered(marker):
		return false
	return true


static func display_label(marker: Dictionary) -> String:
	if is_discovered(marker):
		return String(marker.get("label", "Place"))
	return String(marker.get("mystery_label", "???"))
