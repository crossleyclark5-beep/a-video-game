class_name CompanionPersonality
extends RefCounted
## Derives readable traits and behavioral modifiers from CreatureInstance axes.
## Traits shape dialogue, follow style, battle bias.

const TRAIT_ORDER: Array[StringName] = [
	&"brave", &"playful", &"curious", &"calm", &"energetic", &"stubborn", &"protective",
]


static func ensure_axes(personality: Dictionary) -> Dictionary:
	var p: Dictionary = personality.duplicate(true) if not personality.is_empty() else {}
	## Always start from a copy so callers keep their original dict intact.
	if personality.is_empty():
		p = {}
	else:
		p = personality.duplicate(true)
	if not p.has("playful"):
		p["playful"] = 55.0
	if not p.has("curious"):
		p["curious"] = 60.0
	if not p.has("affectionate"):
		p["affectionate"] = 50.0
	if not p.has("lazy"):
		p["lazy"] = 35.0
	if not p.has("brave"):
		p["brave"] = 45.0
	if not p.has("stubborn"):
		p["stubborn"] = clampf(40.0 + float(p.get("brave", 45.0)) * 0.15 - float(p.get("affectionate", 50.0)) * 0.1, 15.0, 85.0)
	if not p.has("protective"):
		p["protective"] = clampf((float(p.get("affectionate", 50.0)) + float(p.get("brave", 45.0))) * 0.5, 20.0, 90.0)
	if not p.has("energetic"):
		p["energetic"] = clampf(100.0 - float(p.get("lazy", 35.0)), 10.0, 95.0)
	if not p.has("calm"):
		p["calm"] = clampf(100.0 - float(p.get("playful", 55.0)) * 0.55 - float(p.get("energetic", 50.0)) * 0.25, 10.0, 90.0)
	return p


static func primary_trait(personality: Dictionary) -> StringName:
	var p: Dictionary = ensure_axes(personality)
	var best_id: StringName = &"curious"
	var best_v: float = -1.0
	for tid in TRAIT_ORDER:
		var v: float = float(p.get(String(tid), 50.0))
		if v > best_v:
			best_v = v
			best_id = tid
	return best_id


static func trait_label(trait_id: StringName) -> String:
	match trait_id:
		&"brave":
			return "Brave"
		&"playful":
			return "Playful"
		&"curious":
			return "Curious"
		&"calm":
			return "Calm"
		&"energetic":
			return "Energetic"
		&"stubborn":
			return "Stubborn"
		&"protective":
			return "Protective"
		_:
			return String(trait_id).capitalize()


static func battle_style(personality: Dictionary) -> StringName:
	var trait_id: StringName = primary_trait(personality)
	match trait_id:
		&"brave":
			return &"aggressive"
		&"protective":
			return &"aggressive"
		&"stubborn":
			return &"tank"
		&"playful":
			return &"swift"
		&"energetic":
			return &"swift"
		&"calm":
			return &"steady"
		&"curious":
			return &"opportunist"
		_:
			return &"balanced"


static func follow_side_bias(personality: Dictionary) -> float:
	var p: Dictionary = ensure_axes(personality)
	if float(p.get("playful", 50.0)) >= 55.0:
		return 1.0
	if float(p.get("protective", 50.0)) >= 60.0:
		return -1.0
	if float(p.get("curious", 50.0)) >= 50.0:
		return 1.0
	return -1.0


static func sense_radius_mult(personality: Dictionary) -> float:
	var p: Dictionary = ensure_axes(personality)
	return lerpf(0.88, 1.28, float(p.get("curious", 50.0)) / 100.0)


static func adventure_speed_mult(personality: Dictionary, energy: float, happiness: float) -> float:
	var p: Dictionary = ensure_axes(personality)
	var mult: float = lerpf(0.82, 1.22, float(p.get("energetic", 50.0)) / 100.0)
	if energy < 30.0:
		mult *= 0.7
	elif happiness > 80.0 and float(p.get("playful", 50.0)) > 60.0:
		mult *= 1.08
	if float(p.get("stubborn", 50.0)) > 70.0 and energy < 40.0:
		mult *= 0.92
	return clampf(mult, 0.5, 1.45)


static func talk_line(personality: Dictionary, mood_label: String, context: StringName = &"idle") -> String:
	var trait_id: StringName = primary_trait(personality)
	match context:
		&"danger":
			if trait_id == &"brave" or trait_id == &"protective":
				return "Stay behind me - I've got this!"
			if trait_id == &"calm":
				return "Slow steps. Watch the shadows."
			if trait_id == &"curious":
				return "Something's wrong here... careful."
			return "That feels dangerous..."
		&"discover":
			if trait_id == &"curious" or trait_id == &"playful":
				return "Look look look!"
			if trait_id == &"energetic":
				return "Race you there!"
			return "New place - together!"
		&"victory":
			if trait_id == &"playful":
				return "We did it! Again?"
			if trait_id == &"brave":
				return "Told you we could!"
			if trait_id == &"protective":
				return "You're safe. I'm proud."
			return "Victory tastes good."
		&"tired":
			return "Can we rest soon...?"
		&"hungry":
			return "Snack break?"
		&"comfort":
			if trait_id == &"protective":
				return "...Thanks. That helps."
			if trait_id == &"stubborn":
				return "I'm fine. ...Okay, maybe not."
			return "Feeling better already."
		_:
			if mood_label == "Tired":
				return "Just a little longer out here..."
			if mood_label == "Irritable":
				return "Food first, then adventure."
			match trait_id:
				&"brave":
					return "Wherever you go, I go."
				&"playful":
					return "Let's find something fun!"
				&"curious":
					return "Wonder what's over that hill..."
				&"calm":
					return "Nice pace. I like this."
				&"energetic":
					return "Still got juice - keep moving!"
				&"stubborn":
					return "I'm not quitting. Not today."
				&"protective":
					return "I've got your back."
				_:
					return "I'm with you."


static func home_care_line(action: StringName, personality: Dictionary, nickname: String) -> String:
	var trait_id: StringName = primary_trait(personality)
	match action:
		&"feed":
			if trait_id == &"playful":
				return "%s munches happily - loud crunches!" % nickname
			return "%s munches happily." % nickname
		&"play":
			if trait_id == &"playful":
				return "%s tumbles around - pure joy." % nickname
			return "%s plays along, bond rising." % nickname
		&"train":
			if trait_id == &"stubborn":
				return "%s pushes harder than asked. Training sticks." % nickname
			if trait_id == &"brave":
				return "%s drills like a champ." % nickname
			return "Training complete. %s feels stronger." % nickname
		&"rest":
			return "%s curls up, breathing soft digital light." % nickname
		&"pet", &"interact", &"talk":
			return talk_line(personality, "Happy", &"idle")
		&"comfort":
			return talk_line(personality, "Content", &"comfort")
		&"celebrate":
			return talk_line(personality, "Excited", &"victory")
		_:
			return "%s notices you." % nickname
