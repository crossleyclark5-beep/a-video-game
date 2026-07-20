class_name InteriorPersonality
extends RefCounted
## Home interior “story” — same HOUSE kind, different lived-in layouts.


enum Style {
	MODEST,
	WEALTHY,
	RUSTIC,
	MODERN,
	GARDEN,
	ABANDONED,
}


static func from_style_name(style: StringName) -> int:
	match style:
		&"brick", &"victorian", &"colonial":
			return Style.WEALTHY
		&"cottage", &"bungalow":
			return Style.RUSTIC
		&"modern", &"ranch":
			return Style.MODERN
		&"garden":
			return Style.GARDEN
		&"abandoned", &"ruin":
			return Style.ABANDONED
		_:
			return Style.MODEST


static func from_building_id(building_id: StringName, kind: StringName) -> int:
	## Fallback when exterior style isn’t set — stable hash per building.
	if kind == InteriorKinds.CABIN or kind == InteriorKinds.FARMHOUSE or kind == InteriorKinds.BARN:
		return Style.RUSTIC
	if kind == InteriorKinds.OFFICE or kind == InteriorKinds.TOWER:
		return Style.MODERN
	var h: int = absi(hash(String(building_id))) % 5
	match h:
		0:
			return Style.WEALTHY
		1:
			return Style.RUSTIC
		2:
			return Style.MODERN
		3:
			return Style.GARDEN
		_:
			return Style.MODEST


static func label(style: int) -> String:
	match style:
		Style.WEALTHY:
			return "Wealthy"
		Style.RUSTIC:
			return "Rustic"
		Style.MODERN:
			return "Modern"
		Style.GARDEN:
			return "Garden"
		Style.ABANDONED:
			return "Abandoned"
		_:
			return "Modest"


static func wall_tint(style: int, base: Color) -> Color:
	match style:
		Style.WEALTHY:
			return base.lightened(0.08)
		Style.RUSTIC:
			return Color(0.78, 0.7, 0.58)
		Style.MODERN:
			return Color(0.82, 0.84, 0.88)
		Style.GARDEN:
			return Color(0.8, 0.86, 0.78)
		Style.ABANDONED:
			return Color(0.65, 0.62, 0.55)
		_:
			return base


static func floor_tint(style: int, base: Color) -> Color:
	match style:
		Style.WEALTHY:
			return Color(0.55, 0.38, 0.28)
		Style.RUSTIC:
			return Color(0.48, 0.36, 0.24)
		Style.MODERN:
			return Color(0.7, 0.7, 0.72)
		Style.ABANDONED:
			return Color(0.42, 0.38, 0.32)
		_:
			return base
