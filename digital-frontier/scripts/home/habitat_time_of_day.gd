class_name HabitatTimeOfDay
extends RefCounted
## Time-of-day / weather foundation for home habitats.
## Modular so seasonal skins and weather packs can override palettes later.

enum Phase {
	DAWN,
	DAY,
	DUSK,
	NIGHT,
}

var phase: Phase = Phase.NIGHT
var weather_id: StringName = &"clear"
var cycle_enabled: bool = false
var _elapsed: float = 0.0

## Seconds per full day when cycle is enabled (foundation only).
const DAY_LENGTH_SEC := 600.0


func advance(delta: float) -> void:
	if not cycle_enabled:
		return
	_elapsed = fmod(_elapsed + delta, DAY_LENGTH_SEC)
	var t := _elapsed / DAY_LENGTH_SEC
	if t < 0.2:
		phase = Phase.DAWN
	elif t < 0.55:
		phase = Phase.DAY
	elif t < 0.7:
		phase = Phase.DUSK
	else:
		phase = Phase.NIGHT


func get_ambient_color() -> Color:
	match phase:
		Phase.DAWN:
			return Color(0.55, 0.45, 0.55)
		Phase.DAY:
			return Color(0.65, 0.75, 0.9)
		Phase.DUSK:
			return Color(0.45, 0.3, 0.4)
		_:
			return Color(0.12, 0.14, 0.28)


func get_window_glow() -> Color:
	match phase:
		Phase.NIGHT:
			return Color(0.35, 0.55, 0.95, 1.0)
		Phase.DAWN:
			return Color(0.95, 0.65, 0.45, 1.0)
		Phase.DUSK:
			return Color(0.9, 0.4, 0.55, 1.0)
		_:
			return Color(0.75, 0.85, 1.0, 1.0)


func get_lamp_energy() -> float:
	match phase:
		Phase.NIGHT:
			return 1.35
		Phase.DAWN, Phase.DUSK:
			return 0.85
		_:
			return 0.25


func get_label() -> String:
	match phase:
		Phase.DAWN: return "Dawn"
		Phase.DAY: return "Day"
		Phase.DUSK: return "Dusk"
		_: return "Night"
