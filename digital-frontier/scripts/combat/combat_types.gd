class_name CombatTypes
extends RefCounted
## Element chart for companion battles — simple handheld Digimon-style advantages.


enum Element {
	NEUTRAL,
	EMBER,
	TIDE,
	VOLT,
	NATURE,
	HEX,
}


static func element_label(el: int) -> String:
	match el:
		Element.EMBER:
			return "Ember"
		Element.TIDE:
			return "Tide"
		Element.VOLT:
			return "Volt"
		Element.NATURE:
			return "Nature"
		Element.HEX:
			return "Hex"
		_:
			return "Neutral"


static func element_color(el: int) -> Color:
	match el:
		Element.EMBER:
			return Color(0.95, 0.45, 0.2)
		Element.TIDE:
			return Color(0.3, 0.55, 0.95)
		Element.VOLT:
			return Color(0.95, 0.85, 0.25)
		Element.NATURE:
			return Color(0.35, 0.8, 0.4)
		Element.HEX:
			return Color(0.7, 0.35, 0.85)
		_:
			return Color(0.75, 0.75, 0.78)


## Multiplier: attacker element vs defender element.
static func affinity(attacker: int, defender: int) -> float:
	if attacker == Element.NEUTRAL or defender == Element.NEUTRAL:
		return 1.0
	## Classic cycle + Hex as wild card.
	match attacker:
		Element.EMBER:
			if defender == Element.NATURE:
				return 1.4
			if defender == Element.TIDE:
				return 0.7
		Element.TIDE:
			if defender == Element.EMBER:
				return 1.4
			if defender == Element.VOLT:
				return 0.7
		Element.VOLT:
			if defender == Element.TIDE:
				return 1.4
			if defender == Element.NATURE:
				return 0.7
		Element.NATURE:
			if defender == Element.VOLT:
				return 1.4
			if defender == Element.EMBER:
				return 0.7
		Element.HEX:
			if defender == Element.HEX:
				return 0.85
			return 1.15
	return 1.0


static func species_element(species_id: StringName) -> int:
	match String(species_id):
		"emberling", "emberaptor", "emberion":
			return Element.EMBER
		"tidepup", "tidemaul", "tidalking":
			return Element.TIDE
		"sparkbit", "sparkbolt", "sparkion", "bytebat":
			return Element.VOLT
		"cotton_rabbit", "park_deer", "timber_moose", "hex_squirrel", "meadow_bird", "pack_pup":
			return Element.NATURE
		"glitchmite", "glitch_alpha", "scrubwolf", "thornboar", "hollow_warden":
			return Element.HEX
		_:
			return Element.NEUTRAL
