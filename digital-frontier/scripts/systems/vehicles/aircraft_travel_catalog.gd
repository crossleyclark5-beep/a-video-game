class_name AircraftTravelCatalog
extends RefCounted
## Grassland air-hop destinations for the Field Skiff prototype.


static func destinations() -> Array[Dictionary]:
	## Landing offsets keep the skiff clear of hub plazas / gazebos.
	return [
		{"id": &"pleasant_park", "label": "Pleasant Park", "pos": GrasslandLayout.PLEASANT_PARK + Vector3(48, 0, 18)},
		{"id": &"salty_springs", "label": "Salty Springs", "pos": GrasslandLayout.SALTY_SPRINGS + Vector3(12, 0, 18)},
		{"id": &"risky_reels", "label": "Risky Reels", "pos": GrasslandLayout.RISKY_REELS + Vector3(16, 0, 20)},
		{"id": &"mirror_mere", "label": "Mirror Mere", "pos": GrasslandLayout.MIRROR_MERE + Vector3(-18, 0, 16)},
		{"id": &"market_mile", "label": "Market Mile", "pos": GrasslandLayout.MARKET_MILE + Vector3(-20, 0, 12)},
		{"id": &"grease_grove", "label": "Grease Grove", "pos": GrasslandLayout.GREASE_GROVE + Vector3(18, 0, -14)},
		{"id": &"fatal_fields", "label": "Fatal Fields", "pos": GrasslandLayout.FATAL_FIELDS + Vector3(-16, 0, 18)},
		{"id": &"pine_hollow", "label": "Pine Hollow", "pos": GrasslandLayout.LANDMARK_PINE_HOLLOW + Vector3(10, 0, 12)},
	]
